import 'package:flutter_test/flutter_test.dart';
import 'package:so_tay_y_te/domain/entities/auth_identity.dart';
import 'package:so_tay_y_te/domain/entities/user_account.dart';
import 'package:so_tay_y_te/domain/entities/user_profile.dart';
import 'package:so_tay_y_te/domain/repositories/auth_repository.dart';
import 'package:so_tay_y_te/presentation/features/auth/viewmodel/login_state.dart';
import 'package:so_tay_y_te/presentation/features/auth/viewmodel/login_viewmodel.dart';
import 'package:so_tay_y_te/presentation/features/auth/viewmodel/register_state.dart';
import 'package:so_tay_y_te/presentation/features/auth/viewmodel/register_viewmodel.dart';

class MockSocialAuthRepository implements AuthRepository {
  final Map<String, UserAccount> _accounts = {};
  UserAccount? _activeSession;

  @override
  Future<UserAccount> login({
    required String identifier,
    required String password,
    bool rememberMe = true,
  }) async {
    final user = _accounts[identifier];
    if (user == null) {
      throw Exception('Tài khoản không tồn tại.');
    }
    if (rememberMe) _activeSession = user;
    return user;
  }

  @override
  Future<UserAccount> register({
    required String fullName,
    required String contact,
    required String password,
    String? dateOfBirth,
    String? gender,
    String? bloodType,
    bool enableBiometric = false,
  }) async {
    if (_accounts.containsKey(contact)) {
      throw Exception('Tài khoản đã tồn tại.');
    }

    final user = UserAccount(
      id: 'soc-usr-${_accounts.length + 1}',
      patientCode: 'STYT-${700000 + _accounts.length}',
      fullName: fullName,
      primaryContact: contact,
      passwordHash: 'hash',
      salt: 'salt',
      dateOfBirth: dateOfBirth,
      gender: gender,
      bloodType: bloodType,
      createdAt: DateTime.now(),
      identities: [
        AuthIdentity(
          id: 'ident-${_accounts.length + 1}',
          userId: 'soc-usr-${_accounts.length + 1}',
          provider: contact.contains('apple') ? AuthProviderType.apple : AuthProviderType.google,
          providerUid: 'sub-${contact.hashCode}',
          emailAssociated: contact,
          linkedAt: DateTime.now(),
        ),
      ],
    );

    _accounts[contact] = user;
    _activeSession = user;
    return user;
  }

  @override
  Future<UserAccount?> getActiveSession() async => _activeSession;

  @override
  Future<bool> checkAccountExists(String identifier) async =>
      _accounts.containsKey(identifier);

  @override
  Future<UserAccount?> getBiometricBoundAccount() async => null;

  @override
  Future<String?> getLastLoginIdentifier() async => null;

  @override
  Future<bool> isDeviceAppLockEnabled() async => false;

  @override
  Future<UserProfile?> getCurrentUser() async => null;

  @override
  Future<UserProfile> loginAnonymous() async => const UserProfile(id: 'g', fullName: 'G');

  @override
  Future<UserProfile> linkAccount({required String email, required String password}) async => const UserProfile(id: 'l', fullName: 'L');

  @override
  Future<bool> checkProStatus() async => false;

  @override
  Future<void> logout() async {
    _activeSession = null;
  }

  @override
  Future<void> resetPassword({required String identifier, required String newPassword}) async {}

  @override
  Future<PasswordRecoveryChallenge> sendPasswordRecoveryChallenge(
    String identifier,
  ) async {
    return PasswordRecoveryChallenge(
      verificationId: 'rec-soc',
      maskedContact: identifier,
      targetContact: identifier,
      sandboxOtpPreview: '123456',
    );
  }

  @override
  Future<void> verifyRecoveryAndResetPassword({
    required String identifier,
    required String verificationId,
    required String otpCode,
    required String newPassword,
  }) async {}

  @override
  Future<void> verifyPhoneOtpOnly({
    required String phoneNumber,
    required String verificationId,
    required String smsCode,
  }) async {}

  @override
  Future<UserAccount> verifyEmailSignupOtp({
    required String email,
    required String otpCode,
    required String password,
    required String fullName,
    String? dateOfBirth,
    String? gender,
    String? bloodType,
    bool enableBiometric = false,
  }) async {
    return register(
      fullName: fullName,
      contact: email,
      password: password,
    );
  }

