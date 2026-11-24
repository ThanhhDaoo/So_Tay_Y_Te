import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_tay_y_te/core/di/injection_container.dart';
import 'package:so_tay_y_te/data/datasources/local/medical_local_datasource.dart';
import 'package:so_tay_y_te/data/datasources/remote/medical_sync_remote_datasource.dart';
import 'package:so_tay_y_te/data/models/medical_event_model.dart';
import 'package:so_tay_y_te/data/repositories/sync_repository_impl.dart';
import 'package:so_tay_y_te/domain/entities/medical_event.dart';
import 'package:so_tay_y_te/domain/entities/medicine.dart';
import 'package:so_tay_y_te/domain/entities/prescription.dart';

class _InMemorySyncableLocalDataSource implements SyncableMedicalLocalDataSource {
  final Map<String, MedicalEventModel> _rows = {};

  @override
  Future<List<MedicalEventModel>> getAllEvents({String? userId, String? memberId}) async {
    return _rows.values.where((row) {
      if (row.deletedAt != null) return false;
      if (userId != null && userId.isNotEmpty && row.userId != userId) {
        return false;
      }
      if (memberId != null && memberId.isNotEmpty) {
        if (memberId == 'primary') {
          return row.memberId.isEmpty || row.memberId == 'primary';
        }
        return row.memberId == memberId;
      }
      return true;
    }).toList();
  }

  @override
  Future<MedicalEventModel?> getEventById(String id) async {
    final e = _rows[id];
    if (e == null || e.deletedAt != null) return null;
    return e;
  }

  @override
  Future<void> insertOrUpdateEvent(MedicalEventModel event) async {
    _rows[event.id] = event;
  }

  @override
  Future<void> deleteEvent(String id) async {
    final existing = _rows[id];
    if (existing == null) return;
    _rows[id] = MedicalEventModel(
      id: existing.id,
      userId: existing.userId,
      memberId: existing.memberId,
      title: existing.title,
      description: existing.description,
      date: existing.date,
      type: existing.type,
      facilityName: existing.facilityName,
      doctorName: existing.doctorName,
      department: existing.department,
      diagnosis: existing.diagnosis,
      bloodPressure: existing.bloodPressure,
      heartRate: existing.heartRate,
      spo2: existing.spo2,
      temperature: existing.temperature,
      prescription: existing.prescription,
      attachments: existing.attachments,
      hospitalFee: existing.hospitalFee,
      syncStatus: 'pending_delete',
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      deletedAt: DateTime.now(),
    );
  }

