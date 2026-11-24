import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../../models/medical_event_model.dart';

abstract class MedicalLocalDataSource {
  Future<List<MedicalEventModel>> getAllEvents({String? userId, String? memberId});
  Future<MedicalEventModel?> getEventById(String id);
  Future<void> insertOrUpdateEvent(MedicalEventModel event);
  Future<void> deleteEvent(String id);
}

abstract class SyncableMedicalLocalDataSource extends MedicalLocalDataSource {
  Future<List<MedicalEventModel>> getPendingDeletedEvents({String? userId});
  Future<void> purgeSoftDeletedEvent(String id);
  Future<void> markEventsSynced(List<String> ids);
}

class MedicalLocalDataSourceImpl implements SyncableMedicalLocalDataSource {
  final DatabaseHelper databaseHelper;

  MedicalLocalDataSourceImpl({required this.databaseHelper});

  Future<Database> get _db => databaseHelper.database;

  @override
  Future<List<MedicalEventModel>> getAllEvents({String? userId, String? memberId}) async {
    final db = await _db;
    final clauses = <String>['(deleted_at IS NULL OR deleted_at = "")'];
    final args = <Object?>[];

    if (userId != null && userId.isNotEmpty) {
      // Chỉ tự động gán các bản ghi mồ côi chưa có user_id (NULL/"") nếu thiết bị chỉ có đúng 1 tài khoản duy nhất
      try {
        final totalUsersCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM users'),
            ) ??
            0;
        if (totalUsersCount <= 1) {
          await db.update(
            'medical_events',
            {'user_id': userId},
            where: 'user_id IS NULL OR user_id = ""',
          );
        }
      } catch (_) {}

      clauses.add('user_id = ?');
      args.add(userId);
    }

    if (memberId != null && memberId.isNotEmpty) {
      if (memberId == 'primary') {
        clauses.add('(member_id IS NULL OR member_id = "" OR member_id = ?)');
        args.add('primary');
      } else {
        clauses.add('member_id = ?');
        args.add(memberId);
      }
    }

