import 'package:shared_preferences/shared_preferences.dart';
import '../../core/di/injection_container.dart';
import '../../domain/repositories/sync_repository.dart';
import '../datasources/local/app_preferences_datasource.dart';
import '../datasources/local/medical_local_datasource.dart';
import '../datasources/remote/medical_sync_remote_datasource.dart';
import '../models/medical_event_model.dart';

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

  Future<String?> _resolveActiveUserId() async {
    return sl.isRegistered<AppPreferencesDataSource>()
        ? await sl<AppPreferencesDataSource>().getSessionUserId()
        : null;
  }

  Future<Set<String>> _flushPendingDeletions(String? activeUserId) async {
    final deletedUuids = <String>{};
    if (localDataSource is! SyncableMedicalLocalDataSource) return deletedUuids;

    final localImpl = localDataSource as SyncableMedicalLocalDataSource;
    final tombstones = await localImpl.getPendingDeletedEvents(userId: activeUserId);
    for (final tomb in tombstones) {
      deletedUuids.add(tomb.id);
      deletedUuids.add(MedicalEventModel.ensureValidUuid(tomb.id));
      await remoteDataSource.deleteEvent(tomb.id);
      await localImpl.purgeSoftDeletedEvent(tomb.id);
    }
    return deletedUuids;
  }

  @override
  Future<void> syncLocalToCloud() async {
    final activeUserId = await _resolveActiveUserId();
    await _flushPendingDeletions(activeUserId);

    final events = await localDataSource.getAllEvents(userId: activeUserId);
    if (events.isNotEmpty) {
      await remoteDataSource.uploadEvents(events);
      if (localDataSource is SyncableMedicalLocalDataSource) {
        await (localDataSource as SyncableMedicalLocalDataSource)
            .markEventsSynced(events.map((e) => e.id).toList());
      }
    }
    await _saveSyncTime();
  }

  @override
  Future<void> syncCloudToLocal() async {
    final activeUserId = await _resolveActiveUserId();
    final deletedIds = await _flushPendingDeletions(activeUserId);

    final localEvents = await localDataSource.getAllEvents(userId: activeUserId);
    final localById = <String, MedicalEventModel>{};
    for (final loc in localEvents) {
      localById[loc.id] = loc;
      localById[MedicalEventModel.ensureValidUuid(loc.id)] = loc;
    }

    final remoteEvents = await remoteDataSource.fetchLatestEvents();
    for (final remote in remoteEvents) {
      if (deletedIds.contains(remote.id) ||
          deletedIds.contains(MedicalEventModel.ensureValidUuid(remote.id))) {
        continue;
      }

      final existingLocal =
          localById[remote.id] ?? localById[MedicalEventModel.ensureValidUuid(remote.id)];

      if (existingLocal != null) {
        final localUpdated = existingLocal.updatedAt ?? existingLocal.createdAt ?? existingLocal.date;
        final remoteUpdated = remote.updatedAt ?? remote.createdAt ?? remote.date;
        // Giải quyết xung đột theo Last-Write-Wins (không ghi đè bản sửa mới hơn trên máy bằng bản cũ từ Cloud)
        if (localUpdated.isAfter(remoteUpdated)) {
          continue;
        }
      }

      await localDataSource.insertOrUpdateEvent(remote);
    }

    if (remoteEvents.isNotEmpty) {
      await _saveSyncTime();
    }
  }

  @override
  Future<void> syncBothWays() async {
    final activeUserId = await _resolveActiveUserId();
    // 1. Đẩy toàn bộ lệnh xóa offline (tombstones) lên Cloud trước để không bao giờ hồi sinh bản ghi đã xóa
    final deletedIds = await _flushPendingDeletions(activeUserId);

    // 2. Lấy trạng thái hiện tại của cả Local và Cloud để phân giải xung đột theo `updated_at`
    final localEvents = await localDataSource.getAllEvents(userId: activeUserId);
    final remoteEvents = await remoteDataSource.fetchLatestEvents();

    final remoteByUuid = <String, MedicalEventModel>{
      for (final r in remoteEvents) MedicalEventModel.ensureValidUuid(r.id): r,
    };
    final localByUuid = <String, MedicalEventModel>{
      for (final l in localEvents) MedicalEventModel.ensureValidUuid(l.id): l,
    };

    final toUpload = <MedicalEventModel>[];
    for (final local in localEvents) {
      final uuid = MedicalEventModel.ensureValidUuid(local.id);
      final remote = remoteByUuid[uuid];
      if (remote == null) {
        toUpload.add(local);
      } else {
        final localTime = local.updatedAt ?? local.createdAt ?? local.date;
        final remoteTime = remote.updatedAt ?? remote.createdAt ?? remote.date;
        if (localTime.isAfter(remoteTime) || local.syncStatus == 'dirty') {
          if (!remoteTime.isAfter(localTime)) {
            toUpload.add(local);
          }
        }
      }
    }

    if (toUpload.isNotEmpty) {
      await remoteDataSource.uploadEvents(toUpload);
      if (localDataSource is SyncableMedicalLocalDataSource) {
        await (localDataSource as SyncableMedicalLocalDataSource)
            .markEventsSynced(toUpload.map((e) => e.id).toList());
      }
    }

    for (final remote in remoteEvents) {
      final uuid = MedicalEventModel.ensureValidUuid(remote.id);
      if (deletedIds.contains(remote.id) || deletedIds.contains(uuid)) {
        continue;
      }
      final local = localByUuid[uuid];
      if (local == null) {
        await localDataSource.insertOrUpdateEvent(remote);
      } else {
        final localTime = local.updatedAt ?? local.createdAt ?? local.date;
        final remoteTime = remote.updatedAt ?? remote.createdAt ?? remote.date;
        if (remoteTime.isAfter(localTime)) {
          await localDataSource.insertOrUpdateEvent(remote);
        }
      }
    }

    await _saveSyncTime();
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
