import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_tay_y_te/core/di/injection_container.dart';
import 'package:so_tay_y_te/core/services/ocr_service.dart';
import 'package:so_tay_y_te/data/datasources/local/app_preferences_datasource.dart';
import 'package:so_tay_y_te/data/datasources/local/elder_care_local_datasource.dart';
import 'package:so_tay_y_te/data/repositories/elder_care_repository_impl.dart';
import 'package:so_tay_y_te/domain/entities/daily_health_task.dart';
import 'package:so_tay_y_te/domain/entities/daily_vital_log.dart';
import 'package:so_tay_y_te/domain/entities/doctor_contact.dart';
import 'package:so_tay_y_te/domain/entities/health_video.dart';
import 'package:so_tay_y_te/domain/entities/nutrition_item.dart';
import 'package:so_tay_y_te/domain/repositories/elder_care_repository.dart';
import 'package:so_tay_y_te/presentation/features/doctors/view/my_doctors_screen.dart';
import 'package:so_tay_y_te/presentation/features/health_videos/view/health_videos_screen.dart';
import 'package:so_tay_y_te/presentation/features/home/view/home_screen.dart';
import 'package:so_tay_y_te/presentation/features/home/viewmodel/home_viewmodel.dart';
import 'package:so_tay_y_te/presentation/features/medical_dossier/view/medical_dossier_screen.dart';
import 'package:so_tay_y_te/presentation/features/nutrition/view/nutrition_supplements_screen.dart';
import 'package:so_tay_y_te/presentation/features/vitals_scan/view/blood_pressure_scan_screen.dart';

class _FakeBpOcrService implements OcrService {
  @override
  Future<String?> pickImage({required ImageSource source}) async =>
      '/mock/bp_monitor.jpg';

  @override
  Future<ParsedPrescriptionResult?> processPrescriptionImage(String imagePath) async {
    return const ParsedPrescriptionResult(
      rawText: 'SYS 134\nDIA 84\nPUL 76',
      medicines: [],
    );
  }

  @override
  ParsedPrescriptionResult parseText(String text, {String? imagePath}) =>
      ParsedPrescriptionResult(rawText: text, medicines: const []);

  @override
  Future<void> dispose() async {}
}

class _SeededMemoryElderLocalDataSource implements ElderCareLocalDataSource {
  final List<DailyVitalLog> vitals = [
    DailyVitalLog(
      id: 'seed_y',
      memberId: 'primary',
      dateKey: DailyVitalLog.formatDateKey(
        DateTime.now().subtract(const Duration(days: 1)),
      ),
      measuredAt: DateTime.now().subtract(const Duration(days: 1)),
      systolic: 128,
      diastolic: 82,
      heartRate: 74,
      statusLevel: BloodPressureLevel.normal,
    ),
  ];
  final List<DailyHealthTask> tasks = [];
  final List<DoctorContact> doctors = [
    DoctorContact(
      id: 'doc_1',
      fullName: 'PGS.TS.BS Nguyễn Hoàng Việt',
      specialty: 'Tim mạch & Huyết áp',
      hospitalName: 'Bệnh viện Đại học Y Dược',
      phoneNumber: '0903128456',
      lastVisitDate: '15/10/2026',
      lastVisitNote: 'Duy trì Amlodipin 5mg buổi sáng.',
      isPrimaryDoctor: true,
      createdAt: DateTime.now(),
    ),
  ];
  final List<HealthVideo> videos = [
    HealthVideo(
      id: 'v_1',
      title: 'Bài tập Thở Chậm giúp ổn định Huyết áp tại nhà',
      category: 'Tim mạch & Huyết áp',
      durationLabel: '10 phút',
      thumbnailUrl: 'assets/images/img_profile_hero_portrait.png',
      videoUrl: 'https://example.com/video.mp4',
      instructorName: 'BS.CKI Hoàng Nam',
      description: 'Thư giãn thành mạch nhẹ nhàng.',
      keySteps: const ['Bước 1: Ngồi thẳng lưng', 'Bước 2: Hít vào 4 giây'],
      createdAt: DateTime.now(),
    ),
  ];
  final List<NutritionGuideline> nutrition = [
    NutritionGuideline(
      id: 'n_1',
      type: NutritionRuleType.shouldEat,
      healthTag: 'Huyết áp & Tim mạch',
      foodName: 'Cá hồi & Rau xanh đậm',
      recommendedAmount: '3 bữa / tuần',
      benefitOrRisk: 'Giàu Omega-3 và Kali tốt cho huyết áp.',
      createdAt: DateTime.now(),
    ),
    NutritionGuideline(
      id: 'n_2',
      type: NutritionRuleType.shouldAvoid,
      healthTag: 'Huyết áp & Tim mạch',
      foodName: 'Dưa muối mặn & Mì gói',
      recommendedAmount: 'Hạn chế tối đa',
      benefitOrRisk: 'Nhiều muối Natri gây tăng huyết áp.',
      createdAt: DateTime.now(),
    ),
  ];
  final List<DietarySupplement> supplements = [
    DietarySupplement(
      id: 's_1',
      productName: 'Dầu cá Omega-3 1000mg',
      category: 'Tim mạch',
      benefits: 'Giảm mỡ máu, tốt cho mắt.',
      dosageGuide: '1 viên sau ăn trưa',
      createdAt: DateTime.now(),
    ),
  ];
  String specialNote = '';

