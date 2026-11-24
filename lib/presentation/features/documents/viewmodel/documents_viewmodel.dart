import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/user_session_manager.dart';
import '../../../../core/widgets/safe_avatar_image.dart';
import '../../../../domain/entities/medical_event.dart';
import '../../../../domain/repositories/auth_repository.dart';
import '../../../../domain/repositories/medical_record_repository.dart';
import 'documents_state.dart';

class DocumentsViewModel extends ChangeNotifier {
  final DatabaseHelper? databaseHelper;
  final MedicalRecordRepository? repository;
  final AuthRepository? authRepository;
  final bool _hasCustomInitialState;
  int _lastRecordsVersion = AppSessionNotifier.instance.medicalRecordsVersion;

  DocumentsViewModel({
    this.databaseHelper,
    this.repository,
    this.authRepository,
    DocumentsState? initialState,
  })  : _hasCustomInitialState = initialState != null,
        _state = initialState ??
            const DocumentsState(
              selectedCategory: DocumentCategory.all,
            ) {
    if (!_hasCustomInitialState) {
      loadDocuments();
      AppSessionNotifier.instance.addListener(_onGlobalSessionChanged);
    }
  }

  void _onGlobalSessionChanged() {
    final currentVer = AppSessionNotifier.instance.medicalRecordsVersion;
    if (currentVer != _lastRecordsVersion) {
      _lastRecordsVersion = currentVer;
      loadDocuments();
    }
  }

  @override
  void dispose() {
    if (!_hasCustomInitialState) {
      AppSessionNotifier.instance.removeListener(_onGlobalSessionChanged);
    }
    super.dispose();
  }

  DocumentsState _state;
  DocumentsState get state => _state;

  Future<String?> _resolveActiveUserId() async {
    final auth = authRepository ??
        (sl.isRegistered<AuthRepository>() ? sl<AuthRepository>() : null);
    if (auth == null) return null;
    try {
      final session = await auth.getActiveSession();
      return session?.id;
    } catch (_) {
      return null;
    }
  }

  void selectCategory(DocumentCategory category) {
    if (_state.selectedCategory == category) return;
    _state = _state.copyWith(selectedCategory: category);
    notifyListeners();
  }

  void dismissViewerTip() {
    if (!_state.showViewerTip) return;
    _state = _state.copyWith(showViewerTip: false);
    notifyListeners();
  }

  Future<void> loadDocuments() async {
    final docs = <MedicalDocumentItem>[];

    try {
      final activeUserId = await _resolveActiveUserId();

      // 1. Load from medical_documents table (isolated per active user)
      final dbHelper = databaseHelper ??
          (sl.isRegistered<DatabaseHelper>() ? sl<DatabaseHelper>() : null);
      if (dbHelper != null) {
        final db = await dbHelper.database;
        final rows = activeUserId != null
            ? await db.query(
                'medical_documents',
                where: 'user_id = ? OR user_id = ?',
                whereArgs: [activeUserId, 'current_user'],
                orderBy: 'created_at DESC',
              )
            : await db.query('medical_documents', orderBy: 'created_at DESC');

        for (final r in rows) {
          final catStr = r['category'] as String? ?? 'prescriptions';
          DocumentCategory cat;
          switch (catStr) {
            case 'blood_tests':
              cat = DocumentCategory.bloodTests;
              break;
            case 'endoscopy':
              cat = DocumentCategory.endoscopy;
              break;
            case 'xray':
              cat = DocumentCategory.xray;
              break;
            case 'discharge':
              cat = DocumentCategory.discharge;
              break;
            default:
              cat = DocumentCategory.prescriptions;
          }

          List<Map<String, String>> findings = [];
          final summaryStr = r['summary'] as String?;
          if (summaryStr != null && summaryStr.isNotEmpty) {
            try {
              final decoded = jsonDecode(summaryStr);
              if (decoded is List) {
                findings = decoded
                    .map((item) => Map<String, String>.from(item as Map))
                    .toList();
              }
            } catch (_) {}
          }

          docs.add(
            MedicalDocumentItem(
              id: r['id'] as String,
              title: r['title'] as String,
              category: cat,
              date: r['date'] as String,
              hospital: r['hospital'] as String? ?? 'Cơ sở khám bệnh',
              imagePath: SafeAvatarHelper.resolveImagePath(r['file_path'] as String),
              keyFindings: findings,
            ),
          );
        }
      }

      // 2. Load attachments from medical_events
      final repo = repository ??
          (sl.isRegistered<MedicalRecordRepository>()
              ? sl<MedicalRecordRepository>()
              : null);
      if (repo != null) {
        final events = await repo.getMedicalTimeline(userId: activeUserId);
        for (final e in events) {
          if (e.attachments.isNotEmpty) {
            for (int i = 0; i < e.attachments.length; i++) {
              final att = SafeAvatarHelper.resolveImagePath(e.attachments[i]);
              DocumentCategory cat = DocumentCategory.prescriptions;
              if (att.contains('blood')) {
                cat = DocumentCategory.bloodTests;
              } else if (att.contains('endo')) {
                cat = DocumentCategory.endoscopy;
              } else if (att.contains('xray')) {
                cat = DocumentCategory.xray;
              } else if (e.prescription != null) {
                cat = DocumentCategory.prescriptions;
              }

              final dateFormatted =
                  '${e.date.day.toString().padLeft(2, '0')}/${e.date.month.toString().padLeft(2, '0')}/${e.date.year}';
              docs.add(
                MedicalDocumentItem(
                  id: 'event_doc_${e.id}_$i',
                  title: '${e.title} (Ảnh đính kèm ${i + 1})',
                  category: cat,
                  date: dateFormatted,
                  hospital: e.facilityName ?? 'Cơ sở y tế',
                  imagePath: att,
                  keyFindings: [
                    {'label': 'Chẩn đoán', 'value': e.diagnosis ?? e.title, 'status': 'Ghi nhận'},
                    {'label': 'Bác sĩ', 'value': e.doctorName ?? 'Bác sĩ điều trị', 'status': 'Phụ trách'},
                  ],
                ),
              );
            }
          }
        }
      }
    } catch (_) {}

    final count = docs.length;
    int mb = 0;
    for (final doc in docs) {
      if (!doc.imagePath.startsWith('assets/')) {
        final file = File(doc.imagePath);
        if (file.existsSync()) {
          final bytes = file.lengthSync();
          mb += bytes > 0 ? (bytes / (1024 * 1024)).ceil().clamp(1, 500) : 1;
          continue;
        }
      }
      mb += 2;
    }

    _state = _state.copyWith(
      documents: docs,
      totalDocCount: count,
      usedStorageMb: mb,
      savedStorageMb: mb > 0 ? (mb * 0.4).round() : 0,
      totalStorageGb: '$mb MB',
    );
    notifyListeners();
  }

