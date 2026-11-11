import '../../entities/user_profile.dart';
import '../../repositories/auth_repository.dart';

class LinkAnonymousAccountUseCase {
  final AuthRepository repository;

  LinkAnonymousAccountUseCase(this.repository);

  Future<UserProfile> call({required String email, required String password}) async {
    return await repository.linkAccount(email: email, password: password);
  }
}
