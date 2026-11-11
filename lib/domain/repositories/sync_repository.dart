abstract class SyncRepository {
  Future<void> syncLocalToCloud();
  Future<void> syncCloudToLocal();
  Future<DateTime?> getLastSyncTime();
}
