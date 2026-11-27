import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

abstract class DatabaseHelper {
  Future<Database> get database;
  Future<void> init();
  Future<void> close();
}

class AppDatabaseHelper implements DatabaseHelper {
  static const String _dbName = 'so_tay_y_te.db';
  static const int _dbVersion = 4;

  Database? _db;

  @override
  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  @override
  Future<void> init() async {
    _db = await database;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Bảng hồ sơ / đợt khám y tế (hỗ trợ đa thành viên & đồng bộ xóa mềm)
    await db.execute('''
      CREATE TABLE medical_events (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        member_id TEXT NOT NULL DEFAULT 'primary',
        title TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        facility_name TEXT,
        doctor_name TEXT,
        department TEXT,
        diagnosis TEXT,
        blood_pressure TEXT,
        heart_rate TEXT,
        spo2 TEXT,
        temperature TEXT,
        prescription_json TEXT,
        attachments TEXT,
        hospital_fee TEXT,
        sync_status TEXT DEFAULT 'dirty',
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT
      )
    ''');

    // 2. Bảng đơn thuốc
    await db.execute('''
      CREATE TABLE prescriptions (
        id TEXT PRIMARY KEY,
        event_id TEXT NOT NULL,
        doctor_name TEXT NOT NULL,
        hospital TEXT,
        issued_date TEXT NOT NULL,
        duration_days INTEGER,
        status TEXT DEFAULT 'active',
        note TEXT,
        FOREIGN KEY (event_id) REFERENCES medical_events (id) ON DELETE CASCADE
      )
    ''');

    // 3. Bảng chi tiết thuốc trong đơn
    await db.execute('''
      CREATE TABLE medicines (
        id TEXT PRIMARY KEY,
        prescription_id TEXT NOT NULL,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        frequency TEXT NOT NULL,
        instructions TEXT,
        FOREIGN KEY (prescription_id) REFERENCES prescriptions (id) ON DELETE CASCADE
      )
    ''');

    // 4. Bảng thông tin người dùng & thẻ cấp cứu
    await db.execute('''
      CREATE TABLE user_profile (
        id TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        date_of_birth TEXT,
        blood_type TEXT,
        allergies TEXT,
        chronic_conditions TEXT,
        emergency_contact TEXT,
        is_pro INTEGER NOT NULL DEFAULT 0,
        height TEXT,
        weight TEXT,
        gender TEXT,
        organ_donor TEXT,
        region TEXT
      )
    ''');

    // 5. Bảng tài khoản người dùng bảo mật chuẩn y tế
    await _createAuthTables(db);

    // 6. Bảng thành viên gia đình
    await _createFamilyMembersTable(db);

    // 7. Bảng tài liệu y tế
    await _createMedicalDocumentsTable(db);

    // 8. Bảng token chia sẻ QR Bác sĩ
    await _createDoctorShareTokensTable(db);

    // 9. Các bảng mở rộng V4 cho người lớn tuổi (40+)
    await _createElderCareV4Tables(db);
    await _seedElderCareSampleDataIfEmpty(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _createAuthTables(db);
    await _createFamilyMembersTable(db);
    await _createMedicalDocumentsTable(db);
    await _createDoctorShareTokensTable(db);
    await _ensureMedicalEventsSchema(db);
    await _createElderCareV4Tables(db);
    await _seedElderCareSampleDataIfEmpty(db);
  }

  Future<void> _createDoctorShareTokensTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS doctor_share_tokens (
        token TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        pin_code TEXT NOT NULL,
        scopes TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        is_revoked INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createMedicalDocumentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS medical_documents (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        member_id TEXT NOT NULL DEFAULT 'primary',
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        file_path TEXT NOT NULL,
        hospital TEXT,
        date TEXT NOT NULL,
        summary TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createFamilyMembersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS family_members (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        relationship TEXT NOT NULL,
        blood_type TEXT,
        dob TEXT,
        gender TEXT,
        phone TEXT,
        allergies TEXT,
        chronic_conditions TEXT,
        avatar_asset TEXT,
        height TEXT,
        weight TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createAuthTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        patient_code TEXT UNIQUE NOT NULL,
        full_name TEXT NOT NULL,
        primary_contact TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        date_of_birth TEXT,
        gender TEXT,
        blood_type TEXT,
        avatar_url TEXT,
        is_guest INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS auth_identities (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        provider TEXT NOT NULL,
        provider_uid TEXT NOT NULL,
        email_associated TEXT,
        linked_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onOpen(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    await _createAuthTables(db);
    await _createFamilyMembersTable(db);
    await _createMedicalDocumentsTable(db);
    await _createDoctorShareTokensTable(db);
    await _ensureMedicalEventsSchema(db);
    await _createElderCareV4Tables(db);
    await _seedElderCareSampleDataIfEmpty(db);

    await db.delete(
      'auth_identities',
      where: 'user_id = ?',
      whereArgs: ['default-demo-user-01'],
    );
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: ['default-demo-user-01'],
    );

    await _syncPrescriptionsFromMedicalEvents(db);
  }

  Future<void> _syncPrescriptionsFromMedicalEvents(Database db) async {
    try {
      final events = await db.query(
        'medical_events',
        where:
            'prescription_json IS NOT NULL AND prescription_json != "" AND (deleted_at IS NULL OR deleted_at = "")',
      );
      for (final ev in events) {
        final evId = ev['id'] as String;
        final presJsonStr = ev['prescription_json'] as String?;
        if (presJsonStr == null || presJsonStr.isEmpty) continue;

        final decoded = jsonDecode(presJsonStr);
        if (decoded is Map<String, dynamic>) {
          final presId = decoded['id'] as String? ?? 'pres_$evId';
          await db.insert(
            'prescriptions',
            {
              'id': presId,
              'event_id': evId,
              'doctor_name': decoded['doctor_name'] ?? decoded['doctorName'] ?? '',
              'hospital': decoded['hospital'] ?? '',
              'issued_date': decoded['issued_date'] ?? decoded['issuedDate'] ?? DateTime.now().toIso8601String(),
              'duration_days': decoded['duration_days'],
              'status': decoded['status'] ?? 'active',
              'note': decoded['note'] ?? '',
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          final meds = decoded['medicines'] as List<dynamic>? ?? [];
          for (final m in meds) {
            if (m is Map<String, dynamic>) {
              await db.insert(
                'medicines',
                {
                  'id': m['id'] ?? 'med_${DateTime.now().millisecondsSinceEpoch}',
                  'prescription_id': presId,
                  'name': m['name'] ?? '',
                  'dosage': m['dosage'] ?? '',
                  'frequency': m['frequency'] ?? m['instruction'] ?? '',
                  'instructions': m['instruction'] ?? m['instructions'] ?? m['frequency'] ?? '',
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _ensureMedicalEventsSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS medical_events (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        member_id TEXT NOT NULL DEFAULT 'primary',
        title TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        facility_name TEXT,
        doctor_name TEXT,
        department TEXT,
        diagnosis TEXT,
        blood_pressure TEXT,
        heart_rate TEXT,
        spo2 TEXT,
        temperature TEXT,
        prescription_json TEXT,
        attachments TEXT,
        hospital_fee TEXT,
        sync_status TEXT DEFAULT 'dirty',
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT
      )
    ''');

    try {
      final tableInfo = await db.rawQuery('PRAGMA table_info(medical_events)');
      final existingColumns = tableInfo.map((row) => row['name'] as String).toSet();

      final requiredColumns = {
        'user_id': 'TEXT',
        'member_id': "TEXT NOT NULL DEFAULT 'primary'",
        'facility_name': 'TEXT',
        'doctor_name': 'TEXT',
        'department': 'TEXT',
        'diagnosis': 'TEXT',
        'blood_pressure': 'TEXT',
        'heart_rate': 'TEXT',
        'spo2': 'TEXT',
        'temperature': 'TEXT',
        'prescription_json': 'TEXT',
        'hospital_fee': 'TEXT',
        'sync_status': "TEXT DEFAULT 'dirty'",
        'created_at': 'TEXT',
        'updated_at': 'TEXT',
        'deleted_at': 'TEXT',
      };

      for (final entry in requiredColumns.entries) {
        if (!existingColumns.contains(entry.key)) {
          try {
            await db.execute('ALTER TABLE medical_events ADD COLUMN ${entry.key} ${entry.value}');
          } catch (_) {}
        }
      }

      final presInfo = await db.rawQuery('PRAGMA table_info(prescriptions)');
      final existingPresCols = presInfo.map((row) => row['name'] as String).toSet();
      final requiredPresCols = {
        'duration_days': 'INTEGER',
        'status': "TEXT DEFAULT 'active'",
      };
      for (final entry in requiredPresCols.entries) {
        if (!existingPresCols.contains(entry.key)) {
          try {
            await db.execute('ALTER TABLE prescriptions ADD COLUMN ${entry.key} ${entry.value}');
          } catch (_) {}
        }
      }

      final docInfo = await db.rawQuery('PRAGMA table_info(medical_documents)');
      final existingDocCols = docInfo.map((row) => row['name'] as String).toSet();
      if (!existingDocCols.contains('member_id')) {
        try {
          await db.execute("ALTER TABLE medical_documents ADD COLUMN member_id TEXT NOT NULL DEFAULT 'primary'");
        } catch (_) {}
      }

      final profileInfo = await db.rawQuery('PRAGMA table_info(user_profile)');
      final existingProfileCols = profileInfo.map((row) => row['name'] as String).toSet();
      final requiredProfileCols = {
        'height': 'TEXT',
        'weight': 'TEXT',
        'gender': 'TEXT',
        'organ_donor': 'TEXT',
        'region': 'TEXT',
        'special_history_note': 'TEXT',
      };
      for (final entry in requiredProfileCols.entries) {
        if (!existingProfileCols.contains(entry.key)) {
          try {
            await db.execute('ALTER TABLE user_profile ADD COLUMN ${entry.key} ${entry.value}');
          } catch (_) {}
        }
      }

      final famInfo = await db.rawQuery('PRAGMA table_info(family_members)');
      final existingFamCols = famInfo.map((row) => row['name'] as String).toSet();
      final requiredFamCols = {
        'height': 'TEXT',
        'weight': 'TEXT',
        'gender': 'TEXT',
        'phone': 'TEXT',
        'allergies': 'TEXT',
        'chronic_conditions': 'TEXT',
        'avatar_asset': 'TEXT',
        'special_history_note': 'TEXT',
      };
      for (final entry in requiredFamCols.entries) {
        if (!existingFamCols.contains(entry.key)) {
          try {
            await db.execute('ALTER TABLE family_members ADD COLUMN ${entry.key} ${entry.value}');
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  Future<void> _createElderCareV4Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_vitals_logs (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        member_id TEXT NOT NULL DEFAULT 'primary',
        date_key TEXT NOT NULL,
        measured_at TEXT NOT NULL,
        systolic INTEGER NOT NULL,
        diastolic INTEGER NOT NULL,
        heart_rate INTEGER,
        status_level TEXT NOT NULL,
        source TEXT NOT NULL DEFAULT 'manual',
        image_path TEXT,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_health_tasks (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        member_id TEXT NOT NULL DEFAULT 'primary',
        date_key TEXT NOT NULL,
        title TEXT NOT NULL,
        subtitle TEXT,
        category TEXT NOT NULL,
        time_label TEXT,
        linked_slot_id TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS my_doctors (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        member_id TEXT NOT NULL DEFAULT 'primary',
        full_name TEXT NOT NULL,
        specialty TEXT NOT NULL,
        hospital_name TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        avatar_path TEXT,
        last_visit_date TEXT,
        last_visit_note TEXT,
        is_primary_doctor INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS health_videos (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        duration_label TEXT NOT NULL,
        thumbnail_url TEXT NOT NULL,
        video_url TEXT NOT NULL,
        instructor_name TEXT,
        description TEXT,
        key_steps_json TEXT,
        is_saved INTEGER NOT NULL DEFAULT 0,
        last_watched_at TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS nutrition_guidelines (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        member_id TEXT NOT NULL DEFAULT 'primary',
        type TEXT NOT NULL,
        health_tag TEXT NOT NULL,
        food_name TEXT NOT NULL,
        recommended_amount TEXT,
        benefit_or_risk TEXT NOT NULL,
        icon_name TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS dietary_supplements (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        member_id TEXT NOT NULL DEFAULT 'primary',
        product_name TEXT NOT NULL,
        category TEXT NOT NULL,
        image_path TEXT,
        benefits TEXT NOT NULL,
        dosage_guide TEXT NOT NULL,
        usage_status TEXT NOT NULL DEFAULT 'using',
        caution_note TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _seedElderCareSampleDataIfEmpty(Database db) async {
    try {
      final nowIso = DateTime.now().toIso8601String();

      // 1. Seed mẫu số đo huyết áp ngày hôm qua nếu bảng trống để hiển thị ngay so sánh Hôm qua vs Hôm nay
      final vitalsCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM daily_vitals_logs'),
          ) ??
          0;
      if (vitalsCount == 0) {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final yKey =
            '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
        await db.insert('daily_vitals_logs', {
          'id': 'seed_bp_yesterday_primary',
          'user_id': 'seed',
          'member_id': 'primary',
          'date_key': yKey,
          'measured_at': DateTime(yesterday.year, yesterday.month, yesterday.day, 7, 30)
              .toIso8601String(),
          'systolic': 126,
          'diastolic': 82,
          'heart_rate': 74,
          'status_level': 'normal',
          'source': 'manual',
          'note': 'Đo buổi sáng trước bữa ăn',
        });
      }

      // 2. Seed Danh bạ Bác sĩ đã khám
      final docCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM my_doctors'),
          ) ??
          0;
      if (docCount == 0) {
        final sampleDoctors = [
          {
            'id': 'doc_seed_cardiology_01',
            'user_id': 'seed',
            'member_id': 'all',
            'full_name': 'PGS.TS.BS Nguyễn Hoàng Việt',
            'specialty': 'Tim mạch & Huyết áp người cao tuổi',
            'hospital_name': 'Bệnh viện Đại học Y Dược - Khoa Tim Mạch',
            'phone_number': '0903128456',
            'avatar_path': 'assets/images/img_profile_bo_hai.png',
            'last_visit_date': '15/10/2026',
            'last_visit_note':
                'Huyết áp kiểm soát tốt với Amlodipin 5mg. Duy trì ăn nhạt, đi bộ 20 phút mỗi chiều, hẹn tái khám sau 3 tháng.',
            'is_primary_doctor': 1,
            'created_at': nowIso,
            'updated_at': nowIso,
          },
          {
            'id': 'doc_seed_ortho_02',
            'user_id': 'seed',
            'member_id': 'all',
            'full_name': 'BS.CKII Trần Thu Hà',
            'specialty': 'Cơ xương khớp & Phục hồi chức năng',
            'hospital_name': 'Bệnh viện Chợ Rẫy - Phòng khám Chuyên gia',
            'phone_number': '0918456789',
            'avatar_path': 'assets/images/img_profile_thu_trang.png',
            'last_visit_date': '02/09/2026',
            'last_visit_note':
                'Thoái hóa nhẹ khớp gối hai bên. Hạn chế leo cầu thang cao, bổ sung Glucosamine & tập co duỗi khớp tại giường buổi sáng.',
            'is_primary_doctor': 0,
            'created_at': nowIso,
            'updated_at': nowIso,
          },
          {
            'id': 'doc_seed_general_03',
            'user_id': 'seed',
            'member_id': 'all',
            'full_name': 'ThS.BS Lê Minh Quân',
            'specialty': 'Nội tiết - Đái tháo đường & Dinh dưỡng',
            'hospital_name': 'Bệnh viện Đa khoa Tâm Anh',
            'phone_number': '0987654321',
            'avatar_path': 'assets/images/img_patient_avatar.png',
            'last_visit_date': '18/07/2026',
            'last_visit_note':
                'Đường huyết lúc đói và mỡ máu ổn định. Tăng cường cá biển, rau xanh đậm, giảm tinh bột trắng buổi tối.',
            'is_primary_doctor': 0,
            'created_at': nowIso,
            'updated_at': nowIso,
          },
        ];
        for (final doc in sampleDoctors) {
          await db.insert('my_doctors', doc);
        }
      }

      // 3. Seed Kho Video sức khỏe người cao tuổi
      final videoCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM health_videos'),
          ) ??
          0;
      if (videoCount == 0) {
        final sampleVideos = [
          {
            'id': 'vid_bp_breathing_01',
            'title': 'Bài tập Thở Chậm 4-7-8 giúp ổn định Huyết áp & Nhịp tim tại nhà',
            'category': 'Tim mạch & Huyết áp',
            'duration_label': '10 phút',
            'thumbnail_url': 'assets/images/img_profile_hero_portrait.png',
            'video_url': 'https://www.youtube.com/watch?v=kpSkoXRrZnE',
            'instructor_name': 'BS.CKI Phục hồi chức năng Hoàng Nam',
            'description':
                'Bài tập hít thở bằng cơ hoành nhẹ nhàng dành riêng cho người từ 45 tuổi trở lên, giúp thư giãn thành mạch và hạ áp tự nhiên.',
            'key_steps_json': jsonEncode([
              'Bước 1: Ngồi thẳng lưng thoải mái trên ghế có tựa, thả lỏng hai vai.',
              'Bước 2: Hít vào thật êm bằng mũi trong 4 giây, bụng phình nhẹ.',
              'Bước 3: Giữ hơi nhẹ nhàng 4–7 giây (không gồng ngực).',
              'Bước 4: Thở ra từ từ bằng miệng trong 6–8 giây. Lặp lại 8–10 nhịp.',
            ]),
            'is_saved': 1,
            'created_at': nowIso,
          },
          {
            'id': 'vid_knee_joint_02',
            'title': '5 Động tác vận động Khớp Gối nhẹ nhàng giảm đau mỏi buổi sáng',
            'category': 'Xương khớp',
            'duration_label': '14 phút',
            'thumbnail_url': 'assets/images/img_doc_xray.png',
            'video_url': 'https://www.youtube.com/watch?v=M6_3bB2RkZc',
            'instructor_name': 'Chuyên gia Vật lý trị liệu Minh Trang',
            'description':
                'Giúp tiết dịch khớp tự nhiên, giảm cứng khớp gối sau khi thức dậy mà không gây áp lực lên sụn khớp.',
            'key_steps_json': jsonEncode([
              'Bước 1: Ngồi trên mép giường hoặc ghế chắc chắn, hai bàn chân chạm sàn.',
              'Bước 2: Từ từ duỗi thẳng chân phải song song mặt sàn, giữ 5 giây rồi hạ xuống.',
              'Bước 3: Đổi sang chân trái, thực hiện chậm rãi 10 lần mỗi bên.',
              'Bước 4: Xoa ấm hai lòng bàn tay rồi massage nhẹ quanh bánh chè 2 phút.',
            ]),
            'is_saved': 1,
            'created_at': nowIso,
          },
          {
            'id': 'vid_neck_shoulder_03',
            'title': 'Thể dục Dưỡng sinh Cổ Vai Gáy phòng ngừa tê bì tay & mất ngủ',
            'category': 'Dưỡng sinh & Hơi thở',
            'duration_label': '12 phút',
            'thumbnail_url': 'assets/images/img_doc_blood_test.png',
            'video_url': 'https://www.youtube.com/watch?v=X3-gKPNyrTA',
            'instructor_name': 'ThS.BS Y học cổ truyền Quốc Bảo',
            'description':
                'Các động tác xoay mở khớp vai và kéo giãn vùng cổ cực chậm, tăng tuần hoàn máu lên não.',
            'key_steps_json': jsonEncode([
              'Bước 1: Xoay tròn hai khớp vai ra sau 10 vòng thật chậm kết hợp hít sâu.',
              'Bước 2: Nghiêng đầu nhẹ sang phải giữ 10 giây, đổi bên sang trái (không xoay giật cổ).',
              'Bước 3: Đan hai tay vươn nhẹ qua đầu, mở lồng ngực hít thở 5 nhịp.',
            ]),
            'is_saved': 0,
            'created_at': nowIso,
          },
          {
            'id': 'vid_sleep_relax_04',
            'title': 'Thư giãn gân cơ buổi tối giúp người lớn tuổi ngủ sâu tới sáng',
            'category': 'Giấc ngủ',
            'duration_label': '15 phút',
            'thumbnail_url': 'assets/images/img_doc_endoscopy.png',
            'video_url': 'https://www.youtube.com/watch?v=1ZYbU82GVz4',
            'instructor_name': 'BS. Nội Thần kinh Thanh Thảo',
            'description':
                'Thực hiện trên giường trước giờ đi ngủ 20 phút kết hợp ngâm chân nước ấm giúp dễ vào giấc ngủ.',
            'key_steps_json': jsonEncode([
              'Bước 1: Ngâm hai bàn chân với nước ấm 40 độ C trong 10 phút và lau khô.',
              'Bước 2: Nằm ngửa thoải mái, co duỗi nhẹ cổ chân 15 nhịp để máu lưu thông.',
              'Bước 3: Đặt tay lên bụng, thở êm đều và thả lỏng toàn bộ cơ mặt.',
            ]),
            'is_saved': 0,
            'created_at': nowIso,
          },
        ];
        for (final vid in sampleVideos) {
          await db.insert('health_videos', vid);
        }
      }

      // 4. Seed Chế độ Dinh dưỡng Nên ăn / Nên kiêng
      final nutCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM nutrition_guidelines'),
          ) ??
          0;
      if (nutCount == 0) {
        final sampleNutrition = [
          {
            'id': 'nut_eat_01',
            'user_id': 'seed',
            'member_id': 'all',
            'type': 'should_eat',
            'health_tag': 'Huyết áp & Tim mạch',
            'food_name': 'Cá biển sâu (Cá hồi, cá thu, cá trích)',
            'recommended_amount': '2–3 bữa / tuần (100g–120g mỗi bữa)',
            'benefit_or_risk':
                'Giàu Omega-3 tự nhiên giúp giảm mỡ máu xấu, bảo vệ thành mạch và ổn định huyết áp.',
            'icon_name': 'fish',
            'created_at': nowIso,
          },
          {
            'id': 'nut_eat_02',
            'user_id': 'seed',
            'member_id': 'all',
            'type': 'should_eat',
            'health_tag': 'Huyết áp & Tim mạch',
            'food_name': 'Rau lá xanh đậm & Chuối chín, Khoai lang',
            'recommended_amount': '300g rau xanh + 1 quả chuối / ngày',
            'benefit_or_risk':
                'Cung cấp Kali, Magie và chất xơ giúp đào thải muối thừa (Natri) và ngừa táo bón.',
            'icon_name': 'leaf',
            'created_at': nowIso,
          },
          {
            'id': 'nut_eat_03',
            'user_id': 'seed',
            'member_id': 'all',
            'type': 'should_eat',
            'health_tag': 'Xương khớp',
            'food_name': 'Sữa hạt ít đường, Đậu phụ, Tôm cá nhỏ ăn cả xương mềm',
            'recommended_amount': '1–2 khẩu phần mỗi ngày',
            'benefit_or_risk':
                'Bổ sung Canxi hữu cơ dễ hấp thu và đạm thực vật lành mạnh phòng loãng xương.',
            'icon_name': 'bone',
            'created_at': nowIso,
          },
          {
            'id': 'nut_eat_04',
            'user_id': 'seed',
            'member_id': 'all',
            'type': 'should_eat',
            'health_tag': 'Đường huyết',
            'food_name': 'Yến mạch nguyên cám, Gạo lứt mềm & Các loại hạt',
            'recommended_amount': 'Thay thế 1/2 lượng cơm trắng buổi sáng/tối',
            'benefit_or_risk':
                'Chỉ số đường huyết thấp, giúp no lâu mà không làm tăng vọt đường máu sau ăn.',
            'icon_name': 'grain',
            'created_at': nowIso,
          },
          {
            'id': 'nut_avoid_01',
            'user_id': 'seed',
            'member_id': 'all',
            'type': 'should_avoid',
            'health_tag': 'Huyết áp & Tim mạch',
            'food_name': 'Đồ muối chua, Cá khô, Mì gói & Nước chấm mặn',
            'recommended_amount': 'Kiêng tối đa (Tổng muối < 5g / ngày)',
            'benefit_or_risk':
                'Lượng muối Natri cao gây giữ nước trong lòng mạch, làm tăng vọt huyết áp đột ngột.',
            'icon_name': 'salt_warn',
            'created_at': nowIso,
          },
          {
            'id': 'nut_avoid_02',
            'user_id': 'seed',
            'member_id': 'all',
            'type': 'should_avoid',
            'health_tag': 'Huyết áp & Tim mạch',
            'food_name': 'Mỡ động vật, Nội tạng & Thực phẩm chiên đi chiên lại',
            'recommended_amount': 'Hạn chế tối đa',
            'benefit_or_risk':
                'Làm tăng Cholesterol xấu gây xơ vữa động mạch và tăng gánh nặng cho tim.',
            'icon_name': 'fat_warn',
            'created_at': nowIso,
          },
          {
            'id': 'nut_avoid_03',
            'user_id': 'seed',
            'member_id': 'all',
            'type': 'should_avoid',
            'health_tag': 'Xương khớp',
            'food_name': 'Rượu bia, Nước ngọt có gas & Trà đặc buổi tối',
            'recommended_amount': 'Tránh dùng, đặc biệt sau 17:00',
            'benefit_or_risk':
                'Cản trở hấp thu Canxi, dễ kích hoạt cơn đau khớp/Gout và gây mất ngủ ban đêm.',
            'icon_name': 'drink_warn',
            'created_at': nowIso,
          },
        ];
        for (final n in sampleNutrition) {
          await db.insert('nutrition_guidelines', n);
        }
      }

      // 5. Seed Thực phẩm chức năng đang dùng / tham khảo
      final supCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM dietary_supplements'),
          ) ??
          0;
      if (supCount == 0) {
        final sampleSupplements = [
          {
            'id': 'sup_seed_omega3_01',
            'user_id': 'seed',
            'member_id': 'all',
            'product_name': 'Dầu cá Omega-3 Tinh Khiết 1000mg (EPA & DHA)',
            'category': 'Tim mạch & Thị lực',
            'image_path': 'assets/images/img_doc_blood_test.png',
            'benefits':
                'Hỗ trợ giảm Triglyceride máu, bảo vệ tim mạch, giảm khô mỏi mắt ở người lớn tuổi.',
            'dosage_guide': 'Ngày uống 1 viên nang mềm ngay sau bữa ăn trưa.',
            'usage_status': 'using',
            'caution_note':
                'Nếu đang dùng thuốc chống đông máu (Aspirin/Warfarin), cần hỏi ý kiến bác sĩ tim mạch.',
            'created_at': nowIso,
          },
          {
            'id': 'sup_seed_calcium_02',
            'user_id': 'seed',
            'member_id': 'all',
            'product_name': 'Canxi Hữu Cơ + Vitamin D3 & K2 MK7',
            'category': 'Xương khớp & Răng',
            'image_path': 'assets/images/img_doc_xray.png',
            'benefits':
                'Giúp gắn Canxi đúng vào xương, phòng ngừa loãng xương và chuột rút ban đêm.',
            'dosage_guide': 'Uống 1 viên vào buổi sáng sau ăn (kèm 1 cốc nước lớn). Không uống buổi tối.',
            'usage_status': 'using',
            'caution_note':
                'Uống cách các loại thuốc huyết áp hoặc kháng sinh ít nhất 2 tiếng.',
            'created_at': nowIso,
          },
          {
            'id': 'sup_seed_glucosamine_03',
            'user_id': 'seed',
            'member_id': 'all',
            'product_name': 'Glucosamine Sulfate 1500mg & Chondroitin',
            'category': 'Bổ sụn khớp',
            'image_path': 'assets/images/img_doc_hp_test.png',
            'benefits':
                'Hỗ trợ tái tạo sụn khớp, tăng độ nhờn dịch khớp gối, giảm lục khục khi đi lại.',
            'dosage_guide': 'Ngày uống 1–2 viên chia sau bữa ăn no.',
            'usage_status': 'reference',
            'caution_note':
                'Người dị ứng hải sản vỏ cứng hoặc đang theo dõi đường huyết nên tham khảo bác sĩ trước khi dùng.',
            'created_at': nowIso,
          },
        ];
        for (final s in sampleSupplements) {
          await db.insert('dietary_supplements', s);
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
