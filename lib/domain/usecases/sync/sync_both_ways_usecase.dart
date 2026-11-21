import '../../repositories/sync_repository.dart';

class SyncBothWaysUseCase {
  final SyncRepository repository;

  SyncBothWaysUseCase(this.repository);

  Future<void> call() async {
    await repository.syncBothWays();
  }
}
