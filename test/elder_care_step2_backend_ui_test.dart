import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_tay_y_te/core/services/ocr_service.dart';
import 'package:so_tay_y_te/data/datasources/local/app_preferences_datasource.dart';
import 'package:so_tay_y_te/data/datasources/local/elder_care_local_datasource.dart';
import 'package:so_tay_y_te/data/repositories/elder_care_repository_impl.dart';
import 'package:so_tay_y_te/domain/entities/daily_health_task.dart';
import 'package:so_tay_y_te/domain/entities/daily_vital_log.dart';
import 'package:so_tay_y_te/domain/entities/doctor_contact.dart';
import 'package:so_tay_y_te/domain/entities/health_video.dart';
import 'package:so_tay_y_te/domain/entities/nutrition_item.dart';
import 'package:so_tay_y_te/presentation/common_widgets/senior_40plus/senior_ui_kit.dart';

class _InMemoryElderCareLocalDataSource implements ElderCareLocalDataSource {
  final List<DailyVitalLog> _vitals = [];
  final List<DailyHealthTask> _tasks = [];
  final List<DoctorContact> _doctors = [];
  final List<HealthVideo> _videos = [];
  final List<NutritionGuideline> _nutrition = [];
  final List<DietarySupplement> _supplements = [];
  final Map<String, String> _notes = {};

  @override
  Future<DailyVitalLog?> getLatestVitalForDate({
    String? userId,
    required String memberId,
    required String dateKey,
  }) async {
    final matches = _vitals
        .where((v) => v.dateKey == dateKey && v.memberId == memberId)
        .toList()
      ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    return matches.isNotEmpty ? matches.first : null;
  }

  @override
  Future<List<DailyVitalLog>> getRecentVitalLogs({
    String? userId,
    required String memberId,
    int limit = 14,
  }) async {
    final matches = _vitals.where((v) => v.memberId == memberId).toList()
      ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    return matches.take(limit).toList();
  }

  @override
  Future<void> upsertVitalLog(DailyVitalLog log) async {
    _vitals.removeWhere((e) => e.id == log.id);
    _vitals.add(log);
  }

  @override
  Future<List<DailyHealthTask>> getTasksForDate({
    String? userId,
    required String memberId,
    required String dateKey,
  }) async {
    return _tasks
        .where((t) => t.dateKey == dateKey && t.memberId == memberId)
        .toList();
  }

  @override
  Future<void> upsertTask(DailyHealthTask task) async {
    _tasks.removeWhere((t) => t.id == task.id);
    _tasks.add(task);
  }

