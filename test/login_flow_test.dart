import 'package:flutter_test/flutter_test.dart';
import 'package:so_tay_y_te/domain/entities/user_account.dart';
import 'package:so_tay_y_te/domain/entities/user_profile.dart';
import 'package:so_tay_y_te/domain/repositories/auth_repository.dart';
import 'package:so_tay_y_te/presentation/features/auth/viewmodel/login_state.dart';
import 'package:so_tay_y_te/presentation/features/auth/viewmodel/login_viewmodel.dart';

class MockLoginAuthRepository implements AuthRepository {
  final Map<String, String> _passwords = {
    'STYT-892410': '123456',
    'bacsitu@sotayyte.vn': '123456',
  };

  UserAccount? activeSession;

  @override
  Future<UserAccount> login({
    required String identifier,
    required String password,
    bool rememberMe = true,
  }) async {
    final expected = _passwords[identifier];
    if (expected == null) {
      throw Exception('Mã hồ sơ hoặc Email/SĐT chưa được đăng ký trong hệ thống.');
    }
    if (expected != password) {
      throw Exception('Mật khẩu không chính xác. Vui lòng kiểm tra lại.');
    }

    final user = UserAccount(
      id: 'usr-demo-01',
      patientCode: 'STYT-892410',
      fullName: 'Bác sĩ Trần Tuấn Tú',
      primaryContact: 'bacsitu@sotayyte.vn',
      passwordHash: 'hash',
      salt: 'salt',
      createdAt: DateTime.now(),
    );

    if (rememberMe) {
      activeSession = user;
    }
    return user;
  }

  @override
  Future<UserAccount?> getActiveSession() async => activeSession;

  @override
  Future<void> resetPassword({
    required String identifier,
    required String newPassword,
  }) async {
    if (!_passwords.containsKey(identifier)) {
      throw Exception('Không tìm thấy tài khoản tương ứng.');
    }
    _passwords[identifier] = newPassword;
  }

  @override
  Future<UserProfile> loginAnonymous() async {
    return const UserProfile(
      id: 'guest-123',
      fullName: 'Bệnh nhân Khách',
      isPro: false,
    );
  }

  @override
  Future<UserProfile?> getCurrentUser() async => null;

  @override
  Future<UserProfile> linkAccount({required String email, required String password}) async => const UserProfile(id: 'l', fullName: 'L');

  @override
  Future<bool> checkProStatus() async => false;

  @override
  Future<void> logout() async {
    activeSession = null;
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
    _passwords[contact] = password;
    return UserAccount(
      id: 'new-id',
      patientCode: 'STYT-999999',
      fullName: fullName,
      primaryContact: contact,
      passwordHash: 'hash',
      salt: 'salt',
      createdAt: DateTime.now(),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sub-module 1.3: Flexible Login & Session Tests', () {
    late LoginViewModel viewModel;
    late MockLoginAuthRepository mockRepo;

    setUp(() {
      mockRepo = MockLoginAuthRepository();
      viewModel = LoginViewModel(authRepository: mockRepo);
    });

    test('Login with valid Patient Code (STYT-892410) succeeds', () async {
      viewModel.identifierController.text = 'STYT-892410';
      viewModel.passwordController.text = '123456';

      final success = await viewModel.signInWithEmailOrId();

      expect(success, isTrue);
      expect(viewModel.state.status, equals(LoginStatus.success));
      expect(viewModel.state.loggedInUser, isNotNull);
      expect(viewModel.state.loggedInUser!.patientCode, equals('STYT-892410'));
    });

    test('Login with valid Email succeeds', () async {
      viewModel.identifierController.text = 'bacsitu@sotayyte.vn';
      viewModel.passwordController.text = '123456';

      final success = await viewModel.signInWithEmailOrId();

      expect(success, isTrue);
      expect(viewModel.state.status, equals(LoginStatus.success));
    });

    test('Login with incorrect password fails with error message', () async {
      viewModel.identifierController.text = 'STYT-892410';
      viewModel.passwordController.text = 'WrongPassword';

      final success = await viewModel.signInWithEmailOrId();

      expect(success, isFalse);
      expect(viewModel.state.status, equals(LoginStatus.error));
      expect(viewModel.state.errorMessage, contains('không chính xác'));
    });

    test('Login with unregistered account fails', () async {
      viewModel.identifierController.text = 'STYT-999000';
      viewModel.passwordController.text = '123456';

      final success = await viewModel.signInWithEmailOrId();

      expect(success, isFalse);
      expect(viewModel.state.status, equals(LoginStatus.error));
      expect(viewModel.state.errorMessage, contains('chưa được đăng ký'));
    });

    test('Guest Mode login creates guest session', () async {
      final success = await viewModel.continueAsGuestOffline();

      expect(success, isTrue);
      expect(viewModel.state.status, equals(LoginStatus.success));
      expect(viewModel.state.loggedInUser!.isGuest, isTrue);
    });

    test('Password reset and subsequent login with new password succeeds', () async {
      // 1. Reset password
      final resetOk = await viewModel.resetPassword(
        identifier: 'STYT-892410',
        newPassword: 'BrandNewPassword2026!',
      );
      expect(resetOk, isTrue);

      // 2. Old password should fail
      viewModel.identifierController.text = 'STYT-892410';
      viewModel.passwordController.text = '123456';
      final oldLoginSuccess = await viewModel.signInWithEmailOrId();
      expect(oldLoginSuccess, isFalse);

      // 3. New password should succeed
      viewModel.passwordController.text = 'BrandNewPassword2026!';
      final newLoginSuccess = await viewModel.signInWithEmailOrId();
      expect(newLoginSuccess, isTrue);
    });

    test('Auto-login check recognizes active session', () async {
      expect(await viewModel.checkAutoLogin(), isFalse);

      // Log in with rememberMe = true
      viewModel.identifierController.text = 'STYT-892410';
      viewModel.passwordController.text = '123456';
      await viewModel.signInWithEmailOrId();

      // Check auto-login now
      final autoLoginOk = await viewModel.checkAutoLogin();
      expect(autoLoginOk, isTrue);
    });
  });
}