  @override
  Future<List<MedicalEventModel>> getPendingDeletedEvents({String? userId}) async {
    return _rows.values.where((row) {
      if (row.deletedAt == null) return false;
      if (userId != null && userId.isNotEmpty && row.userId != userId) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<void> purgeSoftDeletedEvent(String id) async {
    _rows.remove(id);
  }

  @override
  Future<void> markEventsSynced(List<String> ids) async {
    for (final id in ids) {
      final e = _rows[id];
      if (e != null) {
        _rows[id] = MedicalEventModel(
          id: e.id,
          userId: e.userId,
          memberId: e.memberId,
          title: e.title,
          description: e.description,
          date: e.date,
          type: e.type,
          facilityName: e.facilityName,
          doctorName: e.doctorName,
          department: e.department,
          diagnosis: e.diagnosis,
          bloodPressure: e.bloodPressure,
          heartRate: e.heartRate,
          spo2: e.spo2,
          temperature: e.temperature,
          prescription: e.prescription,
          attachments: e.attachments,
          hospitalFee: e.hospitalFee,
          syncStatus: 'synced',
          createdAt: e.createdAt,
          updatedAt: e.updatedAt,
          deletedAt: e.deletedAt,
        );
      }
    }
  }
}

class _InMemoryCloudSyncRemote implements MedicalSyncRemoteDataSource {
  final Map<String, MedicalEventModel> cloudByUuid = {};
  final List<String> deletedIds = [];

  @override
  Future<void> uploadEvents(List<MedicalEventModel> events) async {
    for (final e in events) {
      final uuid = MedicalEventModel.ensureValidUuid(e.id);
      cloudByUuid[uuid] = MedicalEventModel(
        id: uuid,
        userId: e.userId,
        memberId: e.memberId,
        title: e.title,
        description: e.description,
        date: e.date,
        type: e.type,
        facilityName: e.facilityName,
        doctorName: e.doctorName,
        department: e.department,
        diagnosis: e.diagnosis,
        bloodPressure: e.bloodPressure,
        heartRate: e.heartRate,
        spo2: e.spo2,
        temperature: e.temperature,
        prescription: e.prescription,
        attachments: e.attachments,
        hospitalFee: e.hospitalFee,
        syncStatus: 'synced',
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
      );
    }
  }

  @override
  Future<List<MedicalEventModel>> fetchLatestEvents() async {
    return cloudByUuid.values.toList();
  }

  @override
  Future<void> deleteEvent(String id) async {
    final uuid = MedicalEventModel.ensureValidUuid(id);
    deletedIds.add(uuid);
    cloudByUuid.remove(uuid);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _InMemorySyncableLocalDataSource localDataSource;
  late _InMemoryCloudSyncRemote remoteDataSource;
  late SyncRepositoryImpl syncRepository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();

    localDataSource = _InMemorySyncableLocalDataSource();
    remoteDataSource = _InMemoryCloudSyncRemote();
    final prefs = await SharedPreferences.getInstance();
    syncRepository = SyncRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      preferences: prefs,
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  group('Cloud Sync Schema, Tombstone & Last-Write-Wins Conflict Tests', () {
    test('ensureValidUuid converts legacy REC-* IDs deterministically to valid UUID and serializes JSONB payload', () {
      final uuid1 = MedicalEventModel.ensureValidUuid('REC-2026-0001');
      final uuid2 = MedicalEventModel.ensureValidUuid('REC-2026-0001');
      final uuidRegex = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      );

      expect(uuid1, equals(uuid2));
      expect(uuidRegex.hasMatch(uuid1), isTrue);

      final model = MedicalEventModel(
        id: 'REC-2026-0001',
        userId: 'usr_1',
        memberId: 'fam_child_1',
        title: 'Khám Nhi định kỳ',
        date: DateTime(2026, 5, 10),
        type: MedicalEventType.generalCheckup,
        spo2: '99',
        temperature: '36.7',
        prescription: Prescription(
          id: 'RX-01',
          doctorName: 'BS. Minh',
          issuedDate: DateTime(2026, 5, 10),
          durationDays: 7,
          medicines: const [
            Medicine(
              id: 'm1',
              name: 'Vitamin D3',
              dosage: '400 IU',
              frequency: 'Sáng 1 giọt',
            ),
          ],
        ),
        attachments: const ['assets/images/img_doc_blood_test.png'],
      );

      final payload = model.toSupabaseMap(overrideUserId: uuid1);
      expect(payload['id'], equals(uuid1));
      expect(payload['member_id'], equals('fam_child_1'));
      expect(payload['spo2'], equals('99'));
      expect(payload['temperature'], equals('36.7'));
      expect(payload['attachments'], isA<List<String>>());
      expect(payload['prescription_json'], isA<Map<String, dynamic>>());
    });

    test('soft-deleted local record flushes deletion to Cloud and is NOT resurrected during syncBothWays', () async {
      const eventUuid = '11111111-2222-4333-8444-555555555555';
      final initialEvent = MedicalEventModel(
        id: eventUuid,
        userId: 'usr_sync_1',
        memberId: 'primary',
        title: 'Khám Nội Tổng Quát',
        date: DateTime(2026, 3, 15),
        type: MedicalEventType.generalCheckup,
        createdAt: DateTime(2026, 3, 15, 9, 0),
        updatedAt: DateTime(2026, 3, 15, 9, 0),
      );

      await localDataSource.insertOrUpdateEvent(initialEvent);
      await syncRepository.syncLocalToCloud();
      expect(remoteDataSource.cloudByUuid.containsKey(eventUuid), isTrue);

      // Xóa offline (tạo tombstone pending_delete)
      await localDataSource.deleteEvent(eventUuid);
      final visibleAfterDelete = await localDataSource.getAllEvents(userId: 'usr_sync_1');
      expect(visibleAfterDelete, isEmpty);

      final tombstones = await localDataSource.getPendingDeletedEvents(userId: 'usr_sync_1');
      expect(tombstones.length, equals(1));

      // Đồng bộ 2 chiều: phải xóa trên Cloud thay vì tải ngược lại làm sống lại bệnh án
      await syncRepository.syncBothWays();

      expect(remoteDataSource.deletedIds, contains(eventUuid));
      expect(remoteDataSource.cloudByUuid.containsKey(eventUuid), isFalse);
      final afterSyncLocal = await localDataSource.getAllEvents(userId: 'usr_sync_1');
      expect(afterSyncLocal, isEmpty);
    });

    test('Last-Write-Wins conflict resolution keeps newer local edit over stale Cloud copy', () async {
      const conflictId = '22222222-3333-4444-8555-666666666666';

      // Bản cũ trên Cloud (10:00)
      remoteDataSource.cloudByUuid[conflictId] = MedicalEventModel(
        id: conflictId,
        userId: 'usr_lww',
        memberId: 'primary',
        title: 'Chẩn đoán cũ trên mây',
        date: DateTime(2026, 6, 1),
        type: MedicalEventType.generalCheckup,
        createdAt: DateTime(2026, 6, 1, 10, 0),
        updatedAt: DateTime(2026, 6, 1, 10, 0),
      );

      // Bản mới vừa sửa offline trên máy (11:30)
      await localDataSource.insertOrUpdateEvent(
        MedicalEventModel(
          id: conflictId,
          userId: 'usr_lww',
          memberId: 'primary',
          title: 'Chẩn đoán mới cập nhật trên máy',
          date: DateTime(2026, 6, 1),
          type: MedicalEventType.generalCheckup,
          createdAt: DateTime(2026, 6, 1, 10, 0),
          updatedAt: DateTime(2026, 6, 1, 11, 30),
        ),
      );

      await syncRepository.syncBothWays();

      final localAfter = await localDataSource.getEventById(conflictId);
      expect(localAfter?.title, equals('Chẩn đoán mới cập nhật trên máy'));
      expect(remoteDataSource.cloudByUuid[conflictId]?.title, equals('Chẩn đoán mới cập nhật trên máy'));
    });

    test('memberId strictly isolates primary account records from family member records', () async {
      await localDataSource.insertOrUpdateEvent(
        MedicalEventModel(
          id: '33333333-4444-4555-8666-777777777771',
          userId: 'usr_fam',
          memberId: 'primary',
          title: 'Hồ sơ Chủ tài khoản',
          date: DateTime(2026, 7, 1),
          type: MedicalEventType.generalCheckup,
        ),
      );
      await localDataSource.insertOrUpdateEvent(
        MedicalEventModel(
          id: '33333333-4444-4555-8666-777777777772',
          userId: 'usr_fam',
          memberId: 'fam_mother_01',
          title: 'Hồ sơ Mẹ ruột',
          date: DateTime(2026, 7, 2),
          type: MedicalEventType.vaccination,
        ),
      );

      final primaryRecords = await localDataSource.getAllEvents(
        userId: 'usr_fam',
        memberId: 'primary',
      );
      final motherRecords = await localDataSource.getAllEvents(
        userId: 'usr_fam',
        memberId: 'fam_mother_01',
      );

      expect(primaryRecords.length, equals(1));
      expect(primaryRecords.first.title, equals('Hồ sơ Chủ tài khoản'));
      expect(motherRecords.length, equals(1));
      expect(motherRecords.first.title, equals('Hồ sơ Mẹ ruột'));
    });
  });
}
