import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_tay_y_te/core/database/database_helper.dart';
import 'package:so_tay_y_te/core/di/injection_container.dart';
import 'package:so_tay_y_te/core/security/biometric_service.dart';
import 'package:so_tay_y_te/core/security/secure_storage_helper.dart';
import 'package:so_tay_y_te/data/datasources/local/app_preferences_datasource.dart';
import 'package:so_tay_y_te/data/datasources/local/auth_local_datasource.dart';
import 'package:so_tay_y_te/data/datasources/remote/auth_remote_datasource.dart';
import 'package:so_tay_y_te/data/datasources/remote/firebase_auth_datasource.dart';
import 'package:so_tay_y_te/data/repositories/auth_repository_impl.dart';
import 'package:so_tay_y_te/presentation/features/security_settings/view/app_lock_screen.dart';
import 'package:so_tay_y_te/presentation/features/security_settings/viewmodel/security_settings_viewmodel.dart';

class _StubBiometricService implements BiometricService {
  @override
  Future<bool> isBiometricAvailable() async => false;

  @override
  Future<List<BiometricHardwareType>> getAvailableBiometrics() async =>
      [BiometricHardwareType.none];

  @override
  Future<bool> authenticate({required String localizedReason}) async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppPreferencesDataSource prefsDataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();

    final secureStorage = SecureStorageHelperImpl();
    prefsDataSource = AppPreferencesDataSourceImpl(
      secureStorage: secureStorage,
    );
    sl.registerLazySingleton<AppPreferencesDataSource>(() => prefsDataSource);
    sl.registerLazySingleton<BiometricService>(() => _StubBiometricService());
  });

  tearDown(() async {
    await sl.reset();
  });

  group('Production Auth Hardening & AppLock Rate-Limiting Tests', () {
    test('Production mode (allowSandboxOverride: false) blocks hardcoded test phone numbers and hardcoded 123456 OTP bypass', () async {
      final prodFirebaseAuth = FirebaseAuthRemoteDataSourceImpl(
        allowSandboxOverride: false,
      );

      expect(
        prodFirebaseAuth.isFirebaseConsoleTestPhone('0362625218'),
        isFalse,
      );
      expect(
        () => prodFirebaseAuth.sendPhoneOtp('0362625218'),
        throwsException,
      );

      final dbHelper = AppDatabaseHelper();
      final authRepo = AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSourceImpl(),
        localDataSource: prefsDataSource,
        authLocalDataSource: AuthLocalDataSourceImpl(databaseHelper: dbHelper),
        allowSandboxOverride: false,
      );

      expect(
        () => authRepo.verifyPhoneOtpOnly(
          phoneNumber: '0362625218',
          verificationId: 'manual-ver-id',
          smsCode: '123456',
        ),
        throwsException,
      );
    });

    test('AppLock PIN brute-force rate-limiting locks out after 5 consecutive wrong attempts', () async {
      final vm = SecuritySettingsViewModel(
        preferencesDataSource: prefsDataSource,
        biometricService: _StubBiometricService(),
      );

      await vm.saveNewPin('246810');
      expect(await vm.hasConfiguredPin(), isTrue);

      for (int i = 0; i < 5; i++) {
        final ok = await vm.verifyPin('000000');
        expect(ok, isFalse);
      }

      final remainingLockSeconds = await vm.getPinLockoutRemainingSeconds();
      expect(remainingLockSeconds, greaterThan(0));

      // Ngay cả khi nhập đúng mã PIN trong thời gian bị khóa tạm thời vẫn phải từ chối
      final blockedEvenWhenCorrect = await vm.verifyPin('246810');
      expect(blockedEvenWhenCorrect, isFalse);
      vm.dispose();
    });

    testWidgets('AppLockScreen renders non-deadlocking password/logout fallback button when no PIN is configured', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: AppLockScreen(
            onUnlocked: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Mở khóa bằng mật khẩu tài khoản / Đăng xuất'),
        findsOneWidget,
      );
    });
  });
}
