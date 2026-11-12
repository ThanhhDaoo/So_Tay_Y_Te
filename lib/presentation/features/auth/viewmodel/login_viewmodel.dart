import 'package:flutter/material.dart';
import 'login_state.dart';

class LoginViewModel extends ChangeNotifier {
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  LoginState _state = const LoginState();
  LoginState get state => _state;

  void togglePasswordVisibility() {
    _state = _state.copyWith(obscurePassword: !_state.obscurePassword);
    notifyListeners();
  }

  void toggleRememberMe(bool? value) {
    _state = _state.copyWith(rememberMe: value ?? false);
    notifyListeners();
  }

  Future<bool> signInWithEmailOrId() async {
    if (!(formKey.currentState?.validate() ?? false)) return false;

    _state = _state.copyWith(status: LoginStatus.loading, errorMessage: null);
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));
    _state = _state.copyWith(status: LoginStatus.success);
    notifyListeners();
    return true;
  }

  Future<bool> signInWithSocial(String provider) async {
    _state = _state.copyWith(status: LoginStatus.loading, errorMessage: null);
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));
    _state = _state.copyWith(status: LoginStatus.success);
    notifyListeners();
    return true;
  }

  Future<bool> continueAsGuestOffline() async {
    _state = _state.copyWith(status: LoginStatus.loading, errorMessage: null);
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 400));
    _state = _state.copyWith(status: LoginStatus.success);
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

