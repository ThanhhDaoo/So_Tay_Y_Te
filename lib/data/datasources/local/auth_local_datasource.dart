import 'dart:math';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../../../domain/entities/auth_identity.dart';
import '../../models/auth_identity_model.dart';
import '../../models/user_account_model.dart';

abstract class AuthLocalDataSource {
  Future<UserAccountModel?> findById(String id);
  Future<UserAccountModel?> findByIdentifier(String identifier);
  Future<UserAccountModel?> findByProviderUid(AuthProviderType provider, String providerUid);
  Future<UserAccountModel> createUser(UserAccountModel user, {AuthIdentityModel? initialIdentity});
  Future<void> linkIdentity(AuthIdentityModel identity);
  Future<void> updatePassword(String userId, String passwordHash, String salt);
  Future<String> generateUniquePatientCode();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final DatabaseHelper databaseHelper;

  AuthLocalDataSourceImpl({required this.databaseHelper});

  Future<Database> get _db => databaseHelper.database;

  @override
  Future<UserAccountModel?> findById(String id) async {
    final db = await _db;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    final identities = await _getIdentitiesForUser(db, id);
    return UserAccountModel.fromMap(results.first, identities);
  }

  @override
  Future<UserAccountModel?> findByIdentifier(String identifier) async {
    final cleanIdentifier = identifier.trim().toLowerCase();
    final db = await _db;

    final results = await db.rawQuery(
      '''
      SELECT * FROM users 
      WHERE LOWER(patient_code) = ? OR LOWER(primary_contact) = ? 
      LIMIT 1
      ''',
      [cleanIdentifier, cleanIdentifier],
    );

    if (results.isEmpty) return null;
    final userMap = results.first;
    final identities = await _getIdentitiesForUser(db, userMap['id'] as String);
    return UserAccountModel.fromMap(userMap, identities);
  }

  @override
  Future<UserAccountModel?> findByProviderUid(
    AuthProviderType provider,
    String providerUid,
  ) async {
    final db = await _db;
    final identityResults = await db.query(
      'auth_identities',
      where: 'provider = ? AND provider_uid = ?',
      whereArgs: [provider.rawValue, providerUid],
      limit: 1,
    );

    if (identityResults.isEmpty) return null;
    final userId = identityResults.first['user_id'] as String;
    return await findById(userId);
  }

  @override
  Future<UserAccountModel> createUser(
    UserAccountModel user, {
    AuthIdentityModel? initialIdentity,
  }) async {
    final db = await _db;

    await db.transaction((txn) async {
      await txn.insert('users', user.toMap());

      if (initialIdentity != null) {
        await txn.insert('auth_identities', initialIdentity.toMap());
      }

      // Tự động tạo hồ sơ user_profile tương ứng để đồng bộ hệ thống y tế
      await txn.insert(
        'user_profile',
        {
          'id': user.id,
          'full_name': user.fullName,
          'date_of_birth': user.dateOfBirth,
          'blood_type': user.bloodType ?? 'Chưa rõ',
          'allergies': 'Không có',
          'chronic_conditions': 'Không có',
          'emergency_contact': user.primaryContact,
          'is_pro': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    final identities = await _getIdentitiesForUser(db, user.id);
    return user.copyWith(identities: identities) as UserAccountModel;
  }

  @override
  Future<void> linkIdentity(AuthIdentityModel identity) async {
    final db = await _db;
    await db.insert(
      'auth_identities',
      identity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updatePassword(
    String userId,
    String passwordHash,
    String salt,
  ) async {
    final db = await _db;
    await db.update(
      'users',
      {
        'password_hash': passwordHash,
        'salt': salt,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  @override
  Future<String> generateUniquePatientCode() async {
    final db = await _db;
    final random = Random();

    while (true) {
      final number = 100000 + random.nextInt(900000); // 6 số từ 100000 đến 999999
      final code = 'STYT-$number';

      final exists = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM users WHERE patient_code = ?',
          [code],
        ),
      );

      if (exists == 0) {
        return code;
      }
    }
  }

  Future<List<AuthIdentityModel>> _getIdentitiesForUser(
    Database db,
    String userId,
  ) async {
    final results = await db.query(
      'auth_identities',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return results.map((m) => AuthIdentityModel.fromMap(m)).toList();
  }
}
