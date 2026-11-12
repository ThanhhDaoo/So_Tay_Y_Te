enum LoginStatus { initial, loading, success, error }

class LoginState {
  final LoginStatus status;
  final bool obscurePassword;
  final bool rememberMe;
  final String? errorMessage;

  const LoginState({
    this.status = LoginStatus.initial,
    this.obscurePassword = true,
    this.rememberMe = false,
    this.errorMessage,
  });

  bool get isLoading => status == LoginStatus.loading;

  LoginState copyWith({
    LoginStatus? status,
    bool? obscurePassword,
    bool? rememberMe,
    String? errorMessage,
  }) {
    return LoginState(
      status: status ?? this.status,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      rememberMe: rememberMe ?? this.rememberMe,
      errorMessage: errorMessage,
    );
  }
}

