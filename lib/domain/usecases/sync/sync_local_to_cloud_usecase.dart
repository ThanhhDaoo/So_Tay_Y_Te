import '../../repositories/sync_repository.dart';

class SyncLocalToCloudUseCase {
  final SyncRepository repository;

  SyncLocalToCloudUseCase(this.repository);

  Future<void> call() async {
    await repository.syncLocalToCloud();
  }
}
