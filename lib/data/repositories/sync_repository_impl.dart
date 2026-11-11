import '../../domain/repositories/sync_repository.dart';
import '../datasources/local/medical_local_datasource.dart';
import '../datasources/remote/medical_sync_remote_datasource.dart';

class SyncRepositoryImpl implements SyncRepository {
  final MedicalLocalDataSource localDataSource;
  final MedicalSyncRemoteDataSource remoteDataSource;

  SyncRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<void> syncLocalToCloud() async {
    final events = await localDataSource.getAllEvents();
    await remoteDataSource.uploadEvents(events);
  }

  @override
  Future<void> syncCloudToLocal() async {
    final events = await remoteDataSource.fetchLatestEvents();
    for (final event in events) {
      await localDataSource.insertOrUpdateEvent(event);
    }
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    return DateTime.now();
  }
}
