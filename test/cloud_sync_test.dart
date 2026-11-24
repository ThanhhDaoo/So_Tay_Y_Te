import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_tay_y_te/core/di/injection_container.dart';
import 'package:so_tay_y_te/data/datasources/local/medical_local_datasource.dart';
import 'package:so_tay_y_te/data/datasources/remote/medical_sync_remote_datasource.dart';
import 'package:so_tay_y_te/data/models/medical_event_model.dart';
import 'package:so_tay_y_te/data/repositories/sync_repository_impl.dart';
import 'package:so_tay_y_te/domain/entities/medical_event.dart';
import 'package:so_tay_y_te/domain/repositories/sync_repository.dart';
import 'package:so_tay_y_te/domain/usecases/sync/sync_both_ways_usecase.dart';
import 'package:so_tay_y_te/domain/usecases/sync/sync_local_to_cloud_usecase.dart';
import 'package:so_tay_y_te/presentation/features/security_settings/view/security_settings_screen.dart';
import 'package:so_tay_y_te/presentation/features/security_settings/view/widgets/cloud_sync_card.dart';
import 'package:so_tay_y_te/presentation/features/security_settings/viewmodel/security_settings_state.dart';
import 'package:so_tay_y_te/presentation/features/security_settings/viewmodel/security_settings_viewmodel.dart';

class MockTestMedicalLocalDataSource implements MedicalLocalDataSource {
  final List<MedicalEventModel> items = [];

  @override
  Future<List<MedicalEventModel>> getAllEvents({String? userId}) async => List.from(items);

  @override
  Future<MedicalEventModel?> getEventById(String id) async {
    return items.cast<MedicalEventModel?>().firstWhere((e) => e?.id == id, orElse: () => null);
  }

  @override
  Future<void> insertOrUpdateEvent(MedicalEventModel event) async {
    items.removeWhere((e) => e.id == event.id);
    items.add(event);
  }

  @override
  Future<void> deleteEvent(String id) async {
    items.removeWhere((e) => e.id == id);
  }
}

class MockTestMedicalSyncRemoteDataSource implements MedicalSyncRemoteDataSource {
  final List<MedicalEventModel> cloudStorage = [];
  bool uploadCalled = false;
  bool fetchCalled = false;

  @override
  Future<void> uploadEvents(List<MedicalEventModel> events) async {
    uploadCalled = true;
    for (final e in events) {
      cloudStorage.removeWhere((item) => item.id == e.id);
      cloudStorage.add(e);
    }
  }

  @override
  Future<List<MedicalEventModel>> fetchLatestEvents() async {
    fetchCalled = true;
    return List.from(cloudStorage);
  }