  Future<void> addDocument({
    required String title,
    required DocumentCategory category,
    required String filePath,
    String? hospital,
    String? date,
    List<Map<String, String>>? findings,
  }) async {
    final dbHelper = databaseHelper ??
        (sl.isRegistered<DatabaseHelper>() ? sl<DatabaseHelper>() : null);
    if (dbHelper != null) {
      final db = await dbHelper.database;
      final activeUserId = await _resolveActiveUserId();
      final now = DateTime.now();
      final id = 'doc_${now.millisecondsSinceEpoch}';
      final dateStr = date ??
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

      String catKey;
      switch (category) {
        case DocumentCategory.bloodTests:
          catKey = 'blood_tests';
          break;
        case DocumentCategory.endoscopy:
          catKey = 'endoscopy';
          break;
        case DocumentCategory.xray:
          catKey = 'xray';
          break;
        case DocumentCategory.discharge:
          catKey = 'discharge';
          break;
        default:
          catKey = 'prescriptions';
      }

      await db.insert('medical_documents', {
        'id': id,
        'user_id': activeUserId ?? 'current_user',
        'title': title,
        'category': catKey,
        'file_path': filePath,
        'hospital': hospital ?? 'Cơ sở khám bệnh',
        'date': dateStr,
        'summary': findings != null ? jsonEncode(findings) : '[]',
        'created_at': now.toIso8601String(),
      });

      await loadDocuments();
    }
  }

  Future<void> deleteDocument(String id) async {
    if (id.startsWith('event_doc_')) {
      final withoutPrefix = id.substring('event_doc_'.length);
      final lastUnderscore = withoutPrefix.lastIndexOf('_');
      if (lastUnderscore > 0) {
        final eventId = withoutPrefix.substring(0, lastUnderscore);
        final attIdx = int.tryParse(withoutPrefix.substring(lastUnderscore + 1));
        final repo = repository ??
            (sl.isRegistered<MedicalRecordRepository>()
                ? sl<MedicalRecordRepository>()
                : null);
        if (repo != null && attIdx != null) {
          final event = await repo.getMedicalEventById(eventId);
          if (event != null && attIdx >= 0 && attIdx < event.attachments.length) {
            final updatedAttachments = List<String>.from(event.attachments)..removeAt(attIdx);
            final updatedEvent = MedicalEvent(
              id: event.id,
              userId: event.userId,
              title: event.title,
              description: event.description,
              date: event.date,
              type: event.type,
              facilityName: event.facilityName,
              doctorName: event.doctorName,
              department: event.department,
              diagnosis: event.diagnosis,
              bloodPressure: event.bloodPressure,
              heartRate: event.heartRate,
              prescription: event.prescription,
              attachments: updatedAttachments,
              hospitalFee: event.hospitalFee,
              createdAt: event.createdAt,
              updatedAt: DateTime.now(),
            );
            await repo.saveMedicalEvent(updatedEvent);
            await loadDocuments();
            return;
          }
        }
      }
    }

    final dbHelper = databaseHelper ??
        (sl.isRegistered<DatabaseHelper>() ? sl<DatabaseHelper>() : null);
    if (dbHelper != null) {
      final db = await dbHelper.database;
      await db.delete('medical_documents', where: 'id = ?', whereArgs: [id]);
      await loadDocuments();
    }
  }
}
