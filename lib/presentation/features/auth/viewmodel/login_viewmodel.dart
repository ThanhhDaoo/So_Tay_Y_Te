import 'package:flutter/material.dart';
import '../../../../data/datasources/local/mock_auth_datasource.dart';
import 'login_state.dart';

class LoginViewModel extends ChangeNotifier {
  final MockAuthDataSource _mockAuthDataSource;
  final TextEditingController identifierController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  LoginState _state = const LoginState();
  LoginState get state => _state;

  MockAuthAccount? _loggedInAccount;
  MockAuthAccount? get loggedInAccount => _loggedInAccount;

  LoginViewModel({MockAuthDataSource? mockAuthDataSource})
    : _mockAuthDataSource = mockAuthDataSource ?? MockAuthDataSource(),
      identifierController = TextEditingController(
        text: MockAuthDataSource.defaultDemoAccount.profileCode,
      ),
      passwordController = TextEditingController(
        text: MockAuthDataSource.defaultDemoAccount.password,
      );

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

    await Future.delayed(const Duration(milliseconds: 500));

    final account = _mockAuthDataSource.authenticate(
      identifier: identifierController.text,
      password: passwordController.text,
    );

    if (account == null) {
      _state = _state.copyWith(
        status: LoginStatus.error,
        errorMessage:
            'Sai mã hồ sơ/email hoặc mật khẩu. Dùng thử: STYT-892410 / 123456',
      );
      notifyListeners();
      return false;
    }

    _loggedInAccount = account;
    _state = _state.copyWith(status: LoginStatus.success, errorMessage: null);
    notifyListeners();
    return true;
  }

  Future<bool> signInWithSocial(String provider) async {
    _state = _state.copyWith(status: LoginStatus.loading, errorMessage: null);
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));
    _loggedInAccount = MockAuthDataSource.defaultDemoAccount;
    _state = _state.copyWith(status: LoginStatus.success, errorMessage: null);
    notifyListeners();
    return true;
  }

  Future<bool> continueAsGuestOffline() async {
    _state = _state.copyWith(status: LoginStatus.loading, errorMessage: null);
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 400));
    _loggedInAccount = null;
    _state = _state.copyWith(status: LoginStatus.success, errorMessage: null);
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
