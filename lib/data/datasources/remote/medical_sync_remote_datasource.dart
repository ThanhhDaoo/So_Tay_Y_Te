import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../models/medical_event_model.dart';

abstract class MedicalSyncRemoteDataSource {
  Future<void> uploadEvents(List<MedicalEventModel> events);
  Future<List<MedicalEventModel>> fetchLatestEvents();
  Future<void> deleteEvent(String id);
}

class MedicalSyncRemoteDataSourceImpl implements MedicalSyncRemoteDataSource {
  final SupabaseClient? client;

  MedicalSyncRemoteDataSourceImpl({this.client});

  SupabaseClient? get _client => client ?? SupabaseConfig.client;

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
      final payloads = events.map((event) {
        final map = event.toSqliteMap();
        if (currentUserId != null && (map['user_id'] == null || (map['user_id'] as String).isEmpty)) {
          map['user_id'] = currentUserId;
        }
        return map;
      }).toList();

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
      // Không truy vấn toàn cục nếu chưa đăng nhập Supabase thật (trừ môi trường truyền mock client kiểm thử)
      if (currentUserId == null && client == null) {
        return [];
      }
      dynamic query = c.from('medical_events').select();
      if (currentUserId != null) {
        query = query.eq('user_id', currentUserId);
      }
      final List<dynamic> response = await query.order('date', ascending: false);

      return response
          .map((row) => MedicalEventModel.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (e) {
      debugPrint('[MedicalSyncRemoteDataSource] fetchLatestEvents failed: $e');
      return [];
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
      dynamic query = c.from('medical_events').delete().eq('id', id);
      if (currentUserId != null) {
        query = query.eq('user_id', currentUserId);
      }
      await query;
      debugPrint('[MedicalSyncRemoteDataSource] Deleted event $id from Supabase Cloud.');
    } catch (e) {
      debugPrint('[MedicalSyncRemoteDataSource] deleteEvent failed: $e');
    }
  }
}
