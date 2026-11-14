import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
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
    throw UnimplementedError('AuthRepository is not registered in GetIt.');
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
      final isApple = provider.toLowerCase() == 'apple';
      final defaultName = isApple ? 'Bệnh nhân Apple' : 'Bệnh nhân Google';
      final defaultContact = isApple ? 'apple_user@icloud.com' : 'google_user@gmail.com';

      final user = await _authRepository.register(
        fullName: defaultName,
        contact: defaultContact,
        password: 'SocialOAuthSecureToken2026!',
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
      // Nếu tài khoản đã tồn tại qua email này, tiến hành login tự động
      try {
        final isApple = provider.toLowerCase() == 'apple';
        final defaultContact = isApple ? 'apple_user@icloud.com' : 'google_user@gmail.com';
        final user = await _authRepository.login(
          identifier: defaultContact,
          password: 'SocialOAuthSecureToken2026!',
        );
        _state = _state.copyWith(
          status: RegisterStatus.success,
          createdAccount: user,
          errorMessage: null,
        );
        notifyListeners();
        return true;
      } catch (_) {
        _state = _state.copyWith(
          status: RegisterStatus.error,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        );
        notifyListeners();
        return false;
      }
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
