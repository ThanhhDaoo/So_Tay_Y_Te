abstract class SyncRepository {
  Future<void> syncLocalToCloud();
  Future<void> syncCloudToLocal();
  Future<void> syncBothWays();
  Future<void> deleteRemoteEvent(String id);
  Future<DateTime?> getLastSyncTime();
}
