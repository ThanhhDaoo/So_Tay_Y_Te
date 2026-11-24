import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../models/medical_event_model.dart';

abstract class MedicalSyncRemoteDataSource {
  Future<void> uploadEvents(List<MedicalEventModel> events);
  Future<List<MedicalEventModel>> fetchLatestEvents();
  Future<void> deleteEvent(String id);
}

class MedicalSyncRemoteDataSourceImpl implements MedicalSyncRemoteDataSource {
  static const String _bucketName = 'medical-documents';
  static const String _storageUriPrefix = 'storage://medical-documents/';

  final SupabaseClient? client;

  MedicalSyncRemoteDataSourceImpl({this.client});

  SupabaseClient? get _client => client ?? SupabaseConfig.client;

  Future<List<String>> _uploadAttachmentsIfNeeded(
    SupabaseClient c,
    String userId,
    String recordUuid,
    List<String> attachments,
  ) async {
    if (attachments.isEmpty) return const [];
    final syncedPaths = <String>[];

    for (final rawPath in attachments) {
      if (rawPath.startsWith('assets/') ||
          rawPath.startsWith('http://') ||
          rawPath.startsWith('https://') ||
          rawPath.startsWith(_storageUriPrefix)) {
        syncedPaths.add(rawPath);
        continue;
      }

      try {
        final localFile = File(rawPath);
        if (!localFile.existsSync()) {
          syncedPaths.add(rawPath);
          continue;
        }
        final fileName = p.basename(rawPath);
        final objectPath = '$userId/$recordUuid/$fileName';
        await c.storage.from(_bucketName).upload(
              objectPath,
              localFile,
              fileOptions: const FileOptions(upsert: true),
            );
        syncedPaths.add('$_storageUriPrefix$objectPath');
      } catch (e) {
        debugPrint('[MedicalSyncRemoteDataSource] Attachment upload fallback ($rawPath): $e');
        syncedPaths.add(rawPath);
      }
    }

    return syncedPaths;
  }

  Future<List<String>> _hydrateCloudAttachments(
    SupabaseClient c,
    List<String> remoteAttachments,
  ) async {
    if (remoteAttachments.isEmpty) return const [];
    final resolved = <String>[];

    Directory? docsDir;
    try {
      docsDir = await getApplicationDocumentsDirectory();
    } catch (_) {}

    for (final item in remoteAttachments) {
      if (!item.startsWith(_storageUriPrefix) || docsDir == null) {
        resolved.add(item);
        continue;
      }

      final objectPath = item.substring(_storageUriPrefix.length);
      final fileName = p.basename(objectPath);
      final targetLocalFile = File(p.join(docsDir.path, fileName));

      if (targetLocalFile.existsSync()) {
        resolved.add(targetLocalFile.path);
        continue;
      }

      try {
        final bytes = await c.storage.from(_bucketName).download(objectPath);
        await targetLocalFile.writeAsBytes(bytes, flush: true);
        resolved.add(targetLocalFile.path);
      } catch (e) {
        debugPrint('[MedicalSyncRemoteDataSource] Attachment download skipped ($objectPath): $e');
        resolved.add(item);
      }
    }

    return resolved;
  }

  @override
  Future<void> uploadEvents(List<MedicalEventModel> events) async {
    final c = _client;
    if (c == null || events.isEmpty) return;

    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST') && client == null) {
      debugPrint('[MedicalSyncRemoteDataSource] FLUTTER_TEST offline mode. Skipping network call.');
      return;
    }

    try {
      final currentUserId = c.auth.currentUser?.id;
      if (currentUserId == null && client == null) {
        return;
      }

      final payloads = <Map<String, dynamic>>[];
      for (final event in events) {
        final effectiveUserId =
            (currentUserId != null && currentUserId.isNotEmpty) ? currentUserId : event.userId;
        final uuid = MedicalEventModel.ensureValidUuid(event.id);
        final cloudAttachments = effectiveUserId != null
            ? await _uploadAttachmentsIfNeeded(c, effectiveUserId, uuid, event.attachments)
            : event.attachments;

        payloads.add(
          event.toSupabaseMap(
            overrideUserId: effectiveUserId,
            cloudAttachments: cloudAttachments,
          ),
        );
      }

      await c.from('medical_events').upsert(payloads);
      debugPrint('[MedicalSyncRemoteDataSource] Uploaded ${payloads.length} events to Supabase Cloud.');
    } catch (e) {
      debugPrint('[MedicalSyncRemoteDataSource] uploadEvents failed: $e');
      rethrow;
    }
  }

  @override
  Future<List<MedicalEventModel>> fetchLatestEvents() async {
    final c = _client;
    if (c == null) return [];

    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST') && client == null) {
      debugPrint('[MedicalSyncRemoteDataSource] FLUTTER_TEST offline mode. Returning empty.');
      return [];
    }

    try {
      final currentUserId = c.auth.currentUser?.id;
      if (currentUserId == null && client == null) {
        return [];
      }
      dynamic query = c.from('medical_events').select();
      if (currentUserId != null) {
        query = query.eq('user_id', currentUserId);
      }

      List<dynamic> response;
      try {
        response = await query.order('event_date', ascending: false);
      } catch (_) {
        dynamic fallbackQuery = c.from('medical_events').select();
        if (currentUserId != null) {
          fallbackQuery = fallbackQuery.eq('user_id', currentUserId);
        }
        response = await fallbackQuery.order('created_at', ascending: false);
      }

      final parsedList = <MedicalEventModel>[];
      for (final raw in response) {
        final rowMap = Map<String, dynamic>.from(raw as Map);
        if (rowMap['deleted_at'] != null && rowMap['deleted_at'].toString().isNotEmpty) {
          continue;
        }
        final model = MedicalEventModel.fromJson(rowMap);
        final hydratedAttachments = await _hydrateCloudAttachments(c, model.attachments);
        parsedList.add(
          MedicalEventModel(
            id: model.id,
            userId: model.userId,
            memberId: model.memberId,
            title: model.title,
            description: model.description,
            date: model.date,
            type: model.type,
            facilityName: model.facilityName,
            doctorName: model.doctorName,
            department: model.department,
            diagnosis: model.diagnosis,
            bloodPressure: model.bloodPressure,
            heartRate: model.heartRate,
            spo2: model.spo2,
            temperature: model.temperature,
            prescription: model.prescription,
            attachments: hydratedAttachments,
            hospitalFee: model.hospitalFee,
            syncStatus: 'synced',
            createdAt: model.createdAt,
            updatedAt: model.updatedAt,
          ),
        );
      }
      return parsedList;
    } catch (e) {
      debugPrint('[MedicalSyncRemoteDataSource] fetchLatestEvents failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteEvent(String id) async {
    final c = _client;
    if (c == null || id.isEmpty) return;

    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST') && client == null) {
      return;
    }

    try {
      final currentUserId = c.auth.currentUser?.id;
      final cloudUuid = MedicalEventModel.ensureValidUuid(id);
      dynamic query = c.from('medical_events').delete().eq('id', cloudUuid);
      if (currentUserId != null) {
        query = query.eq('user_id', currentUserId);
      }
      await query;
      debugPrint('[MedicalSyncRemoteDataSource] Deleted event $cloudUuid from Supabase Cloud.');
    } catch (e) {
      debugPrint('[MedicalSyncRemoteDataSource] deleteEvent failed: $e');
      rethrow;
    }
  }
}
