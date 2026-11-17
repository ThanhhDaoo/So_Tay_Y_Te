import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../data/datasources/remote/supabase_auth_datasource.dart';
import '../../../../domain/entities/user_account.dart';
import '../../../../domain/entities/user_profile.dart';
import '../../../../domain/repositories/auth_repository.dart';
import 'register_state.dart';

class RegisterViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  RegisterState _state = const RegisterState();
  RegisterState get state => _state;

  bool _isAwaitingOAuth = false;
  bool get isAwaitingOAuth => _isAwaitingOAuth;
  String? _pendingOAuthProvider;

  bool _isPendingEmailOtp = false;
  bool get isPendingEmailOtp => _isPendingEmailOtp;

  String? _verificationId;
  String? get verificationId => _verificationId;

  RegisterViewModel({AuthRepository? authRepository})
      : _authRepository = authRepository ??
            (sl.isRegistered<AuthRepository>()
                ? sl<AuthRepository>()
                : _createFallbackRepo());

  static AuthRepository _createFallbackRepo() {
    return _FallbackRegisterAuthRepository();
  }

  void cancelPendingOAuth() {
    if (!_isAwaitingOAuth && _state.status != RegisterStatus.awaitingOAuth) {
      return;
    }
    _isAwaitingOAuth = false;
    _pendingOAuthProvider = null;
    _state = _state.copyWith(
      status: RegisterStatus.initial,
      errorMessage: null,
    );
    notifyListeners();
  }

  String? peekSandboxOtp() {
    if (_verificationId == null) return null;
    return _authRepository.peekSandboxOtp(_verificationId!);
  }

  void onPasswordChanged(String value) {
    final strength = _evaluatePasswordStrength(value);
    if (strength != _state.passwordStrength) {
      _state = _state.copyWith(passwordStrength: strength);
      notifyListeners();
    }
  }

  PasswordStrength _evaluatePasswordStrength(String password) {
    if (password.length < 6) return PasswordStrength.weak;
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    if (password.length >= 8 && (hasUpper || hasDigit || hasSpecial)) {
      if (password.length >= 10 && hasUpper && hasDigit && hasSpecial) {
        return PasswordStrength.strong;
      }
      return PasswordStrength.medium;
    }
    return PasswordStrength.weak;
  }

  void togglePasswordVisibility() {
    _state = _state.copyWith(obscurePassword: !_state.obscurePassword);
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _state = _state.copyWith(
      obscureConfirmPassword: !_state.obscureConfirmPassword,
    );
    notifyListeners();
  }

  void toggleBiometric(bool? value) {
    _state = _state.copyWith(enableBiometric: value ?? false);
    notifyListeners();
  }

  void toggleAcceptedTerms(bool? value) {
    _state = _state.copyWith(acceptedTerms: value ?? false);
    notifyListeners();
  }

  void setGender(String gender) {
    _state = _state.copyWith(gender: gender);
    notifyListeners();
  }

  void setBloodType(String bloodType) {
    _state = _state.copyWith(bloodType: bloodType);
    notifyListeners();
  }

  void setDateOfBirth(DateTime date) {
    _state = _state.copyWith(dateOfBirth: date);
    dobController.text =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    notifyListeners();
  }

  String? get _formattedIsoDob => _state.dateOfBirth != null
      ? '${_state.dateOfBirth!.year}-${_state.dateOfBirth!.month.toString().padLeft(2, '0')}-${_state.dateOfBirth!.day.toString().padLeft(2, '0')}'
      : null;

  bool validateRegistrationForm() {
    if (!_state.acceptedTerms) {
      _state = _state.copyWith(
        status: RegisterStatus.error,
        errorMessage:
            'Vui lòng đồng ý với Điều khoản Dịch vụ & Cam kết Bảo mật HIPAA.',
      );
      notifyListeners();
      return false;
    }

    final form = formKey.currentState;
    if (form != null && !form.validate()) {
      return false;
    }

    final nameErr = InputValidators.validateFullName(fullNameController.text);
    if (nameErr != null) {
      _state = _state.copyWith(
        status: RegisterStatus.error,
        errorMessage: nameErr,
      );
      notifyListeners();
      return false;
    }

    final contactErr =
        InputValidators.validateEmailOrPhone(contactController.text);
    if (contactErr != null) {
      _state = _state.copyWith(
        status: RegisterStatus.error,
        errorMessage: contactErr,
      );
      notifyListeners();
      return false;
    }

    final passErr = InputValidators.validatePassword(passwordController.text);
    if (passErr != null) {
      _state = _state.copyWith(
        status: RegisterStatus.error,
        errorMessage: passErr,
      );
      notifyListeners();
      return false;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _state = _state.copyWith(
        status: RegisterStatus.error,
        errorMessage: 'Mật khẩu xác nhận không khớp. Vui lòng kiểm tra lại.',
      );
      notifyListeners();
      return false;
    }

    return true;
  }

  /// Quy trình chuẩn thực tế: Kiểm tra form -> Kiểm tra trùng tài khoản -> Gửi OTP (nếu SĐT) hoặc Đăng ký (nếu Email)
  Future<RegistrationFlowStep> initiateRegistrationFlow() async {
    if (!validateRegistrationForm()) {
      return RegistrationFlowStep.invalid;
    }

    final rawContact = contactController.text.trim();
    final idType = InputValidators.classifyIdentifier(rawContact);

    _state =
        _state.copyWith(status: RegisterStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      // 1. Kiểm tra tài khoản đã tồn tại chưa TRƯỚC KHI gửi OTP
      final alreadyExists = await _authRepository.checkAccountExists(rawContact);
      if (alreadyExists) {
        _state = _state.copyWith(
          status: RegisterStatus.error,
          errorMessage:
              'Số điện thoại hoặc Email này đã được đăng ký hồ sơ.',
        );
        notifyListeners();
        return RegistrationFlowStep.failed;
      }

      // 2. Nếu đăng ký bằng Số điện thoại -> bắt buộc xác thực SMS OTP 6 số trước
      if (idType == AuthIdentifierType.phone) {
        _isPendingEmailOtp = false;
        final verId = await _authRepository.sendPhoneOtp(rawContact);
        _verificationId = verId;
        _state =
            _state.copyWith(status: RegisterStatus.initial, errorMessage: null);
        notifyListeners();
        return RegistrationFlowStep.requirePhoneOtp;
      }

      // 3. Nếu đăng ký bằng Email -> tạo tài khoản trên Supabase & Local
      _isPendingEmailOtp = false;
      final user = await _authRepository.register(
        fullName: fullNameController.text.trim(),
        contact: rawContact,
        password: passwordController.text,
        dateOfBirth: _formattedIsoDob,
        gender: _state.gender,
        bloodType: _state.bloodType,
        enableBiometric: _state.enableBiometric,
      );

      _state = _state.copyWith(
        status: RegisterStatus.success,
        createdAccount: user,
        errorMessage: null,
      );
      notifyListeners();
      return RegistrationFlowStep.completed;
    } on AuthEmailConfirmationRequiredException {
      // Dự án Supabase bật Confirm Email -> mở bảng nhập mã OTP 6 số gửi qua Email
      _isPendingEmailOtp = true;
      _verificationId = 'email-signup-otp';
      _state =
          _state.copyWith(status: RegisterStatus.initial, errorMessage: null);
      notifyListeners();
      return RegistrationFlowStep.requireEmailOtp;
    } catch (e) {
      _state = _state.copyWith(
        status: RegisterStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      notifyListeners();
      return RegistrationFlowStep.failed;
    }
  }

  Future<String> sendRegistrationOtp() async {
    _state =
        _state.copyWith(status: RegisterStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      final contact = contactController.text.trim();
      if (_isPendingEmailOtp) {
        if (sl.isRegistered<SupabaseAuthRemoteDataSource>()) {
          await sl<SupabaseAuthRemoteDataSource>().sendEmailOtp(email: contact);
        }
        _state =
            _state.copyWith(status: RegisterStatus.initial, errorMessage: null);
        notifyListeners();
        return 'email-signup-otp';
      }

      final verId = await _authRepository.sendPhoneOtp(contact);
      _verificationId = verId;
      _state =
          _state.copyWith(status: RegisterStatus.initial, errorMessage: null);
      notifyListeners();
      return verId;
    } catch (e) {
      _state = _state.copyWith(
        status: RegisterStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      notifyListeners();
      rethrow;
    }
  }

  /// Kiểm tra khi người dùng đã nhấn vào liên kết xác nhận trong Email từ Supabase
  Future<bool> confirmEmailLinkVerified() async {
    _state =
        _state.copyWith(status: RegisterStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      final email = contactController.text.trim().toLowerCase();
      final user = await _authRepository.login(
        identifier: email,
        password: passwordController.text,
        rememberMe: true,
      );
      _isPendingEmailOtp = false;
      _state = _state.copyWith(
        status: RegisterStatus.success,
        createdAccount: user,
        errorMessage: null,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _state = _state.copyWith(
        status: RegisterStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtpAndRegister(String otpCode) async {
    _state =
        _state.copyWith(status: RegisterStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      final contact = contactController.text.trim();

      if (_isPendingEmailOtp) {
        final user = await _authRepository.verifyEmailSignupOtp(
          email: contact,
          otpCode: otpCode,
          password: passwordController.text,
          fullName: fullNameController.text.trim(),
          dateOfBirth: _formattedIsoDob,
          gender: _state.gender,
          bloodType: _state.bloodType,
          enableBiometric: _state.enableBiometric,
        );
        _isPendingEmailOtp = false;
        _state = _state.copyWith(
          status: RegisterStatus.success,
          createdAccount: user,
          errorMessage: null,
        );
        notifyListeners();
        return true;
      }

      // 1. Chỉ xác thực mã SMS OTP (KHÔNG tạo user) — tránh xung đột trùng tài khoản
      await _authRepository.verifyPhoneOtpOnly(
        phoneNumber: contact,
        verificationId: _verificationId ?? 'ver-init',
        smsCode: otpCode,
      );

      // 2. OTP hợp lệ -> Tạo tài khoản y tế chính thức qua register()
      final user = await _authRepository.register(
        fullName: fullNameController.text.trim(),
        contact: contact,
        password: passwordController.text,
        dateOfBirth: _formattedIsoDob,
        gender: _state.gender,
        bloodType: _state.bloodType,
        enableBiometric: _state.enableBiometric,
      );

      _state = _state.copyWith(
        status: RegisterStatus.success,
        createdAccount: user,
        errorMessage: null,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _state = _state.copyWith(
        status: RegisterStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitRegistration() async {
    if (!validateRegistrationForm()) {
      return false;
    }

    _state =
        _state.copyWith(status: RegisterStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      final user = await _authRepository.register(
        fullName: fullNameController.text.trim(),
        contact: contactController.text.trim(),
        password: passwordController.text,
        dateOfBirth: _formattedIsoDob,
        gender: _state.gender,
        bloodType: _state.bloodType,
        enableBiometric: _state.enableBiometric,
      );

      _state = _state.copyWith(
        status: RegisterStatus.success,
        createdAccount: user,
        errorMessage: null,
      );
      notifyListeners();
      return true;
    } on AuthEmailConfirmationRequiredException {
      _isPendingEmailOtp = true;
      _verificationId = 'email-signup-otp';
      _state =
          _state.copyWith(status: RegisterStatus.initial, errorMessage: null);
      notifyListeners();
      return false;
    } catch (e) {
      _state = _state.copyWith(
        status: RegisterStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerWithSocial(String provider) async {
    _isAwaitingOAuth = true;
    _pendingOAuthProvider = provider;
    _state =
        _state.copyWith(status: RegisterStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      final user = await _authRepository.signInWithSocialProvider(
        provider: provider,
      );

      if (user.id == 'oauth_in_progress') {
        _state = _state.copyWith(
          status: RegisterStatus.awaitingOAuth,
          errorMessage: null,
        );
        notifyListeners();
        return true;
      }

      _isAwaitingOAuth = false;
      _pendingOAuthProvider = null;
      _state = _state.copyWith(
        status: RegisterStatus.success,
        createdAccount: user,
        errorMessage: null,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _isAwaitingOAuth = false;
      _pendingOAuthProvider = null;
      _state = _state.copyWith(
        status: RegisterStatus.error,
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
    _state =
        _state.copyWith(status: RegisterStatus.loading, errorMessage: null);
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
        status: RegisterStatus.success,
        createdAccount: user,
        errorMessage: null,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _state = _state.copyWith(
        status: RegisterStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    contactController.dispose();
    dobController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}

class _FallbackRegisterAuthRepository implements AuthRepository {
  @override
  Future<UserAccount> login({
    required String identifier,
    required String password,
    bool rememberMe = true,
  }) async {
    throw Exception('Tài khoản chưa được đăng ký.');
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
      dateOfBirth: dateOfBirth,
      gender: gender,
      bloodType: bloodType,
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
