import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/app_preferences_datasource.dart';
import '../datasources/remote/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AppPreferencesDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<UserProfile?> getCurrentUser() async {
    return null;
  }

  @override
  Future<UserProfile> loginAnonymous() async {
    final user = await remoteDataSource.loginAnonymous();
    return user.toEntity();
  }

  @override
  Future<UserProfile> linkAccount({required String email, required String password}) async {
    final user = await remoteDataSource.linkAccount(email: email, password: password);
    return user.toEntity();
  }

  @override
  Future<bool> checkProStatus() async {
    return await localDataSource.getProStatus();
  }

  @override
  Future<void> logout() async {
    await localDataSource.saveToken('');
  }
}
