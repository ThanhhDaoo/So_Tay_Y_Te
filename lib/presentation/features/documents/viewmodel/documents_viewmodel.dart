import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/safe_avatar_image.dart';
import '../../../../domain/repositories/auth_repository.dart';
import '../../../../domain/repositories/medical_record_repository.dart';
import 'documents_state.dart';

class DocumentsViewModel extends ChangeNotifier {
  final DatabaseHelper? databaseHelper;
  final MedicalRecordRepository? repository;
  final AuthRepository? authRepository;

  DocumentsViewModel({
    this.databaseHelper,
    this.repository,
    this.authRepository,
    DocumentsState? initialState,
  })  : _state = initialState ??
            const DocumentsState(
              selectedCategory: DocumentCategory.all,
            ) {
    if (initialState == null) {
      loadDocuments();
    }
  }

  DocumentsState _state;
  DocumentsState get state => _state;

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
      // 1. Load from medical_documents table
      final dbHelper = databaseHelper ??
          (sl.isRegistered<DatabaseHelper>() ? sl<DatabaseHelper>() : null);
      if (dbHelper != null) {
        final db = await dbHelper.database;
        final rows = await db.query('medical_documents', orderBy: 'created_at DESC');
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
        final events = await repo.getMedicalTimeline();
        for (final e in events) {
          if (e.attachments.isNotEmpty) {
            for (int i = 0; i < e.attachments.length; i++) {
              final att = e.attachments[i];
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

              final dateFormatted = '${e.date.day.toString().padLeft(2, '0')}/${e.date.month.toString().padLeft(2, '0')}/${e.date.year}';
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
    final mb = count * 2;
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
      final now = DateTime.now();
      final id = 'doc_${now.millisecondsSinceEpoch}';
      final dateStr = date ?? '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

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
        'user_id': 'current_user',
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
    final dbHelper = databaseHelper ??
        (sl.isRegistered<DatabaseHelper>() ? sl<DatabaseHelper>() : null);
    if (dbHelper != null) {
      final db = await dbHelper.database;
      await db.delete('medical_documents', where: 'id = ?', whereArgs: [id]);
      await loadDocuments();
    }
  }
}
