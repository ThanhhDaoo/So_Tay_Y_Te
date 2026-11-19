import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

abstract class DatabaseHelper {
  Future<Database> get database;
  Future<void> init();
  Future<void> close();
}

class AppDatabaseHelper implements DatabaseHelper {
  static const String _dbName = 'so_tay_y_te.db';
  static const int _dbVersion = 2;

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
      onOpen: _onOpen,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Bảng hồ sơ / đợt khám y tế
    await db.execute('''
      CREATE TABLE medical_events (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        attachments TEXT
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
    // Đảm bảo các bảng auth và medical_events luôn tồn tại kể cả khi mở DB cũ
    await _createAuthTables(db);
    await _ensureMedicalEventsSchema(db);

    // Dọn dẹp tài khoản mẫu tự động seed từ phiên bản dev cũ (nếu có)
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
  }

  Future<void> _ensureMedicalEventsSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS medical_events (
        id TEXT PRIMARY KEY,
        user_id TEXT,
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
        prescription_json TEXT,
        attachments TEXT,
        hospital_fee TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    try {
      final tableInfo = await db.rawQuery('PRAGMA table_info(medical_events)');
      final existingColumns = tableInfo.map((row) => row['name'] as String).toSet();

      final requiredColumns = {
        'user_id': 'TEXT',
        'facility_name': 'TEXT',
        'doctor_name': 'TEXT',
        'department': 'TEXT',
        'diagnosis': 'TEXT',
        'blood_pressure': 'TEXT',
        'heart_rate': 'TEXT',
        'prescription_json': 'TEXT',
        'hospital_fee': 'TEXT',
        'created_at': 'TEXT',
        'updated_at': 'TEXT',
      };

      for (final entry in requiredColumns.entries) {
        if (!existingColumns.contains(entry.key)) {
          try {
            await db.execute('ALTER TABLE medical_events ADD COLUMN ${entry.key} ${entry.value}');
          } catch (_) {}
        }
      }

      final profileInfo = await db.rawQuery('PRAGMA table_info(user_profile)');
      final existingProfileCols = profileInfo.map((row) => row['name'] as String).toSet();
      final requiredProfileCols = {
        'height': 'TEXT',
        'weight': 'TEXT',
        'gender': 'TEXT',
        'organ_donor': 'TEXT',
        'region': 'TEXT',
      };
      for (final entry in requiredProfileCols.entries) {
        if (!existingProfileCols.contains(entry.key)) {
          try {
            await db.execute('ALTER TABLE user_profile ADD COLUMN ${entry.key} ${entry.value}');
          } catch (_) {}
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
