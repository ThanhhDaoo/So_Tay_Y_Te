import '../../../../domain/entities/user_account.dart';

enum LoginStatus { initial, loading, success, error }

class LoginState {
  final LoginStatus status;
  final bool obscurePassword;
  final bool rememberMe;
  final UserAccount? loggedInUser;
  final String? errorMessage;

  const LoginState({
    this.status = LoginStatus.initial,
    this.obscurePassword = true,
    this.rememberMe = true,
    this.loggedInUser,
    this.errorMessage,
  });

  bool get isLoading => status == LoginStatus.loading;

  LoginState copyWith({
    LoginStatus? status,
    bool? obscurePassword,
    bool? rememberMe,
    UserAccount? loggedInUser,
    String? errorMessage,
  }) {
    return LoginState(
      status: status ?? this.status,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      rememberMe: rememberMe ?? this.rememberMe,
      loggedInUser: loggedInUser ?? this.loggedInUser,
      errorMessage: errorMessage,
    );
  }
}
