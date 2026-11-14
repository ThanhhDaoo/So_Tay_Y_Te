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
