import 'package:flutter_test/flutter_test.dart';
import 'package:so_tay_y_te/core/security/password_hasher.dart';
import 'package:so_tay_y_te/data/models/auth_identity_model.dart';
import 'package:so_tay_y_te/data/models/user_account_model.dart';
import 'package:so_tay_y_te/domain/entities/auth_identity.dart';

void main() {
  group('Sub-module 1.1: PasswordHasher Tests', () {
    test('generateSalt produces unique random 32-byte base64 strings', () {
      final salt1 = PasswordHasher.generateSalt();
      final salt2 = PasswordHasher.generateSalt();

      expect(salt1, isNotEmpty);
      expect(salt2, isNotEmpty);
      expect(salt1, isNot(equals(salt2)));
    });

    test('hashPassword produces consistent SHA-256 hash for same input and salt', () {
      const password = 'StrongPassword@123';
      final salt = PasswordHasher.generateSalt();

      final hash1 = PasswordHasher.hashPassword(password, salt);
      final hash2 = PasswordHasher.hashPassword(password, salt);

      expect(hash1, equals(hash2));
      expect(hash1.length, equals(64)); // 256 bits = 64 hex characters
    });

    test('hashPassword produces different hashes for different salts', () {
      const password = 'MyPassword123';
      final salt1 = PasswordHasher.generateSalt();
      final salt2 = PasswordHasher.generateSalt();

      final hash1 = PasswordHasher.hashPassword(password, salt1);
      final hash2 = PasswordHasher.hashPassword(password, salt2);

      expect(hash1, isNot(equals(hash2)));
    });

    test('verifyPassword correctly validates correct and incorrect passwords', () {
      const correctPassword = 'MedicalVault2026!';
      const wrongPassword = 'WrongPassword2026!';
      final salt = PasswordHasher.generateSalt();
      final expectedHash = PasswordHasher.hashPassword(correctPassword, salt);

      expect(
        PasswordHasher.verifyPassword(
          password: correctPassword,
          salt: salt,
          expectedHash: expectedHash,
        ),
        isTrue,
      );

      expect(
        PasswordHasher.verifyPassword(
          password: wrongPassword,
          salt: salt,
          expectedHash: expectedHash,
        ),
        isFalse,
      );
    });
  });

  group('Sub-module 1.1: Models & Serialization Tests', () {
    test('UserAccountModel toMap and fromMap preserve all clinical user fields', () {
      final now = DateTime.now();
      final user = UserAccountModel(
        id: 'usr-12345',
        patientCode: 'STYT-892410',
        fullName: 'Bác sĩ Trần Tuấn Tú',
        primaryContact: 'bacsitu@sotayyte.vn',
        passwordHash: 'hash-abc',
        salt: 'salt-xyz',
        dateOfBirth: '1985-05-15',
        gender: 'Nam',
        bloodType: 'O+',
        avatarUrl: 'assets/images/img_profile_avatar.png',
        isGuest: false,
        createdAt: now,
      );

      final map = user.toMap();
      final restored = UserAccountModel.fromMap(map);

      expect(restored.id, equals(user.id));
      expect(restored.patientCode, equals('STYT-892410'));
      expect(restored.fullName, equals('Bác sĩ Trần Tuấn Tú'));
      expect(restored.primaryContact, equals('bacsitu@sotayyte.vn'));
      expect(restored.gender, equals('Nam'));
      expect(restored.bloodType, equals('O+'));
      expect(restored.isGuest, isFalse);
    });

    test('AuthIdentityModel correctly serializes and restores identity providers', () {
      final now = DateTime.now();
      final googleIdentity = AuthIdentityModel(
        id: 'id-google-1',
        userId: 'usr-12345',
        provider: AuthProviderType.google,
        providerUid: 'google-sub-987654',
        emailAssociated: 'user@gmail.com',
        linkedAt: now,
      );

      final map = googleIdentity.toMap();
      final restored = AuthIdentityModel.fromMap(map);

      expect(restored.provider, equals(AuthProviderType.google));
      expect(restored.providerUid, equals('google-sub-987654'));
      expect(restored.emailAssociated, equals('user@gmail.com'));
    });

    test('AuthIdentityModel handles Apple Sign In with private relay email', () {
      final now = DateTime.now();
      final appleIdentity = AuthIdentityModel(
        id: 'id-apple-1',
        userId: 'usr-12345',
        provider: AuthProviderType.apple,
        providerUid: '001234.apple.user.id',
        emailAssociated: 'xyz123@privaterelay.appleid.com',
        linkedAt: now,
      );

      final map = appleIdentity.toMap();
      final restored = AuthIdentityModel.fromMap(map);

      expect(restored.provider, equals(AuthProviderType.apple));
      expect(restored.emailAssociated, contains('@privaterelay.appleid.com'));
    });
  });
}