  @override
  Future<void> toggleTaskStatus(String taskId, bool completed) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      _tasks[idx] = _tasks[idx].copyWith(isCompleted: completed);
    }
  }

  @override
  Future<void> markTasksCompletedByCategory({
    String? userId,
    required String memberId,
    required String dateKey,
    required HealthTaskCategory category,
  }) async {
    for (int i = 0; i < _tasks.length; i++) {
      final t = _tasks[i];
      if (t.dateKey == dateKey && t.memberId == memberId && t.category == category) {
        _tasks[i] = t.copyWith(isCompleted: true);
      }
    }
  }

  @override
  Future<void> syncMedicationSlotTaskStatus({
    String? userId,
    required String memberId,
    required String dateKey,
    required String slotId,
    required bool completed,
  }) async {
    for (int i = 0; i < _tasks.length; i++) {
      final t = _tasks[i];
      if (t.dateKey == dateKey &&
          t.memberId == memberId &&
          t.linkedSlotId == slotId) {
        _tasks[i] = t.copyWith(isCompleted: completed);
      }
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
  }

  @override
  Future<String> getSpecialHistoryNote({
    String? userId,
    required String memberId,
  }) async =>
      _notes[memberId] ?? '';

  @override
  Future<void> saveSpecialHistoryNote({
    String? userId,
    required String memberId,
    required String note,
  }) async {
    _notes[memberId] = note;
  }

  @override
  Future<List<DoctorContact>> getDoctors({
    String? userId,
    required String memberId,
  }) async =>
      List.unmodifiable(_doctors);

  @override
  Future<void> upsertDoctor(DoctorContact doctor) async {
    _doctors.removeWhere((d) => d.id == doctor.id);
    _doctors.add(doctor);
  }

  @override
  Future<void> deleteDoctor(String doctorId) async {
    _doctors.removeWhere((d) => d.id == doctorId);
  }

  @override
  Future<List<HealthVideo>> getHealthVideos({String? category}) async =>
      List.unmodifiable(_videos);

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
      List.unmodifiable(_nutrition);

  @override
  Future<void> upsertNutritionGuideline(NutritionGuideline item) async {
    _nutrition.add(item);
  }

  @override
  Future<List<DietarySupplement>> getSupplements({
    String? userId,
    required String memberId,
  }) async =>
      List.unmodifiable(_supplements);

  @override
  Future<void> upsertSupplement(DietarySupplement item) async {
    _supplements.removeWhere((s) => s.id == item.id);
    _supplements.add(item);
  }

  @override
  Future<void> deleteSupplement(String supplementId) async {
    _supplements.removeWhere((s) => s.id == supplementId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bước 2 — BloodPressureOcrParser & ElderCareRepository', () {
    test('BloodPressureOcrParser extracts SYS, DIA, PULSE from Omron LCD & noisy OCR digits', () {
      const omronLcdText = '''
OMRON
SYS mmHg
13B
DIA mmHg
8S
PULSE /min
74
      ''';
      final parsed = BloodPressureOcrParser.parse(omronLcdText);
      expect(parsed.isAutoDetected, isTrue);
      expect(parsed.systolic, 138);
      expect(parsed.diastolic, 85);
      expect(parsed.pulse, 74);

      const verticalNumbersOnly = '''
2026 11:30
126
79
68
      ''';
      final parsed2 = BloodPressureOcrParser.parse(verticalNumbersOnly);
      expect(parsed2.isAutoDetected, isTrue);
      expect(parsed2.systolic, 126);
      expect(parsed2.diastolic, 79);
      expect(parsed2.pulse, 68);
    });

    test('ElderCareRepository syncs daily tasks, medication progress, BP comparison & doctors', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = AppPreferencesDataSourceImpl();
      final local = _InMemoryElderCareLocalDataSource();
      final repo = ElderCareRepositoryImpl(
        localDataSource: local,
        preferencesDataSource: prefs,
      );

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await local.upsertVitalLog(
        DailyVitalLog(
          id: 'bp_y',
          memberId: 'primary',
          dateKey: DailyVitalLog.formatDateKey(yesterday),
          measuredAt: yesterday,
          systolic: 132,
          diastolic: 84,
          heartRate: 76,
          statusLevel: DailyVitalLog.evaluateLevel(132, 84),
        ),
      );

      // Generate today's checklist & verify BP task starts unchecked
      final initialTasks = await repo.getOrCreateTodayTasks(memberId: 'primary');
      expect(initialTasks, isNotEmpty);
      expect(
        initialTasks.firstWhere((t) => t.category == HealthTaskCategory.bloodPressure).isCompleted,
        isFalse,
      );

      // Save today's BP -> auto completes BP task & compares with yesterday
      await repo.saveDailyBloodPressure(
        systolic: 122,
        diastolic: 78,
        heartRate: 70,
        memberId: 'primary',
      );
      final cmp = await repo.getYesterdayTodayBpComparison(memberId: 'primary');
      expect(cmp.yesterday?.systolic, 132);
      expect(cmp.today?.systolic, 122);
      expect(cmp.today?.statusLevel, BloodPressureLevel.normal);

      final updatedTasks = await repo.getOrCreateTodayTasks(memberId: 'primary');
      expect(
        updatedTasks.firstWhere((t) => t.category == HealthTaskCategory.bloodPressure).isCompleted,
        isTrue,
      );

      // Mark morning medication slot taken -> updates progress & linked task
      await repo.markMedicationSlotTaken(
        slotId: 'morning',
        isTaken: true,
        memberId: 'primary',
      );
      final medProgress = await repo.getTodayMedicationProgress(memberId: 'primary');
      expect(medProgress.completedSlots, 1);
      expect(medProgress.totalSlots, 3);

      // Save & read Doctor contact + Special History Note
      await repo.saveSpecialHistoryNote(
        note: 'Dị ứng Penicillin, đang uống Amlodipin 5mg buổi sáng.',
        memberId: 'primary',
      );
      expect(
        await repo.getSpecialHistoryNote(memberId: 'primary'),
        contains('Penicillin'),
      );

      await repo.saveDoctor(
        DoctorContact(
          id: 'doc_1',
          fullName: 'PGS.TS Nguyễn Văn Hùng',
          specialty: 'Tim mạch',
          hospitalName: 'BV Bạch Mai',
          phoneNumber: '0912345678',
          createdAt: DateTime.now(),
        ),
      );
      final docs = await repo.getDoctors(memberId: 'primary');
      expect(docs.length, 1);
      expect(docs.first.phoneNumber, '0912345678');
    });
  });

  group('Bước 2 — Bộ Widget 40+ Senior UI Kit Standards', () {
    testWidgets('SeniorBottomNavBar has strictly 4 tabs and SeniorActionButton >= 52px height',
        (tester) async {
      int selectedTab = 0;
      int bpValue = 125;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SeniorActionButton(
                    label: 'Cập nhật huyết áp',
                    icon: Icons.favorite_rounded,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 24),
                  SeniorNumberStepperField(
                    label: 'Huyết áp Tâm thu',
                    unit: 'mmHg',
                    value: bpValue,
                    onChanged: (v) => bpValue = v,
                  ),
                ],
              ),
            ),
            bottomNavigationBar: SeniorBottomNavBar(
              selectedIndex: selectedTab,
              onSelectTab: (idx) => selectedTab = idx,
            ),
          ),
        ),
      );

      expect(find.text('Trang chủ'), findsOneWidget);
      expect(find.text('Bệnh án'), findsOneWidget);
      expect(find.text('Thuốc uống'), findsOneWidget);
      expect(find.text('Tài khoản'), findsOneWidget);

      final btnSize = tester.getSize(find.byType(ElevatedButton).first);
      expect(btnSize.height, greaterThanOrEqualTo(52.0));

      await tester.tap(find.text('Tăng'));
      await tester.pump();
      expect(bpValue, 126);
    });
  });
}
