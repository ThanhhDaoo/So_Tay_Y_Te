import '../../repositories/auth_repository.dart';

class CheckProStatusUseCase {
  final AuthRepository repository;

  CheckProStatusUseCase(this.repository);

  Future<bool> call() async {
    return await repository.checkProStatus();
  }
}
