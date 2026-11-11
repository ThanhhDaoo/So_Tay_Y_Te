import '../entities/user_profile.dart';

abstract class AuthRepository {
  Future<UserProfile?> getCurrentUser();
  Future<UserProfile> loginAnonymous();
  Future<UserProfile> linkAccount({required String email, required String password});
  Future<bool> checkProStatus();
  Future<void> logout();
}
