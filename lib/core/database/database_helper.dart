import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../security/password_hasher.dart';

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
        is_pro INTEGER NOT NULL DEFAULT 0
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
    // Đảm bảo các bảng auth luôn tồn tại kể cả khi mở DB cũ
    await _createAuthTables(db);

    // Seed tài khoản Demo mặc định (STYT-892410 / 123456) nếu bảng users rỗng
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM users'),
    );

    if (count == 0) {
      final defaultSalt = PasswordHasher.generateSalt();
      final defaultHash = PasswordHasher.hashPassword('123456', defaultSalt);
      const defaultUserId = 'default-demo-user-01';

      await db.insert('users', {
        'id': defaultUserId,
        'patient_code': 'STYT-892410',
        'full_name': 'Bác sĩ Trần Tuấn Tú',
        'primary_contact': 'bacsitu@sotayyte.vn',
        'password_hash': defaultHash,
        'salt': defaultSalt,
        'date_of_birth': '1985-05-15',
        'gender': 'Nam',
        'blood_type': 'O+',
        'avatar_url': 'assets/images/img_profile_avatar.png',
        'is_guest': 0,
        'created_at': DateTime.now().toIso8601String(),
      });

      await db.insert('auth_identities', {
        'id': 'identity-demo-01',
        'user_id': defaultUserId,
        'provider': 'password',
        'provider_uid': 'bacsitu@sotayyte.vn',
        'email_associated': 'bacsitu@sotayyte.vn',
        'linked_at': DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
