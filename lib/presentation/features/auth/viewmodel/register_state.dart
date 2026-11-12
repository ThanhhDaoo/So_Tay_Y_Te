enum RegisterStatus { initial, loading, success, error }

enum PasswordStrength {
  weak(1, 'Yếu'),
  medium(2, 'Trung bình'),
  strong(3, 'Mạnh');

  final int level;
  final String label;
  const PasswordStrength(this.level, this.label);
}

class RegisterState {
  final RegisterStatus status;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool enableBiometric;
  final bool acceptedTerms;
  final PasswordStrength passwordStrength;
  final String? errorMessage;

  const RegisterState({
    this.status = RegisterStatus.initial,
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
    this.enableBiometric = true,
    this.acceptedTerms = true,
    this.passwordStrength = PasswordStrength.medium,
    this.errorMessage,
  });

  bool get isLoading => status == RegisterStatus.loading;

  RegisterState copyWith({
    RegisterStatus? status,
    bool? obscurePassword,
    bool? obscureConfirmPassword,
    bool? enableBiometric,
    bool? acceptedTerms,
    PasswordStrength? passwordStrength,
    String? errorMessage,
  }) {
    return RegisterState(
      status: status ?? this.status,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirmPassword:
          obscureConfirmPassword ?? this.obscureConfirmPassword,
      enableBiometric: enableBiometric ?? this.enableBiometric,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      passwordStrength: passwordStrength ?? this.passwordStrength,
      errorMessage: errorMessage,
    );
  }
}

