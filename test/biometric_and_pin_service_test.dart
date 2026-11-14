import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_tay_y_te/core/security/biometric_service.dart';
import 'package:so_tay_y_te/core/security/password_hasher.dart';
import 'package:so_tay_y_te/data/datasources/local/app_preferences_datasource.dart';

class MockSuccessBiometricService implements BiometricService {
  @override
  Future<bool> isBiometricAvailable() async => true;

  @override
  Future<List<BiometricHardwareType>> getAvailableBiometrics() async {
    return [BiometricHardwareType.face, BiometricHardwareType.fingerprint];
  }

  @override
  Future<bool> authenticate({required String localizedReason}) async => true;
}

class MockFailingBiometricService implements BiometricService {
  @override
  Future<bool> isBiometricAvailable() async => false;

  @override
  Future<List<BiometricHardwareType>> getAvailableBiometrics() async {
    return [BiometricHardwareType.none];
  }

  @override
  Future<bool> authenticate({required String localizedReason}) async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sub-module 2.1: Biometric & PIN Security Service Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('MockSuccessBiometricService returns available hardware and authenticates', () async {
      final service = MockSuccessBiometricService();

      final isAvailable = await service.isBiometricAvailable();
      expect(isAvailable, isTrue);

      final types = await service.getAvailableBiometrics();
      expect(types.contains(BiometricHardwareType.face), isTrue);

      final authResult = await service.authenticate(
        localizedReason: 'Xác thực Face ID để bảo vệ hồ sơ bệnh án',
      );
      expect(authResult, isTrue);
    });

    test('MockFailingBiometricService handles unavailable hardware gracefully', () async {
      final service = MockFailingBiometricService();

      final isAvailable = await service.isBiometricAvailable();
      expect(isAvailable, isFalse);

      final authResult = await service.authenticate(
        localizedReason: 'Xác thực Face ID',
      );
      expect(authResult, isFalse);
    });

    test('AppPreferencesDataSource stores and verifies PIN hash with SHA-256 + salt', () async {
      final prefsDs = AppPreferencesDataSourceImpl();

      expect(await prefsDs.hasPin(), isFalse);

      const rawPin = '123456';
      final salt = PasswordHasher.generateSalt();
      final hashedPin = PasswordHasher.hashPassword(rawPin, salt);

      await prefsDs.savePin(pinHash: hashedPin, salt: salt);

      expect(await prefsDs.hasPin(), isTrue);
      expect(await prefsDs.getPinHash(), equals(hashedPin));
      expect(await prefsDs.getPinSalt(), equals(salt));

      // Verify that input PIN matches stored hash
      final isMatch = PasswordHasher.verifyPassword(
        password: '123456',
        expectedHash: (await prefsDs.getPinHash())!,
        salt: (await prefsDs.getPinSalt())!,
      );
      expect(isMatch, isTrue);

      // Verify incorrect PIN fails
      final isWrongMatch = PasswordHasher.verifyPassword(
        password: '654321',
        expectedHash: (await prefsDs.getPinHash())!,
        salt: (await prefsDs.getPinSalt())!,
      );
      expect(isWrongMatch, isFalse);

      // Clear PIN
      await prefsDs.clearPin();
      expect(await prefsDs.hasPin(), isFalse);
    });

    test('AppPreferencesDataSource persists Biometric & Auto-lock timeout settings', () async {
      final prefsDs = AppPreferencesDataSourceImpl();

      expect(await prefsDs.isBiometricLockEnabled(), isFalse);
      await prefsDs.setBiometricLockEnabled(true);
      expect(await prefsDs.isBiometricLockEnabled(), isTrue);

      expect(await prefsDs.getAutoLockTimeout(), equals(0)); // 0 = immediate
      await prefsDs.setAutoLockTimeout(1); // 1 minute
      expect(await prefsDs.getAutoLockTimeout(), equals(1));

      expect(await prefsDs.isPrivacyScreenEnabled(), isTrue);
      await prefsDs.setPrivacyScreenEnabled(false);
      expect(await prefsDs.isPrivacyScreenEnabled(), isFalse);
    });
  });
}
