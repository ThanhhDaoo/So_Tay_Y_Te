import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../domain/entities/user_account.dart';
import '../../../../domain/entities/user_profile.dart';
import '../../../../domain/repositories/auth_repository.dart';
import 'login_state.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  final TextEditingController identifierController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  LoginState _state = const LoginState();
  LoginState get state => _state;

  UserAccount? get loggedInAccount => _state.loggedInUser;

  LoginViewModel({AuthRepository? authRepository})
      : _authRepository = authRepository ?? (sl.isRegistered<AuthRepository>() ? sl<AuthRepository>() : _createFallbackRepo()),
        identifierController = TextEditingController(text: 'STYT-892410'),
        passwordController = TextEditingController(text: '123456');

  static AuthRepository _createFallbackRepo() {
    return _FallbackInMemoryAuthRepository();
  }

  void togglePasswordVisibility() {
    _state = _state.copyWith(obscurePassword: !_state.obscurePassword);
    notifyListeners();
  }

  void toggleRememberMe(bool? value) {
    _state = _state.copyWith(rememberMe: value ?? true);
    notifyListeners();
  }

  Future<bool> checkAutoLogin() async {
    try {
      final activeUser = await _authRepository.getActiveSession();
      if (activeUser != null) {
        _state = _state.copyWith(
          status: LoginStatus.success,
          loggedInUser: activeUser,
          errorMessage: null,
        );
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> signInWithEmailOrId() async {
    final form = formKey.currentState;
    if (form != null && !form.validate()) {
      return false;
    }

    if (identifierController.text.trim().isEmpty || passwordController.text.isEmpty) {
      _state = _state.copyWith(
        status: LoginStatus.error,
        errorMessage: 'Vui lòng nhập đầy đủ Mã hồ sơ/Email và mật khẩu.',
      );
      notifyListeners();
      return false;
    }

    _state = _state.copyWith(status: LoginStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      final user = await _authRepository.login(
        identifier: identifierController.text.trim(),
        password: passwordController.text,
        rememberMe: _state.rememberMe,
      );

      _state = _state.copyWith(
        status: LoginStatus.success,
        loggedInUser: user,
        errorMessage: null,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _state = _state.copyWith(
        status: LoginStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithSocial(String provider) async {
    _state = _state.copyWith(status: LoginStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      final isApple = provider.toLowerCase() == 'apple';
      final defaultContact = isApple ? 'apple_user@icloud.com' : 'google_user@gmail.com';
      final defaultName = isApple ? 'Bệnh nhân Apple' : 'Bệnh nhân Google';

      UserAccount user;
      try {
        user = await _authRepository.login(
          identifier: defaultContact,
          password: 'SocialOAuthSecureToken2026!',
          rememberMe: _state.rememberMe,
        );
      } catch (_) {
        user = await _authRepository.register(
          fullName: defaultName,
          contact: defaultContact,
          password: 'SocialOAuthSecureToken2026!',
        );
      }

      _state = _state.copyWith(
        status: LoginStatus.success,
        loggedInUser: user,
        errorMessage: null,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _state = _state.copyWith(
        status: LoginStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> continueAsGuestOffline() async {
    _state = _state.copyWith(status: LoginStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      final profile = await _authRepository.loginAnonymous();
      final guestAccount = UserAccount(
        id: profile.id,
        patientCode: 'STYT-GUEST',
        fullName: profile.fullName,
        primaryContact: 'guest@sotayyte.local',
        passwordHash: '',
        salt: '',
        isGuest: true,
        createdAt: DateTime.now(),
      );

      _state = _state.copyWith(
        status: LoginStatus.success,
        loggedInUser: guestAccount,
        errorMessage: null,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _state = _state.copyWith(
        status: LoginStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword({
    required String identifier,
    required String newPassword,
  }) async {
    if (identifier.trim().isEmpty || newPassword.length < 6) {
      _state = _state.copyWith(
        status: LoginStatus.error,
        errorMessage: 'Vui lòng nhập định danh và mật khẩu mới tối thiểu 6 ký tự.',
      );
      notifyListeners();
      return false;
    }

    _state = _state.copyWith(status: LoginStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      await _authRepository.resetPassword(
        identifier: identifier.trim(),
        newPassword: newPassword,
      );

      _state = _state.copyWith(
        status: LoginStatus.initial,
        errorMessage: null,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _state = _state.copyWith(
        status: LoginStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

class _FallbackInMemoryAuthRepository implements AuthRepository {
  @override
  Future<UserAccount> login({
    required String identifier,
    required String password,
    bool rememberMe = true,
  }) async {
    return UserAccount(
      id: 'demo-user',
      patientCode: 'STYT-892410',
      fullName: 'Bác sĩ Trần Tuấn Tú',
      primaryContact: 'bacsitu@sotayyte.vn',
      passwordHash: '',
      salt: '',
      createdAt: DateTime.now(),
    );
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
    return UserAccount(
      id: 'reg-user',
      patientCode: 'STYT-999999',
      fullName: fullName,
      primaryContact: contact,
      passwordHash: '',
      salt: '',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<UserAccount?> getActiveSession() async => null;

  @override
  Future<UserProfile?> getCurrentUser() async => null;

  @override
  Future<UserProfile> loginAnonymous() async => const UserProfile(id: 'guest', fullName: 'Guest');

  @override
  Future<UserProfile> linkAccount({required String email, required String password}) async => const UserProfile(id: 'link', fullName: 'Link');

  @override
  Future<bool> checkProStatus() async => false;

  @override
  Future<void> logout() async {}

  @override
  Future<void> resetPassword({required String identifier, required String newPassword}) async {}
}
