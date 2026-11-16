import '../entities/user_account.dart';
import '../entities/user_profile.dart';

abstract class AuthRepository {
  Future<UserProfile?> getCurrentUser();
  Future<UserProfile> loginAnonymous();
  Future<UserProfile> linkAccount({required String email, required String password});
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
  });

  Future<UserAccount> login({
    required String identifier,
    required String password,
    bool rememberMe = true,
  });

  Future<UserAccount?> getActiveSession();
  Future<void> resetPassword({
    required String identifier,
    required String newPassword,
  });

  // Hybrid Phone OTP (Firebase & Supabase)
  Future<String> sendPhoneOtp(String phoneNumber);

  Future<UserAccount> verifyPhoneOtp({
    required String phoneNumber,
    required String verificationId,
    required String smsCode,
  });

  // Social Sign-In (Apple & Google)
  Future<UserAccount> signInWithSocialProvider({
    required String provider,
    String? idToken,
    String? accessToken,
  });
}
