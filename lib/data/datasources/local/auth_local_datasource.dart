import 'dart:math';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/utils/input_validators.dart';
import '../../../domain/entities/auth_identity.dart';
import '../../models/auth_identity_model.dart';
import '../../models/user_account_model.dart';

abstract class AuthLocalDataSource {
  Future<UserAccountModel?> findById(String id);
  Future<UserAccountModel?> findByIdentifier(String identifier);
  Future<UserAccountModel?> findByProviderUid(
    AuthProviderType provider,
    String providerUid,
  );
  Future<UserAccountModel> createUser(
    UserAccountModel user, {
    AuthIdentityModel? initialIdentity,
  });
  Future<void> linkIdentity(AuthIdentityModel identity);
  Future<void> updatePassword(
    String userId,
    String passwordHash,
    String salt,
  );
  Future<UserAccountModel?> updateProfileFields({
    required String userId,
    required String fullName,
    String? dateOfBirth,
    String? gender,
    String? bloodType,
    String? emergencyContact,
    String? allergies,
    String? chronicConditions,
    String? height,
    String? weight,
    String? organDonor,
    String? avatarUrl,
    String? region,
  });
  Future<Map<String, dynamic>?> getUserProfileData(String userId);
  Future<void> deleteUserById(String userId);
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
    if (cleanIdentifier.isEmpty) return null;
    final db = await _db;

    // Hỗ trợ tìm kiếm thông minh đa định dạng SĐT (09xxx, +849xxx, 849xxx, 9xxx)
    final variants = <String>{cleanIdentifier};
    final compact = InputValidators.stripPhoneSeparators(cleanIdentifier);
    variants.add(compact);

