import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../../../domain/entities/daily_health_task.dart';
import '../../../domain/entities/daily_vital_log.dart';
import '../../../domain/entities/doctor_contact.dart';
import '../../../domain/entities/health_video.dart';
import '../../../domain/entities/nutrition_item.dart';

abstract class ElderCareLocalDataSource {
  // 1. Huyết áp hằng ngày
  Future<DailyVitalLog?> getLatestVitalForDate({
    String? userId,
    required String memberId,
    required String dateKey,
  });
  Future<List<DailyVitalLog>> getRecentVitalLogs({
    String? userId,
    required String memberId,
    int limit = 14,
  });
  Future<void> upsertVitalLog(DailyVitalLog log);

  // 2. Việc cần làm trong ngày
  Future<List<DailyHealthTask>> getTasksForDate({
    String? userId,
    required String memberId,
    required String dateKey,
  });
  Future<void> upsertTask(DailyHealthTask task);
  Future<void> toggleTaskStatus(String taskId, bool completed);
  Future<void> markTasksCompletedByCategory({
    String? userId,
    required String memberId,
    required String dateKey,
    required HealthTaskCategory category,
  });
  Future<void> syncMedicationSlotTaskStatus({
    String? userId,
    required String memberId,
    required String dateKey,
    required String slotId,
    required bool completed,
  });
  Future<void> deleteTask(String taskId);

  // 3. Lưu ý đặc biệt về tiền sử bệnh
  Future<String> getSpecialHistoryNote({
    String? userId,
    required String memberId,
  });
  Future<void> saveSpecialHistoryNote({
    String? userId,
    required String memberId,
    required String note,
  });

  // 4. Danh bạ bác sĩ đã khám
  Future<List<DoctorContact>> getDoctors({
    String? userId,
    required String memberId,
  });
  Future<void> upsertDoctor(DoctorContact doctor);
  Future<void> deleteDoctor(String doctorId);

  // 5. Video sức khỏe
  Future<List<HealthVideo>> getHealthVideos({String? category});
  Future<void> toggleSaveVideo(String videoId, bool isSaved);
  Future<void> markVideoWatched(String videoId);

  // 6. Dinh dưỡng & Thực phẩm chức năng
  Future<List<NutritionGuideline>> getNutritionGuidelines({
    String? userId,
    required String memberId,
    String? healthTag,
  });
  Future<void> upsertNutritionGuideline(NutritionGuideline item);

  Future<List<DietarySupplement>> getSupplements({
    String? userId,
    required String memberId,
  });
  Future<void> upsertSupplement(DietarySupplement item);
  Future<void> deleteSupplement(String supplementId);
}

class ElderCareLocalDataSourceImpl implements ElderCareLocalDataSource {
  final DatabaseHelper databaseHelper;

  ElderCareLocalDataSourceImpl({required this.databaseHelper});

  Future<Database> get _db => databaseHelper.database;

  String _userScopeClause(String? userId, List<Object?> args, {bool includeSeed = false}) {
    if (userId == null || userId.trim().isEmpty) {
      return includeSeed
          ? '(user_id IS NULL OR user_id = "" OR user_id = "seed")'
          : '1 = 1';
    }
    args.add(userId.trim());
    if (includeSeed) {
      return '(user_id = ? OR user_id IS NULL OR user_id = "" OR user_id = "seed")';
    }
    return '(user_id = ? OR user_id IS NULL OR user_id = "")';
  }

  String _memberScopeClause(String memberId, List<Object?> args, {bool includeSharedSeed = false}) {
    final normalized = memberId.trim().isEmpty ? 'primary' : memberId.trim();
    args.add(normalized);
    if (normalized == 'primary') {
      return includeSharedSeed
          ? '(member_id = ? OR member_id IS NULL OR member_id = "" OR member_id = "all")'
          : '(member_id = ? OR member_id IS NULL OR member_id = "")';
    }
    return includeSharedSeed
        ? '(member_id = ? OR member_id = "all")'
        : 'member_id = ?';
  }

