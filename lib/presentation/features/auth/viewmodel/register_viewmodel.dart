import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
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
  final TextEditingController confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  RegisterState _state = const RegisterState();
  RegisterState get state => _state;

  RegisterViewModel({AuthRepository? authRepository})
      : _authRepository = authRepository ?? (sl.isRegistered<AuthRepository>() ? sl<AuthRepository>() : _createFallbackRepo());

  static AuthRepository _createFallbackRepo() {
    return _FallbackRegisterAuthRepository();
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
    dobController.text = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    notifyListeners();
  }

  String? _verificationId;
  String? get verificationId => _verificationId;

  bool validateRegistrationForm() {
    if (!_state.acceptedTerms) {
      _state = _state.copyWith(
        status: RegisterStatus.error,
        errorMessage: 'Vui lòng đồng ý với Điều khoản Dịch vụ & Cam kết Bảo mật HIPAA.',
      );
      notifyListeners();
      return false;
    }

    final form = formKey.currentState;
    if (form != null && !form.validate()) {
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

  Future<String> sendRegistrationOtp() async {
    _state = _state.copyWith(status: RegisterStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      final contact = contactController.text.trim();
      final verId = await _authRepository.sendPhoneOtp(contact);
      _verificationId = verId;
      _state = _state.copyWith(status: RegisterStatus.initial, errorMessage: null);
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

  Future<bool> verifyOtpAndRegister(String smsCode) async {
    _state = _state.copyWith(status: RegisterStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      final contact = contactController.text.trim();
      // 1. Chỉ xác thực mã OTP (KHÔNG tạo user) — tránh lỗi "đã đăng ký"
      await _authRepository.verifyPhoneOtpOnly(
        phoneNumber: contact,
        verificationId: _verificationId ?? 'ver-init',
        smsCode: smsCode,
      );

      // 2. OTP hợp lệ → Tạo tài khoản y tế chính thức qua register()
      final user = await _authRepository.register(
        fullName: fullNameController.text.trim(),
        contact: contact,
        password: passwordController.text,
        dateOfBirth: _state.dateOfBirth != null
            ? '${_state.dateOfBirth!.year}-${_state.dateOfBirth!.month.toString().padLeft(2, '0')}-${_state.dateOfBirth!.day.toString().padLeft(2, '0')}'
            : null,
        gender: _state.gender,
        bloodType: _state.bloodType,
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
    if (!_state.acceptedTerms) {
      _state = _state.copyWith(
        status: RegisterStatus.error,
        errorMessage: 'Vui lòng đồng ý với Điều khoản Dịch vụ & Cam kết Bảo mật HIPAA.',
      );
      notifyListeners();
      return false;
    }

    final form = formKey.currentState;
    if (form != null && !form.validate()) {
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

    _state = _state.copyWith(status: RegisterStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      final user = await _authRepository.register(
        fullName: fullNameController.text.trim(),
        contact: contactController.text.trim(),
        password: passwordController.text,
        dateOfBirth: _state.dateOfBirth != null
            ? '${_state.dateOfBirth!.year}-${_state.dateOfBirth!.month.toString().padLeft(2, '0')}-${_state.dateOfBirth!.day.toString().padLeft(2, '0')}'
            : null,
        gender: _state.gender,
        bloodType: _state.bloodType,
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

  Future<bool> registerWithSocial(String provider) async {
    _state = _state.copyWith(status: RegisterStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      final user = await _authRepository.signInWithSocialProvider(
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

  Future<bool> handleOAuthSessionSuccess({
    required String userId,
    String? email,
    String? fullName,
  }) async {
    _state = _state.copyWith(status: RegisterStatus.loading, errorMessage: null);
    notifyListeners();

    try {
      final user = await _authRepository.syncSupabaseUserSession(
        userId: userId,
        email: email,
        fullName: fullName,
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
      dateOfBirth: dateOfBirth,
      gender: gender,
      bloodType: bloodType,
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
      patientCode: 'STYT-999999',
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
      patientCode: 'STYT-999999',
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
      patientCode: 'STYT-999999',
      fullName: fullName ?? 'Bệnh nhân',
      primaryContact: email ?? 'user@test.vn',
      passwordHash: '',
      salt: '',
      createdAt: DateTime.now(),
    );
  }
}