    final digitsOnly = cleanIdentifier.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length >= 9 && !cleanIdentifier.contains('styt')) {
      variants.add(digitsOnly);
      variants.add(InputValidators.normalizePhoneLocal(digitsOnly).toLowerCase());
      variants.add(InputValidators.normalizePhoneE164(digitsOnly).toLowerCase());
      if (digitsOnly.startsWith('84') && digitsOnly.length >= 10) {
        variants.add('0${digitsOnly.substring(2)}');
        variants.add('+$digitsOnly');
      } else if (digitsOnly.startsWith('0') && digitsOnly.length >= 9) {
        variants.add('+84${digitsOnly.substring(1)}');
        variants.add('84${digitsOnly.substring(1)}');
      }
    }

    final variantList = variants.where((v) => v.isNotEmpty).toList();
    final placeholders = List.filled(variantList.length, '?').join(', ');

    final results = await db.rawQuery(
      '''
      SELECT DISTINCT u.* FROM users u
      LEFT JOIN auth_identities ai ON ai.user_id = u.id
      WHERE LOWER(u.patient_code) IN ($placeholders)
         OR LOWER(u.primary_contact) IN ($placeholders)
         OR LOWER(ai.provider_uid) IN ($placeholders)
         OR LOWER(ai.email_associated) IN ($placeholders)
      LIMIT 1
      ''',
      [...variantList, ...variantList, ...variantList, ...variantList],
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
      where: 'provider = ? AND LOWER(provider_uid) = ?',
      whereArgs: [provider.rawValue, providerUid.trim().toLowerCase()],
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

    // Kiểm tra bản ghi hiện có theo id hoặc primary_contact để bảo toàn mật khẩu băm & thông tin y tế
    final existingById = await findById(user.id);
    final existingByContact = existingById ?? await findByIdentifier(user.primaryContact);

    final preservedPasswordHash = user.passwordHash.isNotEmpty
        ? user.passwordHash
        : (existingByContact?.passwordHash ?? '');
    final preservedSalt = user.salt.isNotEmpty
        ? user.salt
        : (existingByContact?.salt ?? '');
    final preservedDob = (user.dateOfBirth != null && user.dateOfBirth!.isNotEmpty)
        ? user.dateOfBirth
        : existingByContact?.dateOfBirth;
    final preservedGender = (user.gender != null &&
            user.gender!.isNotEmpty &&
            user.gender != 'Chưa rõ')
        ? user.gender
        : (existingByContact?.gender ?? user.gender);
    final preservedBloodType = (user.bloodType != null &&
            user.bloodType!.isNotEmpty &&
            user.bloodType != 'Chưa rõ')
        ? user.bloodType
        : (existingByContact?.bloodType ?? user.bloodType);

    String resolvedPatientCode = user.patientCode;
    if (existingByContact != null &&
        !existingByContact.isGuest &&
        existingByContact.patientCode.isNotEmpty &&
        existingByContact.patientCode != 'STYT-GUEST') {
      resolvedPatientCode = existingByContact.patientCode;
    }

    // Đảm bảo không đụng độ patient_code với một user KHÁC
    final codeOwner = await db.query(
      'users',
      where: 'patient_code = ? AND id != ?',
      whereArgs: [resolvedPatientCode, user.id],
      limit: 1,
    );
    if (codeOwner.isNotEmpty) {
      final ownerContact = (codeOwner.first['primary_contact'] as String?)?.toLowerCase();
      if (ownerContact != user.primaryContact.trim().toLowerCase()) {
        resolvedPatientCode = await generateUniquePatientCode();
      }
    }

    final mergedUser = UserAccountModel(
      id: user.id,
      patientCode: resolvedPatientCode,
      fullName: user.fullName,
      primaryContact: user.primaryContact,
      passwordHash: preservedPasswordHash,
      salt: preservedSalt,
      dateOfBirth: preservedDob,
      gender: preservedGender,
      bloodType: preservedBloodType,
      avatarUrl: user.avatarUrl ?? existingByContact?.avatarUrl,
      isGuest: user.isGuest,
      createdAt: existingByContact?.createdAt ?? user.createdAt,
    );

    await db.transaction((txn) async {
      // Nếu tồn tại bản ghi local cũ cùng primary_contact nhưng khác id (VD: nâng cấp lên Cloud UUID)
      if (existingByContact != null && existingByContact.id != user.id) {
        await txn.delete('users', where: 'id = ?', whereArgs: [existingByContact.id]);
      }

      await txn.insert(
        'users',
        mergedUser.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Khôi phục các liên kết định danh cũ (nếu vừa gộp ID)
      if (existingByContact != null && existingByContact.id != user.id) {
        for (final oldIdentity in existingByContact.identities) {
          await txn.insert(
            'auth_identities',
            AuthIdentityModel(
              id: oldIdentity.id,
              userId: mergedUser.id,
              provider: oldIdentity.provider,
              providerUid: oldIdentity.providerUid,
              emailAssociated: oldIdentity.emailAssociated,
              linkedAt: oldIdentity.linkedAt,
            ).toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      if (initialIdentity != null) {
        await txn.insert(
          'auth_identities',
          AuthIdentityModel(
            id: initialIdentity.id,
            userId: mergedUser.id,
            provider: initialIdentity.provider,
            providerUid: initialIdentity.providerUid,
            emailAssociated: initialIdentity.emailAssociated,
            linkedAt: initialIdentity.linkedAt,
          ).toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Đồng bộ hồ sơ user_profile tương ứng
      await txn.insert(
        'user_profile',
        {
          'id': mergedUser.id,
          'full_name': mergedUser.fullName,
          'date_of_birth': mergedUser.dateOfBirth,
          'blood_type': mergedUser.bloodType ?? 'Chưa rõ',
          'allergies': 'Không có',
          'chronic_conditions': 'Không có',
          'emergency_contact': mergedUser.primaryContact,
          'is_pro': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    final identities = await _getIdentitiesForUser(db, mergedUser.id);
    return UserAccountModel(
      id: mergedUser.id,
      patientCode: mergedUser.patientCode,
      fullName: mergedUser.fullName,
      primaryContact: mergedUser.primaryContact,
      passwordHash: mergedUser.passwordHash,
      salt: mergedUser.salt,
      dateOfBirth: mergedUser.dateOfBirth,
      gender: mergedUser.gender,
      bloodType: mergedUser.bloodType,
      avatarUrl: mergedUser.avatarUrl,
      isGuest: mergedUser.isGuest,
      createdAt: mergedUser.createdAt,
      identities: identities,
    );
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
  Future<UserAccountModel?> updateProfileFields({
    required String userId,
    required String fullName,
    String? dateOfBirth,
    String? gender,
    String? bloodType,
    String? emergencyContact,
    String? allergies,
    String? chronicConditions,
    String? height,
    String? weight,
    String? organDonor,
    String? avatarUrl,
    String? region,
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      final updates = <String, dynamic>{
        'full_name': fullName.trim(),
      };
      if (dateOfBirth != null) updates['date_of_birth'] = dateOfBirth;
      if (gender != null) updates['gender'] = gender;
      if (bloodType != null) updates['blood_type'] = bloodType;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      await txn.update(
        'users',
        updates,
        where: 'id = ?',
        whereArgs: [userId],
      );

      final profileUpdates = <String, dynamic>{
        'full_name': fullName.trim(),
      };
      if (dateOfBirth != null) profileUpdates['date_of_birth'] = dateOfBirth;
      if (bloodType != null) profileUpdates['blood_type'] = bloodType;
      if (gender != null) profileUpdates['gender'] = gender;
      if (emergencyContact != null) profileUpdates['emergency_contact'] = emergencyContact;
      if (allergies != null) profileUpdates['allergies'] = allergies;
      if (chronicConditions != null) profileUpdates['chronic_conditions'] = chronicConditions;
      if (height != null) profileUpdates['height'] = height;
      if (weight != null) profileUpdates['weight'] = weight;
      if (organDonor != null) profileUpdates['organ_donor'] = organDonor;
      if (region != null) profileUpdates['region'] = region;

      await txn.update(
        'user_profile',
        profileUpdates,
        where: 'id = ?',
        whereArgs: [userId],
      );
    });

    return await findById(userId);
  }

  @override
  Future<Map<String, dynamic>?> getUserProfileData(String userId) async {
    final db = await _db;
    final res = await db.query(
      'user_profile',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return res.first;
  }

  @override
  Future<void> deleteUserById(String userId) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('auth_identities', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('user_profile', where: 'id = ?', whereArgs: [userId]);
      await txn.delete('users', where: 'id = ?', whereArgs: [userId]);
    });
  }

  @override
  Future<String> generateUniquePatientCode() async {
    final db = await _db;
    final random = Random.secure();

    while (true) {
      final number = 100000 + random.nextInt(900000); // 6 số từ 100000 đến 999999
      final code = 'STYT-$number';

      final exists = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM users WHERE UPPER(patient_code) = ?',
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
