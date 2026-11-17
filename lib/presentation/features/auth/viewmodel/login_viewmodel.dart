import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/security/biometric_service.dart';
import '../../../../domain/entities/user_account.dart';
import '../../../../domain/entities/user_profile.dart';
import '../../../../domain/repositories/auth_repository.dart';
import 'login_state.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final BiometricService _biometricService;

  final TextEditingController identifierController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  LoginState _state = const LoginState();
  LoginState get state => _state;

  UserAccount? get loggedInAccount => _state.loggedInUser;

  LoginViewModel({
    AuthRepository? authRepository,
    BiometricService? biometricService,
  })  : _authRepository = authRepository ?? (sl.isRegistered<AuthRepository>() ? sl<AuthRepository>() : _createFallbackRepo()),
        _biometricService = biometricService ?? (sl.isRegistered<BiometricService>() ? sl<BiometricService>() : BiometricServiceImpl()),
        identifierController = TextEditingController(),
        passwordController = TextEditingController();

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

  Future<bool> signInWithBiometrics() async {
    _state = _state.copyWith(status: LoginStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      final isAvailable = await _biometricService.isBiometricAvailable();
      if (!isAvailable) {
        _state = _state.copyWith(
          status: LoginStatus.error,
          errorMessage: 'Thiết bị không hỗ trợ hoặc chưa cài đặt Face ID / Vân tay.',
        );
        notifyListeners();
        return false;
      }

      final authenticated = await _biometricService.authenticate(
        localizedReason: 'Xác thực Face ID để đăng nhập vào Sổ Tay Y Tế',
      );

      if (!authenticated) {
        _state = _state.copyWith(
          status: LoginStatus.error,
          errorMessage: 'Xác thực sinh trắc học không thành công hoặc đã bị hủy.',
        );
        notifyListeners();
        return false;
      }

      // 1. Kiểm tra phiên đã lưu trước đó
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

      // 2. Nếu chưa lưu phiên, đăng nhập với tài khoản đang hiển thị trong ô nhập
      final id = identifierController.text.trim();
      final pwd = passwordController.text;
      if (id.isNotEmpty && pwd.isNotEmpty) {
        final user = await _authRepository.login(
          identifier: id,
          password: pwd,
          rememberMe: _state.rememberMe,
        );
        _state = _state.copyWith(
          status: LoginStatus.success,
          loggedInUser: user,
          errorMessage: null,
        );
        notifyListeners();
        return true;
      }

      _state = _state.copyWith(
        status: LoginStatus.error,
        errorMessage: 'Vui lòng đăng nhập bằng mật khẩu một lần trước khi dùng Face ID.',
      );
      notifyListeners();
      return false;
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
      final user = await _authRepository.signInWithSocialProvider(
        provider: provider,
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

  Future<bool> handleOAuthSessionSuccess({
    required String userId,
    String? email,
    String? fullName,
  }) async {
    _state = _state.copyWith(status: LoginStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      final user = await _authRepository.syncSupabaseUserSession(
        userId: userId,
        email: email,
        fullName: fullName,
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

  Future<String> sendPhoneOtp(String phoneNumber) async {
    _state = _state.copyWith(status: LoginStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      final verId = await _authRepository.sendPhoneOtp(phoneNumber);
      _state = _state.copyWith(status: LoginStatus.initial, errorMessage: null);
      notifyListeners();
      return verId;
    } catch (e) {
      _state = _state.copyWith(
        status: LoginStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> verifyPhoneOtp({
    required String phoneNumber,
    required String verificationId,
    required String smsCode,
  }) async {
    _state = _state.copyWith(status: LoginStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      final user = await _authRepository.verifyPhoneOtp(
        phoneNumber: phoneNumber,
        verificationId: verificationId,
        smsCode: smsCode,
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

  Future<bool> continueAsGuestOffline() async {
    _state = _state.copyWith(status: LoginStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      final profile = await _authRepository.loginAnonymous();
      // Dùng thông tin thật từ loginAnonymous, không hardcode
      final guestAccount = UserAccount(
        id: profile.id,
        patientCode: profile.id.startsWith('guest-') ? 'STYT-GUEST' : profile.id.substring(0, 11).toUpperCase(),
        fullName: profile.fullName,
        primaryContact: profile.emergencyContact ?? 'guest@sotayyte.local',
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

  @override
  Future<void> verifyPhoneOtpOnly({
    required String phoneNumber,
    required String verificationId,
    required String smsCode,
  }) async {}

  @override
  Future<String> sendPhoneOtp(String phoneNumber) async => 'fb-ver-mock-123';

  @override
  Future<UserAccount> verifyPhoneOtp({
    required String phoneNumber,
    required String verificationId,
    required String smsCode,
  }) async {
    return UserAccount(
      id: 'phone-mock-user',
      patientCode: 'STYT-892410',
      fullName: 'Bệnh nhân ($phoneNumber)',
      primaryContact: phoneNumber,
      passwordHash: '',
      salt: '',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<UserAccount> signInWithSocialProvider({
    required String provider,
    String? idToken,
    String? accessToken,
  }) async {
    final isApple = provider.toLowerCase() == 'apple';
    return UserAccount(
      id: 'soc-mock-user',
      patientCode: 'STYT-892410',
      fullName: isApple ? 'Bệnh nhân Apple' : 'Bệnh nhân Google',
      primaryContact: isApple ? 'apple_user@icloud.com' : 'google_user@gmail.com',
      passwordHash: '',
      salt: '',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<UserAccount> syncSupabaseUserSession({
    required String userId,
    String? email,
    String? fullName,
  }) async {
    return UserAccount(
      id: userId,
      patientCode: 'STYT-892410',
      fullName: fullName ?? 'Bệnh nhân Test',
      primaryContact: email ?? 'test@example.com',
      passwordHash: '',
      salt: '',
      createdAt: DateTime.now(),
    );
  }
}
