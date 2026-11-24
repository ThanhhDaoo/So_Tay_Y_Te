import 'package:shared_preferences/shared_preferences.dart';
import '../../core/di/injection_container.dart';
import '../../domain/repositories/sync_repository.dart';
import '../datasources/local/app_preferences_datasource.dart';
import '../datasources/local/medical_local_datasource.dart';
import '../datasources/remote/medical_sync_remote_datasource.dart';

class SyncRepositoryImpl implements SyncRepository {
  final MedicalLocalDataSource localDataSource;
  final MedicalSyncRemoteDataSource remoteDataSource;
  final SharedPreferences? preferences;

  static const String _lastSyncKey = 'last_medical_sync_time_iso';

  SyncRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    this.preferences,
  });

  SharedPreferences? get _prefs => preferences ??
      (sl.isRegistered<SharedPreferences>() ? sl<SharedPreferences>() : null);

  @override
  Future<void> syncLocalToCloud() async {
    final activeUserId = sl.isRegistered<AppPreferencesDataSource>()
        ? await sl<AppPreferencesDataSource>().getSessionUserId()
        : null;
    final events = await localDataSource.getAllEvents(userId: activeUserId);
    if (events.isNotEmpty) {
      await remoteDataSource.uploadEvents(events);
    }
    await _saveSyncTime();
  }

  @override
  Future<void> syncCloudToLocal() async {
    final events = await remoteDataSource.fetchLatestEvents();
    for (final event in events) {
      await localDataSource.insertOrUpdateEvent(event);
    }
    if (events.isNotEmpty) {
      await _saveSyncTime();
    }
  }

  @override
  Future<void> syncBothWays() async {
    await syncLocalToCloud();
    await syncCloudToLocal();
  }

  @override
  Future<void> deleteRemoteEvent(String id) async {
    await remoteDataSource.deleteEvent(id);
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    final iso = _prefs?.getString(_lastSyncKey);
    if (iso != null && iso.isNotEmpty) {
      return DateTime.tryParse(iso);
    }
    return null;
  }

  Future<void> _saveSyncTime() async {
    await _prefs?.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }
}
