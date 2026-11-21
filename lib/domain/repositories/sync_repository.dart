abstract class SyncRepository {
  Future<void> syncLocalToCloud();
  Future<void> syncCloudToLocal();
  Future<void> syncBothWays();
  Future<DateTime?> getLastSyncTime();
}