  @override
  Future<DailyVitalLog?> getLatestVitalForDate({
    String? userId,
    required String memberId,
    required String dateKey,
  }) async {
    final m = vitals.where((v) => v.dateKey == dateKey).toList();
    return m.isNotEmpty ? m.last : null;
  }

  @override
  Future<List<DailyVitalLog>> getRecentVitalLogs({
    String? userId,
    required String memberId,
    int limit = 14,
  }) async =>
      vitals;

  @override
  Future<void> upsertVitalLog(DailyVitalLog log) async => vitals.add(log);

  @override
  Future<List<DailyHealthTask>> getTasksForDate({
    String? userId,
    required String memberId,
    required String dateKey,
  }) async =>
      tasks.where((t) => t.dateKey == dateKey).toList();

  @override
  Future<void> upsertTask(DailyHealthTask task) async {
    tasks.removeWhere((t) => t.id == task.id);
    tasks.add(task);
  }

  @override
  Future<void> toggleTaskStatus(String taskId, bool completed) async {
    final i = tasks.indexWhere((t) => t.id == taskId);
    if (i != -1) tasks[i] = tasks[i].copyWith(isCompleted: completed);
  }

  @override
  Future<void> markTasksCompletedByCategory({
    String? userId,
    required String memberId,
    required String dateKey,
    required HealthTaskCategory category,
  }) async {}

  @override
  Future<void> syncMedicationSlotTaskStatus({
    String? userId,
    required String memberId,
    required String dateKey,
    required String slotId,
    required bool completed,
  }) async {}

  @override
  Future<void> deleteTask(String taskId) async {}

  @override
  Future<String> getSpecialHistoryNote({
    String? userId,
    required String memberId,
  }) async =>
      specialNote;

  @override
  Future<void> saveSpecialHistoryNote({
    String? userId,
    required String memberId,
    required String note,
  }) async {
    specialNote = note;
  }

  @override
  Future<List<DoctorContact>> getDoctors({
    String? userId,
    required String memberId,
  }) async =>
      doctors;

  @override
  Future<void> upsertDoctor(DoctorContact doctor) async => doctors.add(doctor);

  @override
  Future<void> deleteDoctor(String doctorId) async =>
      doctors.removeWhere((d) => d.id == doctorId);

  @override
  Future<List<HealthVideo>> getHealthVideos({String? category}) async => videos;

  @override
  Future<void> toggleSaveVideo(String videoId, bool isSaved) async {}

  @override
  Future<void> markVideoWatched(String videoId) async {}

  @override
  Future<List<NutritionGuideline>> getNutritionGuidelines({
    String? userId,
    required String memberId,
    String? healthTag,
  }) async =>
      nutrition;

  @override
  Future<void> upsertNutritionGuideline(NutritionGuideline item) async =>
      nutrition.add(item);

  @override
  Future<List<DietarySupplement>> getSupplements({
    String? userId,
    required String memberId,
  }) async =>
      supplements;

  @override
  Future<void> upsertSupplement(DietarySupplement item) async =>
      supplements.add(item);

  @override
  Future<void> deleteSupplement(String supplementId) async =>
      supplements.removeWhere((s) => s.id == supplementId);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ElderCareRepository elderRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    final prefs = AppPreferencesDataSourceImpl();
    elderRepo = ElderCareRepositoryImpl(
      localDataSource: _SeededMemoryElderLocalDataSource(),
      preferencesDataSource: prefs,
    );
    sl.registerSingleton<AppPreferencesDataSource>(prefs);
    sl.registerSingleton<ElderCareRepository>(elderRepo);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('HomeScreen renders 5 senior blocks and MedicationReminderPopup updates progress',
      (tester) async {
    tester.view.physicalSize = const Size(1284, 2778);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    HomeViewModel.hasAutoShownMedicationPopupThisSession = false;

    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(enableAutoMedicationPopup: true),
      ),
    );
    await tester.pumpAndSettle();

