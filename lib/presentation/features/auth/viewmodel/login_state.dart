import '../../../../domain/entities/user_account.dart';

enum LoginStatus { initial, loading, awaitingOAuth, success, error }

class LoginState {
  final LoginStatus status;
  final bool obscurePassword;
  final bool rememberMe;
  final bool requiresAppLockUnlock;
  final UserAccount? loggedInUser;
  final String? errorMessage;

  const LoginState({
    this.status = LoginStatus.initial,
    this.obscurePassword = true,
    this.rememberMe = true,
    this.requiresAppLockUnlock = false,
    this.loggedInUser,
    this.errorMessage,
  });

  bool get isLoading => status == LoginStatus.loading;
  bool get isAwaitingOAuth => status == LoginStatus.awaitingOAuth;

  LoginState copyWith({
    LoginStatus? status,
    bool? obscurePassword,
    bool? rememberMe,
    bool? requiresAppLockUnlock,
    UserAccount? loggedInUser,
    String? errorMessage,
  }) {
    return LoginState(
      status: status ?? this.status,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      rememberMe: rememberMe ?? this.rememberMe,
      requiresAppLockUnlock:
          requiresAppLockUnlock ?? this.requiresAppLockUnlock,
      loggedInUser: loggedInUser ?? this.loggedInUser,
      errorMessage: errorMessage,
    );
  }
}