    final results = await db.query(
      'medical_events',
      where: clauses.join(' AND '),
      whereArgs: args,
      orderBy: 'date DESC',
    );
    return results.map((row) => MedicalEventModel.fromJson(row)).toList();
  }

  /// Trả về các bản ghi đã đánh dấu xóa mềm (`pending_delete`) để đồng bộ xóa lên Cloud trước khi dọn hẳn.
  @override
  Future<List<MedicalEventModel>> getPendingDeletedEvents({String? userId}) async {
    final db = await _db;
    final results = (userId != null && userId.isNotEmpty)
        ? await db.query(
            'medical_events',
            where: 'user_id = ? AND deleted_at IS NOT NULL AND deleted_at != ""',
            whereArgs: [userId],
          )
        : await db.query(
            'medical_events',
            where: 'deleted_at IS NOT NULL AND deleted_at != ""',
          );
    return results.map((row) => MedicalEventModel.fromJson(row)).toList();
  }

  /// Xóa vĩnh viễn bản ghi đã đồng bộ xóa mềm xong trên Cloud và dọn tệp ảnh mồ côi.
  @override
  Future<void> purgeSoftDeletedEvent(String id) async {
    final db = await _db;
    final existing = await db.query('medical_events', where: 'id = ?', whereArgs: [id], limit: 1);
    final attachmentsToCheck = <String>[];
    if (existing.isNotEmpty) {
      final rawAtt = existing.first['attachments'] as String?;
      if (rawAtt != null && rawAtt.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawAtt);
          if (decoded is List) {
            attachmentsToCheck.addAll(decoded.map((e) => e.toString()));
          }
        } catch (_) {}
      }
    }

    await db.transaction((txn) async {
      final presRows = await txn.query(
        'prescriptions',
        columns: ['id'],
        where: 'event_id = ?',
        whereArgs: [id],
      );
      for (final p in presRows) {
        final presId = p['id'] as String;
        await txn.delete('medicines', where: 'prescription_id = ?', whereArgs: [presId]);
      }
      await txn.delete('prescriptions', where: 'event_id = ?', whereArgs: [id]);
      await txn.delete('medical_events', where: 'id = ?', whereArgs: [id]);
    });

    await cleanupUnreferencedFiles(attachmentsToCheck);
  }

  /// Đánh dấu bản ghi đã được đẩy lên Cloud thành công.
  @override
  Future<void> markEventsSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await _db;
    final placeholders = List.filled(ids.length, '?').join(', ');
    await db.update(
      'medical_events',
      {'sync_status': 'synced'},
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  @override
  Future<MedicalEventModel?> getEventById(String id, {String? activeUserId}) async {
    final db = await _db;
    final results = (activeUserId != null && activeUserId.isNotEmpty)
        ? await db.query(
            'medical_events',
            where:
                'id = ? AND (user_id = ? OR user_id IS NULL OR user_id = "") AND (deleted_at IS NULL OR deleted_at = "")',
            whereArgs: [id, activeUserId],
            limit: 1,
          )
        : await db.query(
            'medical_events',
            where: 'id = ? AND (deleted_at IS NULL OR deleted_at = "")',
            whereArgs: [id],
            limit: 1,
          );
    if (results.isEmpty) return null;
    return MedicalEventModel.fromJson(results.first);
  }

  @override
  Future<void> insertOrUpdateEvent(MedicalEventModel event) async {
    final db = await _db;
    final previous = await getEventById(event.id);
    final removedAttachments = <String>[];
    if (previous != null) {
      for (final oldPath in previous.attachments) {
        if (!event.attachments.contains(oldPath)) {
          removedAttachments.add(oldPath);
        }
      }
    }

    await db.transaction((txn) async {
      await txn.insert(
        'medical_events',
        event.toSqliteMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (event.deletedAt == null &&
          event.prescription != null &&
          event.prescription!.medicines.isNotEmpty) {
        final pres = event.prescription!;
        await txn.insert(
          'prescriptions',
          {
            'id': pres.id,
            'event_id': event.id,
            'doctor_name': pres.doctorName,
            'hospital': pres.hospital,
            'issued_date': pres.issuedDate.toIso8601String(),
            'duration_days': pres.durationDays,
            'status': pres.status,
            'note': pres.note,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        await txn.delete(
          'medicines',
          where: 'prescription_id = ?',
          whereArgs: [pres.id],
        );

        for (final med in pres.medicines) {
          await txn.insert(
            'medicines',
            {
              'id': med.id,
              'prescription_id': pres.id,
              'name': med.name,
              'dosage': med.dosage,
              'frequency': med.frequency,
              'instructions': med.instructions ?? med.frequency,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      } else {
        final oldPres = await txn.query(
          'prescriptions',
          columns: ['id'],
          where: 'event_id = ?',
          whereArgs: [event.id],
        );
        for (final p in oldPres) {
          final presId = p['id'] as String;
          await txn.delete('medicines', where: 'prescription_id = ?', whereArgs: [presId]);
        }
        await txn.delete('prescriptions', where: 'event_id = ?', whereArgs: [event.id]);
      }
    });

    if (removedAttachments.isNotEmpty) {
      await cleanupUnreferencedFiles(removedAttachments);
    }
  }

  @override
  Future<void> deleteEvent(String id) async {
    final db = await _db;
    final existing = await db.query('medical_events', where: 'id = ?', whereArgs: [id], limit: 1);
    final attachmentsToCheck = <String>[];
    if (existing.isNotEmpty) {
      final rawAtt = existing.first['attachments'] as String?;
      if (rawAtt != null && rawAtt.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawAtt);
          if (decoded is List) {
            attachmentsToCheck.addAll(decoded.map((e) => e.toString()));
          }
        } catch (_) {}
      }
    }

    final nowIso = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      final presRows = await txn.query(
        'prescriptions',
        columns: ['id'],
        where: 'event_id = ?',
        whereArgs: [id],
      );
      for (final p in presRows) {
        final presId = p['id'] as String;
        await txn.delete('medicines', where: 'prescription_id = ?', whereArgs: [presId]);
      }
      await txn.delete('prescriptions', where: 'event_id = ?', whereArgs: [id]);

      // Đánh dấu xóa mềm (Soft Delete Tombstone) để ngăn Cloud Sync hồi sinh bản ghi khi mất mạng
      await txn.update(
        'medical_events',
        {
          'deleted_at': nowIso,
          'updated_at': nowIso,
          'sync_status': 'pending_delete',
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    });

    await cleanupUnreferencedFiles(attachmentsToCheck);
  }

  /// Dọn tệp ảnh vật lý trong thư mục ứng dụng nếu không còn bất kỳ bệnh án hay tài liệu nào tham chiếu.
  Future<void> cleanupUnreferencedFiles(List<String> candidatePaths) async {
    if (candidatePaths.isEmpty) return;
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) return;

    try {
      final db = await _db;
      for (final path in candidatePaths) {
        if (path.isEmpty ||
            path.startsWith('assets/') ||
            path.startsWith('http://') ||
            path.startsWith('https://') ||
            path.startsWith('storage://')) {
          continue;
        }

        final file = File(path);
        if (!file.existsSync()) continue;

        final fileName = path.split('/').last;
        final usedInEvents = Sqflite.firstIntValue(
              await db.rawQuery(
                'SELECT COUNT(*) FROM medical_events WHERE (deleted_at IS NULL OR deleted_at = "") AND attachments LIKE ?',
                ['%$fileName%'],
              ),
            ) ??
            0;
        final usedInDocs = Sqflite.firstIntValue(
              await db.rawQuery(
                'SELECT COUNT(*) FROM medical_documents WHERE file_path LIKE ?',
                ['%$fileName%'],
              ),
            ) ??
            0;

        if (usedInEvents == 0 && usedInDocs == 0) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('[MedicalLocalDataSource] cleanupUnreferencedFiles error: $e');
    }
  }
}
