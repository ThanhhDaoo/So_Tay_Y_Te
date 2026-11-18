import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/security/biometric_service.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../data/datasources/local/app_preferences_datasource.dart';
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

  bool _isAwaitingOAuth = false;
  bool get isAwaitingOAuth => _isAwaitingOAuth;
  String? _pendingOAuthProvider;

  UserAccount? get loggedInAccount => _state.loggedInUser;

  LoginViewModel({
    AuthRepository? authRepository,
    BiometricService? biometricService,
  })  : _authRepository = authRepository ??
            (sl.isRegistered<AuthRepository>()
                ? sl<AuthRepository>()
                : _createFallbackRepo()),
        _biometricService = biometricService ??
            (sl.isRegistered<BiometricService>()
                ? sl<BiometricService>()
                : BiometricServiceImpl()),
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

  void cancelPendingOAuth() {
    if (!_isAwaitingOAuth && _state.status != LoginStatus.awaitingOAuth) return;
    _isAwaitingOAuth = false;
    _pendingOAuthProvider = null;
    _state = _state.copyWith(
      status: LoginStatus.initial,
      errorMessage: null,
    );
    notifyListeners();
  }

  void handleOAuthError(Object error) {
    _isAwaitingOAuth = false;
    _pendingOAuthProvider = null;
    final raw = error.toString();
    final friendly = raw.contains('Unable to exchange external code')
        ? 'Máy chủ Supabase không đổi được mã xác thực Google (Client Secret trên Supabase chưa khớp với Google Cloud Console).'
        : raw.replaceFirst('Exception: ', '');
    _state = _state.copyWith(
      status: LoginStatus.error,
      errorMessage: friendly,
    );
    notifyListeners();
  }

  Future<void> loadLastLoginIdentifierIfNeeded() async {
    if (identifierController.text.trim().isNotEmpty) return;
    try {
      final lastId = await _authRepository.getLastLoginIdentifier();
      if (lastId != null &&
          lastId.trim().isNotEmpty &&
          identifierController.text.isEmpty) {
        identifierController.text = lastId.trim();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> checkAutoLogin() async {
    try {
      final activeUser = await _authRepository.getActiveSession();
      if (activeUser != null) {
        final needsLock = await _authRepository.isDeviceAppLockEnabled();
        _state = _state.copyWith(
          status: LoginStatus.success,
          loggedInUser: activeUser,
          requiresAppLockUnlock: needsLock,
          errorMessage: null,
        );
        notifyListeners();
        return true;
      }
      await loadLastLoginIdentifierIfNeeded();
    } catch (_) {}
    return false;
  }

  Future<bool> signInWithEmailOrId() async {
    final form = formKey.currentState;
    if (form != null && !form.validate()) {
      return false;
    }

    final idText = identifierController.text.trim();
    final pwdText = passwordController.text;

    if (idText.isEmpty || pwdText.isEmpty) {
      _state = _state.copyWith(
        status: LoginStatus.error,
        errorMessage: 'Vui lòng nhập đầy đủ SĐT/Email/Mã hồ sơ và mật khẩu.',
      );
      notifyListeners();
      return false;
    }

    final idErr = InputValidators.validateLoginIdentifier(idText);
    if (idErr != null) {
      _state = _state.copyWith(
        status: LoginStatus.error,
        errorMessage: idErr,
      );
      notifyListeners();
      return false;
    }

    _state = _state.copyWith(status: LoginStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      final user = await _authRepository.login(
        identifier: idText,
        password: pwdText,
        rememberMe: _state.rememberMe,
      );

      _state = _state.copyWith(
        status: LoginStatus.success,
        loggedInUser: user,
        requiresAppLockUnlock: false,
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
          errorMessage:
              'Thiết bị không hỗ trợ hoặc chưa cài đặt Face ID / Vân tay.',
        );
        notifyListeners();
        return false;
      }

      // Kiểm tra trước xem trên thiết bị đã có tài khoản liên kết hoặc đang điền sẵn thông tin chưa
      final activeUser = await _authRepository.getActiveSession();
      final boundUser = activeUser ?? await _authRepository.getBiometricBoundAccount();
      final id = identifierController.text.trim();
      final pwd = passwordController.text;

      if (boundUser == null && (id.isEmpty || pwd.isEmpty)) {
        _state = _state.copyWith(
          status: LoginStatus.error,
          errorMessage:
              'Vui lòng đăng nhập bằng mật khẩu hoặc OTP lần đầu trên thiết bị này để kích hoạt đăng nhập nhanh Face ID.',
        );
        notifyListeners();
        return false;
      }

      final authenticated = await _biometricService.authenticate(
        localizedReason: 'Xác thực sinh trắc học để mở Sổ Tay Y Tế',
      );

      if (!authenticated) {
        _state = _state.copyWith(
          status: LoginStatus.error,
          errorMessage:
              'Xác thực sinh trắc học không thành công hoặc đã bị hủy.',
        );
        notifyListeners();
        return false;
      }

      // 1. Khôi phục phiên từ tài khoản đã liên kết sinh trắc học trên máy (kể cả sau khi Đăng xuất)
      if (boundUser != null) {
        if (sl.isRegistered<AppPreferencesDataSource>()) {
          await sl<AppPreferencesDataSource>().saveSession(
            userId: boundUser.id,
            patientCode: boundUser.patientCode,
            contact: boundUser.primaryContact,
            rememberMe: _state.rememberMe,
          );
        }
        _state = _state.copyWith(
          status: LoginStatus.success,
          loggedInUser: boundUser,
          requiresAppLockUnlock: false,
          errorMessage: null,
        );
        notifyListeners();
        return true;
      }

      // 2. Hoặc xác thực với tài khoản đang nhập trong ô để liên kết Face ID lần đầu
      if (id.isNotEmpty && pwd.isNotEmpty) {
        final user = await _authRepository.login(
          identifier: id,
          password: pwd,
          rememberMe: _state.rememberMe,
        );
        _state = _state.copyWith(
          status: LoginStatus.success,
          loggedInUser: user,
          requiresAppLockUnlock: false,
          errorMessage: null,
        );
        notifyListeners();
        return true;
      }

      _state = _state.copyWith(
        status: LoginStatus.error,
        errorMessage:
            'Vui lòng đăng nhập bằng mật khẩu một lần trước khi dùng Face ID.',
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
    _isAwaitingOAuth = true;
    _pendingOAuthProvider = provider;
    _state = _state.copyWith(status: LoginStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      final user = await _authRepository.signInWithSocialProvider(
        provider: provider,
      );

      if (user.id == 'oauth_in_progress') {
        _state = _state.copyWith(
          status: LoginStatus.awaitingOAuth,
          errorMessage: null,
        );
        notifyListeners();
        return true;
      }

      _isAwaitingOAuth = false;
      _pendingOAuthProvider = null;
      _state = _state.copyWith(
        status: LoginStatus.success,
        loggedInUser: user,
        requiresAppLockUnlock: false,
        errorMessage: null,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _isAwaitingOAuth = false;
      _pendingOAuthProvider = null;
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
    String? avatarUrl,
  }) async {
    final provider = _pendingOAuthProvider;
    _isAwaitingOAuth = false;
    _pendingOAuthProvider = null;
    _state = _state.copyWith(status: LoginStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      final user = await _authRepository.syncSupabaseUserSession(
        userId: userId,
        email: email,
        fullName: fullName,
        avatarUrl: avatarUrl,
        provider: provider,
      );

      _state = _state.copyWith(
        status: LoginStatus.success,
        loggedInUser: user,
        requiresAppLockUnlock: false,
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

  Future<bool> checkPhoneAccountExists(String phoneNumber) async {
    try {
      return await _authRepository.checkAccountExists(phoneNumber);
    } catch (_) {
      return false;
    }
  }

  String? peekSandboxOtp(String verificationId) {
    return _authRepository.peekSandboxOtp(verificationId);
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
        requiresAppLockUnlock: false,
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

  Future<bool> completeNewPhoneUserProfile({
    required String fullName,
    String? bloodType,
    String? gender,
  }) async {
    final current = _state.loggedInUser;
    if (current == null) return false;

    try {
      final updated = await _authRepository.completePhoneProfileSetup(
        userId: current.id,
        fullName: fullName,
        bloodType: bloodType,
        gender: gender,
      );
      _state = _state.copyWith(
        status: LoginStatus.success,
        loggedInUser: updated,
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
        primaryContact: profile.emergencyContact ?? 'guest@sotayyte.local',
        passwordHash: '',
        salt: '',
        isGuest: true,
        createdAt: DateTime.now(),
      );

      _state = _state.copyWith(
        status: LoginStatus.success,
        loggedInUser: guestAccount,
        requiresAppLockUnlock: false,
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

  Future<PasswordRecoveryChallenge> sendPasswordRecoveryChallenge(
    String identifier,
  ) async {
    _state = _state.copyWith(status: LoginStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      final challenge =
          await _authRepository.sendPasswordRecoveryChallenge(identifier);
      _state = _state.copyWith(status: LoginStatus.initial, errorMessage: null);
      notifyListeners();
      return challenge;
    } catch (e) {
      _state = _state.copyWith(
        status: LoginStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> verifyRecoveryAndResetPassword({
    required String identifier,
    required String verificationId,
    required String otpCode,
    required String newPassword,
  }) async {
    _state = _state.copyWith(status: LoginStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      await _authRepository.verifyRecoveryAndResetPassword(
        identifier: identifier.trim(),
        verificationId: verificationId,
        otpCode: otpCode.trim(),
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

  Future<bool> resetPassword({
    required String identifier,
    required String newPassword,
  }) async {
    if (identifier.trim().isEmpty || newPassword.length < 6) {
      _state = _state.copyWith(
        status: LoginStatus.error,
        errorMessage:
            'Vui lòng nhập định danh và mật khẩu mới tối thiểu 6 ký tự.',
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
    throw Exception('Tài khoản chưa được đăng ký trong hệ thống.');
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
  Future<bool> checkAccountExists(String identifier) async => false;

  @override
  Future<UserAccount?> getBiometricBoundAccount() async => null;

  @override
  Future<String?> getLastLoginIdentifier() async => null;

  @override
  Future<bool> isDeviceAppLockEnabled() async => false;

  @override
  Future<UserProfile?> getCurrentUser() async => null;

  @override
  Future<UserProfile> loginAnonymous() async =>
      const UserProfile(id: 'guest', fullName: 'Khách');

  @override
  Future<UserProfile> linkAccount({
    required String email,
    required String password,
  }) async =>
      const UserProfile(id: 'link', fullName: 'Link');

  @override
  Future<bool> checkProStatus() async => false;

  @override
  Future<void> logout() async {}

  @override
  Future<void> resetPassword({
    required String identifier,
    required String newPassword,
  }) async {}

  @override
  Future<PasswordRecoveryChallenge> sendPasswordRecoveryChallenge(
    String identifier,
  ) async {
    return PasswordRecoveryChallenge(
      verificationId: 'rec-fallback',
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
    return UserAccount(
      id: 'email-otp-user',
      patientCode: 'STYT-999999',
      fullName: fullName,
      primaryContact: email,
      passwordHash: '',
      salt: '',
      createdAt: DateTime.now(),
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
    return UserAccount(
      id: userId,
      patientCode: 'STYT-999999',
      fullName: fullName,
      primaryContact: '',
      passwordHash: '',
      salt: '',
      bloodType: bloodType,
      gender: gender,
      dateOfBirth: dateOfBirth,
      createdAt: DateTime.now(),
    );
  }

  @override
  String? peekSandboxOtp(String verificationId) => '123456';

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
      patientCode: 'STYT-999999',
      fullName: 'Chủ hồ sơ ($phoneNumber)',
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
    throw Exception('Chưa cấu hình OAuth.');
  }

  @override
  Future<UserAccount> syncSupabaseUserSession({
    required String userId,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? provider,
  }) async {
    return UserAccount(
      id: userId,
      patientCode: 'STYT-999999',
      fullName: fullName ?? 'Chủ hồ sơ',
      primaryContact: email ?? 'user@sotayyte.vn',
      passwordHash: '',
      salt: '',
      createdAt: DateTime.now(),
    );
  }
}
