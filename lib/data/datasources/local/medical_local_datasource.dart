import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../../models/medical_event_model.dart';

abstract class MedicalLocalDataSource {
  Future<List<MedicalEventModel>> getAllEvents({String? userId});
  Future<MedicalEventModel?> getEventById(String id);
  Future<void> insertOrUpdateEvent(MedicalEventModel event);
  Future<void> deleteEvent(String id);
}

class MedicalLocalDataSourceImpl implements MedicalLocalDataSource {
  final DatabaseHelper databaseHelper;

  MedicalLocalDataSourceImpl({required this.databaseHelper});

  Future<Database> get _db => databaseHelper.database;

  @override
  Future<List<MedicalEventModel>> getAllEvents({String? userId}) async {
    final db = await _db;
    List<Map<String, dynamic>> results;
    if (userId != null && userId.isNotEmpty) {
      results = await db.query(
        'medical_events',
        where: 'user_id = ? OR user_id IS NULL',
        whereArgs: [userId],
        orderBy: 'date DESC',
      );
    } else {
      results = await db.query(
        'medical_events',
        orderBy: 'date DESC',
      );
    }
    return results.map((row) => MedicalEventModel.fromJson(row)).toList();
  }

  @override
  Future<MedicalEventModel?> getEventById(String id) async {
    final db = await _db;
    final results = await db.query(
      'medical_events',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return MedicalEventModel.fromJson(results.first);
  }

  @override
  Future<void> insertOrUpdateEvent(MedicalEventModel event) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.insert(
        'medical_events',
        event.toSqliteMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Đồng bộ quan hệ prescriptions & medicines để CSDL luôn chuẩn hóa và nhất quán
      if (event.prescription != null) {
        final pres = event.prescription!;
        await txn.insert(
          'prescriptions',
          {
            'id': pres.id,
            'event_id': event.id,
            'doctor_name': pres.doctorName,
            'hospital': pres.hospital,
            'issued_date': pres.issuedDate.toIso8601String(),
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
              'instructions': med.frequency,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  @override
  Future<void> deleteEvent(String id) async {
    final db = await _db;
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
  }
}
