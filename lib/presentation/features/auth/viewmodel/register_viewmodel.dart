import 'package:flutter/material.dart';
import 'register_state.dart';

class RegisterViewModel extends ChangeNotifier {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  RegisterState _state = const RegisterState();
  RegisterState get state => _state;

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
    if (password.length >= 10 && hasUpper && hasDigit && hasSpecial) {
      return PasswordStrength.strong;
    }
    return PasswordStrength.medium;
  }

  void togglePasswordVisibility() {
    _state = _state.copyWith(obscurePassword: !_state.obscurePassword);
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

  Future<bool> submitRegistration() async {
    if (!_state.acceptedTerms) {
      _state = _state.copyWith(
        status: RegisterStatus.error,
        errorMessage: 'Vui lòng đồng ý với Điều khoản Dịch vụ & Bảo mật HIPAA.',
      );
      notifyListeners();
      return false;
    }

    if (!(formKey.currentState?.validate() ?? false)) return false;

    _state = _state.copyWith(status: RegisterStatus.loading, errorMessage: null);
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));
    _state = _state.copyWith(status: RegisterStatus.success);
    notifyListeners();
    return true;
  }

  Future<bool> registerWithSocial(String provider) async {
    _state = _state.copyWith(status: RegisterStatus.loading, errorMessage: null);
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));
    _state = _state.copyWith(status: RegisterStatus.success);
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    fullNameController.dispose();
    contactController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}