  @override
  Future<void> deleteEvent(String id) async {
    cloudStorage.removeWhere((item) => item.id == id);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences testPrefs;
  late MockTestMedicalLocalDataSource localDataSource;
  late MockTestMedicalSyncRemoteDataSource remoteDataSource;
  late SyncRepository syncRepository;

  final sampleEvent = MedicalEventModel(
    id: 'ev_sync_001',
    userId: 'usr_cloud_sync_test',
    title: 'Khám Viêm Họng',
    description: 'Ho khan có đờm',
    date: DateTime(2024, 11, 20),
    type: MedicalEventType.generalCheckup,
    facilityName: 'Bệnh viện Bạch Mai',
    doctorName: 'BS. Lê Hoài An',
    bloodPressure: '120/80',
    heartRate: '75',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    testPrefs = await SharedPreferences.getInstance();
    sl.reset();

    localDataSource = MockTestMedicalLocalDataSource();
    remoteDataSource = MockTestMedicalSyncRemoteDataSource();
    syncRepository = SyncRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      preferences: testPrefs,
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  group('Phase 3: Supabase Cloud Sync Domain & Repository Tests', () {
    test('syncLocalToCloud uploads local SQLite events to Supabase and persists sync timestamp', () async {
      await localDataSource.insertOrUpdateEvent(sampleEvent);

      final initialSyncTime = await syncRepository.getLastSyncTime();
      expect(initialSyncTime, isNull);

      await syncRepository.syncLocalToCloud();

      expect(remoteDataSource.uploadCalled, isTrue);
      expect(remoteDataSource.cloudStorage.length, equals(1));
      expect(remoteDataSource.cloudStorage.first.id, equals('ev_sync_001'));

      final updatedSyncTime = await syncRepository.getLastSyncTime();
      expect(updatedSyncTime, isNotNull);
    });

    test('syncCloudToLocal downloads cloud records and updates local SQLite database', () async {
      remoteDataSource.cloudStorage.add(sampleEvent);

      expect(localDataSource.items.isEmpty, isTrue);

      await syncRepository.syncCloudToLocal();

      expect(remoteDataSource.fetchCalled, isTrue);
      expect(localDataSource.items.length, equals(1));
      expect(localDataSource.items.first.title, equals('Khám Viêm Họng'));
    });

    test('SyncBothWaysUseCase coordinates bidirectional synchronization', () async {
      final useCase = SyncBothWaysUseCase(syncRepository);
      await localDataSource.insertOrUpdateEvent(sampleEvent);

      await useCase.call();

      expect(remoteDataSource.uploadCalled, isTrue);
      expect(remoteDataSource.fetchCalled, isTrue);
      final lastTime = await syncRepository.getLastSyncTime();
      expect(lastTime, isNotNull);
    });

    test('SyncLocalToCloudUseCase delegates to repository successfully', () async {
      final useCase = SyncLocalToCloudUseCase(syncRepository);
      await localDataSource.insertOrUpdateEvent(sampleEvent);

      await useCase.call();

      expect(remoteDataSource.uploadCalled, isTrue);
    });
  });

  group('Phase 3: SecuritySettingsViewModel Cloud Sync Integration Tests', () {
    test('ViewModel triggers syncCloudNow and updates cloudSyncTimeLabel and feedbackMessage', () async {
      final vm = SecuritySettingsViewModel(
        syncRepository: syncRepository,
      );

      await localDataSource.insertOrUpdateEvent(sampleEvent);
      expect(vm.state.isSyncingCloud, isFalse);

      await vm.syncCloudNow();

      expect(vm.state.isSyncingCloud, isFalse);
      expect(vm.state.lastCloudSyncTime, isNotNull);
      expect(vm.state.cloudSyncTimeLabel, equals('Vừa xong'));
      expect(vm.state.feedbackMessage, contains('Supabase thành công'));

      // Test toggle auto sync
      vm.toggleAutoCloudSync(false);
      expect(vm.state.isAutoCloudSyncEnabled, isFalse);
      expect(vm.state.feedbackMessage, contains('tắt tự động'));

      vm.toggleAutoCloudSync(true);
      expect(vm.state.isAutoCloudSyncEnabled, isTrue);
      expect(vm.state.feedbackMessage, contains('bật chế độ'));
    });
  });

  group('Phase 3: CloudSyncCard Widget Tests', () {
    testWidgets('CloudSyncCard renders status badge, auto-sync switch and triggers onSyncNow', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool syncTriggered = false;
      bool autoSyncToggled = false;

      final state = SecuritySettingsState(
        lastCloudSyncTime: DateTime.now(),
        isAutoCloudSyncEnabled: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CloudSyncCard(
                state: state,
                onSyncNow: () => syncTriggered = true,
                onToggleAutoSync: (val) => autoSyncToggled = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đồng Bộ Đám Mây Supabase'), findsOneWidget);
      expect(find.text('Cơ Sở Dữ Liệu Đám Mây PostgreSQL'), findsOneWidget);
      expect(find.text('Tự Động Đồng Bộ 2 Chiều'), findsOneWidget);
      expect(find.text('Đồng Bộ Ngay (2 Chiều)'), findsOneWidget);
      expect(find.textContaining('Lần đồng bộ gần nhất: Vừa xong'), findsOneWidget);

      // Tap sync button
      await tester.tap(find.text('Đồng Bộ Ngay (2 Chiều)'));
      await tester.pumpAndSettle();
      expect(syncTriggered, isTrue);

      // Toggle auto sync switch
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(autoSyncToggled, isTrue);
    });

    testWidgets('SecuritySettingsScreen displays CloudSyncCard in the settings flow', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: SecuritySettingsScreen(showBottomNav: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đồng Bộ Đám Mây Supabase'), findsOneWidget);
      expect(find.text('Đồng Bộ Ngay (2 Chiều)'), findsOneWidget);
    });
  });
}