  @override
  Future<DailyVitalLog?> getLatestVitalForDate({
    String? userId,
    required String memberId,
    required String dateKey,
  }) async {
    final db = await _db;
    final args = <Object?>[dateKey];
    final uClause = _userScopeClause(userId, args, includeSeed: true);
    final mClause = _memberScopeClause(memberId, args, includeSharedSeed: false);

    final rows = await db.query(
      'daily_vitals_logs',
      where: 'date_key = ? AND $uClause AND $mClause',
      whereArgs: args,
      orderBy: 'measured_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DailyVitalLog.fromMap(rows.first);
  }

  @override
  Future<List<DailyVitalLog>> getRecentVitalLogs({
    String? userId,
    required String memberId,
    int limit = 14,
  }) async {
    final db = await _db;
    final args = <Object?>[];
    final uClause = _userScopeClause(userId, args, includeSeed: true);
    final mClause = _memberScopeClause(memberId, args, includeSharedSeed: false);

    final rows = await db.query(
      'daily_vitals_logs',
      where: '$uClause AND $mClause',
      whereArgs: args,
      orderBy: 'measured_at DESC',
      limit: limit,
    );
    return rows.map(DailyVitalLog.fromMap).toList();
  }

  @override
  Future<void> upsertVitalLog(DailyVitalLog log) async {
    final db = await _db;
    await db.insert(
      'daily_vitals_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<DailyHealthTask>> getTasksForDate({
    String? userId,
    required String memberId,
    required String dateKey,
  }) async {
    final db = await _db;
    final args = <Object?>[dateKey];
    final uClause = _userScopeClause(userId, args, includeSeed: false);
    final mClause = _memberScopeClause(memberId, args, includeSharedSeed: false);

    final rows = await db.query(
      'daily_health_tasks',
      where: 'date_key = ? AND $uClause AND $mClause',
      whereArgs: args,
      orderBy: 'time_label ASC, rowid ASC',
    );
    return rows.map(DailyHealthTask.fromMap).toList();
  }

  @override
  Future<void> upsertTask(DailyHealthTask task) async {
    final db = await _db;
    await db.insert(
      'daily_health_tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> toggleTaskStatus(String taskId, bool completed) async {
    final db = await _db;
    await db.update(
      'daily_health_tasks',
      {
        'is_completed': completed ? 1 : 0,
        'completed_at': completed ? DateTime.now().toIso8601String() : null,
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  @override
  Future<void> markTasksCompletedByCategory({
    String? userId,
    required String memberId,
    required String dateKey,
    required HealthTaskCategory category,
  }) async {
    final db = await _db;
    final args = <Object?>[dateKey, category.name];
    final uClause = _userScopeClause(userId, args, includeSeed: false);
    final mClause = _memberScopeClause(memberId, args, includeSharedSeed: false);

    await db.update(
      'daily_health_tasks',
      {
        'is_completed': 1,
        'completed_at': DateTime.now().toIso8601String(),
      },
      where: 'date_key = ? AND category = ? AND $uClause AND $mClause',
      whereArgs: args,
    );
  }

  @override
  Future<void> syncMedicationSlotTaskStatus({
    String? userId,
    required String memberId,
    required String dateKey,
    required String slotId,
    required bool completed,
  }) async {
    final db = await _db;
    final args = <Object?>[dateKey, slotId];
    final uClause = _userScopeClause(userId, args, includeSeed: false);
    final mClause = _memberScopeClause(memberId, args, includeSharedSeed: false);

    await db.update(
      'daily_health_tasks',
      {
        'is_completed': completed ? 1 : 0,
        'completed_at': completed ? DateTime.now().toIso8601String() : null,
      },
      where: 'date_key = ? AND linked_slot_id = ? AND $uClause AND $mClause',
      whereArgs: args,
    );
  }

  @override
  Future<void> deleteTask(String taskId) async {
    final db = await _db;
    await db.delete('daily_health_tasks', where: 'id = ?', whereArgs: [taskId]);
  }

  @override
  Future<String> getSpecialHistoryNote({
    String? userId,
    required String memberId,
  }) async {
    final db = await _db;
    if (memberId != 'primary' && memberId.isNotEmpty) {
      final famRows = await db.query(
        'family_members',
        columns: ['special_history_note', 'allergies', 'chronic_conditions'],
        where: 'id = ?',
        whereArgs: [memberId],
        limit: 1,
      );
      if (famRows.isNotEmpty) {
        final saved = (famRows.first['special_history_note'] as String?)?.trim() ?? '';
        if (saved.isNotEmpty) return saved;
      }
      return '';
    }

    if (userId != null && userId.isNotEmpty) {
      final profRows = await db.query(
        'user_profile',
        columns: ['special_history_note'],
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );
      if (profRows.isNotEmpty) {
        final saved = (profRows.first['special_history_note'] as String?)?.trim() ?? '';
        if (saved.isNotEmpty) return saved;
      }
    } else {
      final profRows = await db.query('user_profile', limit: 1);
      if (profRows.isNotEmpty) {
        final saved = (profRows.first['special_history_note'] as String?)?.trim() ?? '';
        if (saved.isNotEmpty) return saved;
      }
    }
    return '';
  }

  @override
  Future<void> saveSpecialHistoryNote({
    String? userId,
    required String memberId,
    required String note,
  }) async {
    final db = await _db;
    final trimmed = note.trim();
    if (memberId != 'primary' && memberId.isNotEmpty) {
      await db.update(
        'family_members',
        {'special_history_note': trimmed},
        where: 'id = ?',
        whereArgs: [memberId],
      );
      return;
    }

    final targetId = (userId != null && userId.isNotEmpty) ? userId : 'primary_default';
    final existing = await db.query(
      'user_profile',
      where: 'id = ?',
      whereArgs: [targetId],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      await db.update(
        'user_profile',
        {'special_history_note': trimmed},
        where: 'id = ?',
        whereArgs: [targetId],
      );
    } else {
      await db.insert(
        'user_profile',
        {
          'id': targetId,
          'full_name': 'Chủ tài khoản',
          'special_history_note': trimmed,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  @override
  Future<List<DoctorContact>> getDoctors({
    String? userId,
    required String memberId,
  }) async {
    final db = await _db;
    final args = <Object?>[];
    final uClause = _userScopeClause(userId, args, includeSeed: true);
    final mClause = _memberScopeClause(memberId, args, includeSharedSeed: true);

    final rows = await db.query(
      'my_doctors',
      where: '$uClause AND $mClause',
      whereArgs: args,
      orderBy: 'is_primary_doctor DESC, created_at DESC',
    );
    return rows.map(DoctorContact.fromMap).toList();
  }

  @override
  Future<void> upsertDoctor(DoctorContact doctor) async {
    final db = await _db;
    await db.insert(
      'my_doctors',
      doctor.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteDoctor(String doctorId) async {
    final db = await _db;
    await db.delete('my_doctors', where: 'id = ?', whereArgs: [doctorId]);
  }

  @override
  Future<List<HealthVideo>> getHealthVideos({String? category}) async {
    final db = await _db;
    final hasCategory =
        category != null && category.trim().isNotEmpty && category != 'Tất cả';
    final rows = hasCategory
        ? await db.query(
            'health_videos',
            where: 'category = ?',
            whereArgs: [category.trim()],
            orderBy: 'is_saved DESC, created_at ASC',
          )
        : await db.query(
            'health_videos',
            orderBy: 'is_saved DESC, created_at ASC',
          );
    return rows.map(HealthVideo.fromMap).toList();
  }

  @override
  Future<void> toggleSaveVideo(String videoId, bool isSaved) async {
    final db = await _db;
    await db.update(
      'health_videos',
      {'is_saved': isSaved ? 1 : 0},
      where: 'id = ?',
      whereArgs: [videoId],
    );
  }

  @override
  Future<void> markVideoWatched(String videoId) async {
    final db = await _db;
    await db.update(
      'health_videos',
      {'last_watched_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [videoId],
    );
  }

  @override
  Future<List<NutritionGuideline>> getNutritionGuidelines({
    String? userId,
    required String memberId,
    String? healthTag,
  }) async {
    final db = await _db;
    final args = <Object?>[];
    final clauses = <String>[
      _userScopeClause(userId, args, includeSeed: true),
      _memberScopeClause(memberId, args, includeSharedSeed: true),
    ];
    if (healthTag != null && healthTag.trim().isNotEmpty && healthTag != 'Tất cả') {
      clauses.add('health_tag = ?');
      args.add(healthTag.trim());
    }
    final rows = await db.query(
      'nutrition_guidelines',
      where: clauses.join(' AND '),
      whereArgs: args,
      orderBy: 'created_at ASC',
    );
    return rows.map(NutritionGuideline.fromMap).toList();
  }

  @override
  Future<void> upsertNutritionGuideline(NutritionGuideline item) async {
    final db = await _db;
    await db.insert(
      'nutrition_guidelines',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<DietarySupplement>> getSupplements({
    String? userId,
    required String memberId,
  }) async {
    final db = await _db;
    final args = <Object?>[];
    final uClause = _userScopeClause(userId, args, includeSeed: true);
    final mClause = _memberScopeClause(memberId, args, includeSharedSeed: true);

    final rows = await db.query(
      'dietary_supplements',
      where: '$uClause AND $mClause',
      whereArgs: args,
      orderBy: 'usage_status ASC, created_at DESC',
    );
    return rows.map(DietarySupplement.fromMap).toList();
  }

  @override
  Future<void> upsertSupplement(DietarySupplement item) async {
    final db = await _db;
    await db.insert(
      'dietary_supplements',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteSupplement(String supplementId) async {
    final db = await _db;
    await db.delete(
      'dietary_supplements',
      where: 'id = ?',
      whereArgs: [supplementId],
    );
  }
}
