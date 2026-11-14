import '../../../../domain/entities/user_account.dart';

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
  final String gender;
  final String bloodType;
  final DateTime? dateOfBirth;
  final UserAccount? createdAccount;
  final String? errorMessage;

  const RegisterState({
    this.status = RegisterStatus.initial,
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
    this.enableBiometric = true,
    this.acceptedTerms = true,
    this.passwordStrength = PasswordStrength.medium,
    this.gender = 'Nam',
    this.bloodType = 'O+',
    this.dateOfBirth,
    this.createdAccount,
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
    String? gender,
    String? bloodType,
    DateTime? dateOfBirth,
    UserAccount? createdAccount,
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
      gender: gender ?? this.gender,
      bloodType: bloodType ?? this.bloodType,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      createdAccount: createdAccount ?? this.createdAccount,
      errorMessage: errorMessage,
    );
  }
}
