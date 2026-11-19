import '../entities/user_account.dart';
import '../entities/user_profile.dart';

class PasswordRecoveryChallenge {
  final String verificationId;
  final String maskedContact;
  final String targetContact;
  final bool isEmailLinkSent;
  final String? sandboxOtpPreview;

  const PasswordRecoveryChallenge({
    required this.verificationId,
    required this.maskedContact,
    required this.targetContact,
    this.isEmailLinkSent = false,
    this.sandboxOtpPreview,
  });
}

abstract class AuthRepository {
  Future<UserProfile?> getCurrentUser();
  Future<UserProfile> loginAnonymous();
  Future<UserProfile> linkAccount({
    required String email,
    required String password,
  });
  Future<bool> checkProStatus();
  Future<void> logout();

  // Full Clinical Authentication
  Future<UserAccount> register({
    required String fullName,
    required String contact,
    required String password,
    String? dateOfBirth,
    String? gender,
    String? bloodType,
    bool enableBiometric = false,
  });

  Future<UserAccount> login({
    required String identifier,
    required String password,
    bool rememberMe = true,
  });

  Future<UserAccount?> getActiveSession();
  Future<bool> checkAccountExists(String identifier);

  // Biometric & Device Lock Helpers
  Future<UserAccount?> getBiometricBoundAccount();
  Future<String?> getLastLoginIdentifier();
  Future<bool> isDeviceAppLockEnabled();

  // Password Recovery with Identity Verification
  Future<void> resetPassword({
    required String identifier,
    required String newPassword,
  });

  Future<PasswordRecoveryChallenge> sendPasswordRecoveryChallenge(
    String identifier,
  );

  Future<void> verifyRecoveryAndResetPassword({
    required String identifier,
    required String verificationId,
    required String otpCode,
    required String newPassword,
  });

  // Hybrid Phone & Email OTP (Firebase & Supabase)
  Future<String> sendPhoneOtp(String phoneNumber);
  String? peekSandboxOtp(String verificationId);

  Future<UserAccount> verifyPhoneOtp({
    required String phoneNumber,
    required String verificationId,
    required String smsCode,
  });

  /// Chỉ xác thực mã OTP mà không tạo user (dùng cho luồng đăng ký SĐT)
  Future<void> verifyPhoneOtpOnly({
    required String phoneNumber,
    required String verificationId,
    required String smsCode,
  });

  /// Xác thực mã OTP Email khi Supabase bật Confirm Email
  Future<UserAccount> verifyEmailSignupOtp({
    required String email,
    required String otpCode,
    required String password,
    required String fullName,
    String? dateOfBirth,
    String? gender,
    String? bloodType,
    bool enableBiometric = false,
  });

  /// Cập nhật họ tên & nhóm máu cho tài khoản SĐT mới đăng nhập qua OTP lần đầu
  Future<UserAccount> completePhoneProfileSetup({
    required String userId,
    required String fullName,
    String? bloodType,
    String? gender,
    String? dateOfBirth,
  });

  /// Cập nhật đầy đủ thông tin hồ sơ cá nhân và đồng bộ dữ liệu
  Future<UserAccount> updateUserProfile({
    required String userId,
    required String fullName,
    String? dateOfBirth,
    String? gender,
    String? bloodType,
    String? emergencyContact,
    String? allergies,
    String? chronicConditions,
    String? height,
    String? weight,
    String? organDonor,
    String? avatarUrl,
    String? region,
  });

  /// Lấy thông tin bổ sung về hồ sơ cá nhân (chiều cao, cân nặng, dị ứng, bệnh nền...)
  Future<Map<String, dynamic>?> getUserProfileDetails(String userId);

  // Social Sign-In (Apple & Google)
  Future<UserAccount> signInWithSocialProvider({
    required String provider,
    String? idToken,
    String? accessToken,
  });

  Future<UserAccount> syncSupabaseUserSession({
    required String userId,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? provider,
  });
}