    // Auto medication reminder popup appears on first launch
    expect(find.textContaining('Nhắc Uống Thuốc'), findsOneWidget);
    expect(find.text('Đã uống xong cữ này'), findsOneWidget);
    expect(find.text('Nhắc lại sau (15 phút)'), findsOneWidget);

    await tester.tap(find.text('Đã uống xong cữ này'));
    await tester.pumpAndSettle();

    expect(find.text('Huyết áp hằng ngày'), findsOneWidget);
    expect(find.text('128/82'), findsOneWidget);
    expect(find.text('Cập nhật huyết áp'), findsOneWidget);
    expect(find.text('Chụp ảnh máy đo (Scan)'), findsOneWidget);

    // Scroll down to verify Medication Progress updated to 1/3 cữ on HomeScreen!
    await tester.scrollUntilVisible(
      find.text('Đã uống 1/3 cữ'),
      240,
    );
    expect(find.text('Đã uống 1/3 cữ'), findsOneWidget);
  });

  testWidgets('MedicalDossierScreen displays 3 ordered sections & SpecialHistoryNoticeCard',
      (tester) async {
    tester.view.physicalSize = const Size(1284, 2778);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: MedicalDossierScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1. Tổng quan sức khỏe'), findsOneWidget);
    expect(find.text('2. Tiền sử bệnh án & Lưu ý đặc biệt'), findsOneWidget);
    expect(find.text('LƯU Ý ĐẶC BIỆT KHI KHÁM BỆNH'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('3. Dòng thời gian bệnh án'),
      300,
    );
    expect(find.text('3. Dòng thời gian bệnh án'), findsOneWidget);
  });

  testWidgets('MyDoctorsScreen, HealthVideosScreen & NutritionSupplementsScreen render cleanly',
      (tester) async {
    tester.view.physicalSize = const Size(1284, 2778);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    // 1. MyDoctorsScreen
    await tester.pumpWidget(const MaterialApp(home: MyDoctorsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Thêm bác sĩ đã khám'), findsOneWidget);
    expect(find.textContaining('Nguyễn Hoàng Việt'), findsOneWidget);
    expect(find.textContaining('Gọi ngay'), findsOneWidget);

    // 2. HealthVideosScreen -> open Video Player
    await tester.pumpWidget(const MaterialApp(home: HealthVideosScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bài tập Thở Chậm'), findsOneWidget);
    await tester.tap(find.text('Mở bài tập này'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Trình Phát Bài Tập'), findsOneWidget);
    expect(find.text('Tạm dừng'), findsOneWidget);

    // 3. NutritionSupplementsScreen (2 tabs)
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        home: const NutritionSupplementsScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Thực phẩm NÊN ĂN'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -320));
    await tester.pumpAndSettle();
    expect(find.text('Thực phẩm NÊN KIÊNG / HẠN CHẾ'), findsOneWidget);

    await tester.tap(find.text('Thực phẩm chức năng'));
    await tester.pumpAndSettle();
    expect(find.text('Dầu cá Omega-3 1000mg'), findsOneWidget);
  });

  testWidgets('BloodPressureScanScreen scans monitor OCR and saves confirmed numbers',
      (tester) async {
    tester.view.physicalSize = const Size(1284, 2778);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  ctx,
                  MaterialPageRoute<bool>(
                    builder: (_) => BloodPressureScanScreen(
                      ocrService: _FakeBpOcrService(),
                      elderCareRepository: elderRepo,
                    ),
                  ),
                ),
                child: const Text('Open Scan'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Scan'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mở Camera chụp máy đo huyết áp'));
    await tester.pumpAndSettle();

    // Verify extracted SYS 134 / DIA 84 / PULSE 76 populated on big confirmation screen
    expect(find.text('134'), findsOneWidget);
    expect(find.text('84'), findsOneWidget);
    expect(find.text('76'), findsOneWidget);

    await tester.ensureVisible(find.text('Lưu vào hệ thống'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu vào hệ thống'));
    await tester.pumpAndSettle();

    final cmp = await elderRepo.getYesterdayTodayBpComparison();
    expect(cmp.today?.systolic, 134);
    expect(cmp.today?.diastolic, 84);
    expect(cmp.today?.heartRate, 76);
  });
}