  @override
  Future<UserAccount> completePhoneProfileSetup({
    required String userId,
    required String fullName,
    String? bloodType,
    String? gender,
    String? dateOfBirth,
  }) async {
    final user = UserAccount(
      id: userId,
      patientCode: 'STYT-892410',
      fullName: fullName,
      primaryContact: '0912345678',
      passwordHash: '',
      salt: '',
      bloodType: bloodType,
      gender: gender,
      dateOfBirth: dateOfBirth,
      createdAt: DateTime.now(),
    );
    _activeSession = user;
    return user;
  }

  @override
  String? peekSandboxOtp(String verificationId) => '123456';

  @override
  Future<String> sendPhoneOtp(String phoneNumber) async => 'mock-ver-123';

  @override
  Future<UserAccount> verifyPhoneOtp({
    required String phoneNumber,
    required String verificationId,
    required String smsCode,
  }) async {
    final user = UserAccount(
      id: 'phone-user-1',
      patientCode: 'STYT-892410',
      fullName: 'Bệnh nhân ($phoneNumber)',
      primaryContact: phoneNumber,
      passwordHash: '',
      salt: '',
      createdAt: DateTime.now(),
    );
    _activeSession = user;
    return user;
  }

  @override
  Future<UserAccount> signInWithSocialProvider({
    required String provider,
    String? idToken,
    String? accessToken,
  }) async {
    final isApple = provider.toLowerCase() == 'apple';
    final user = UserAccount(
      id: isApple ? 'soc-apple' : 'soc-google',
      patientCode: 'STYT-892410',
      fullName: isApple ? 'Bệnh nhân Apple' : 'Bệnh nhân Google',
      primaryContact: isApple ? 'apple_user@icloud.com' : 'google_user@gmail.com',
      passwordHash: '',
      salt: '',
      createdAt: DateTime.now(),
    );
    _activeSession = user;
    return user;
  }

  @override
  Future<UserAccount> syncSupabaseUserSession({
    required String userId,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? provider,
  }) async {
    final user = UserAccount(
      id: userId,
      patientCode: 'STYT-892410',
      fullName: fullName ?? 'Bệnh nhân Test',
      primaryContact: email ?? 'test@example.com',
      passwordHash: '',
      salt: '',
      createdAt: DateTime.now(),
    );
    _activeSession = user;
    return user;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sub-module 1.4: Social Auth (Apple & Google) Linking Tests', () {
    late MockSocialAuthRepository mockRepo;
    late LoginViewModel loginVm;
    late RegisterViewModel registerVm;

    setUp(() {
      mockRepo = MockSocialAuthRepository();
      loginVm = LoginViewModel(authRepository: mockRepo);
      registerVm = RegisterViewModel(authRepository: mockRepo);
    });

    test('Apple Sign-In on LoginScreen creates session and assigns STYT patient ID', () async {
      final success = await loginVm.signInWithSocial('apple');

      expect(success, isTrue);
      expect(loginVm.state.status, equals(LoginStatus.success));
      expect(loginVm.state.loggedInUser, isNotNull);
      expect(loginVm.state.loggedInUser!.fullName, equals('Bệnh nhân Apple'));
      expect(loginVm.state.loggedInUser!.patientCode, startsWith('STYT-'));
    });

    test('Google Sign-In on LoginScreen creates session and assigns STYT patient ID', () async {
      final success = await loginVm.signInWithSocial('google');

      expect(success, isTrue);
      expect(loginVm.state.status, equals(LoginStatus.success));
      expect(loginVm.state.loggedInUser, isNotNull);
      expect(loginVm.state.loggedInUser!.fullName, equals('Bệnh nhân Google'));
      expect(loginVm.state.loggedInUser!.patientCode, startsWith('STYT-'));
    });

    test('Apple Sign-In on RegisterScreen creates new patient account with STYT code', () async {
      final success = await registerVm.registerWithSocial('apple');

      expect(success, isTrue);
      expect(registerVm.state.status, equals(RegisterStatus.success));
      expect(registerVm.state.createdAccount, isNotNull);
      expect(registerVm.state.createdAccount!.patientCode, startsWith('STYT-'));
    });

    test('Google Sign-In on RegisterScreen creates new patient account with STYT code', () async {
      final success = await registerVm.registerWithSocial('google');

      expect(success, isTrue);
      expect(registerVm.state.status, equals(RegisterStatus.success));
      expect(registerVm.state.createdAccount, isNotNull);
      expect(registerVm.state.createdAccount!.patientCode, startsWith('STYT-'));
    });
  });
}

