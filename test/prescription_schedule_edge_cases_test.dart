import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_tay_y_te/core/di/injection_container.dart';
import 'package:so_tay_y_te/core/services/notification_service.dart';
import 'package:so_tay_y_te/domain/entities/medical_event.dart';
import 'package:so_tay_y_te/domain/entities/medicine.dart';
import 'package:so_tay_y_te/domain/entities/prescription.dart';
import 'package:so_tay_y_te/domain/repositories/medical_record_repository.dart';
import 'package:so_tay_y_te/presentation/features/prescriptions/viewmodel/prescriptions_state.dart';
import 'package:so_tay_y_te/presentation/features/prescriptions/viewmodel/prescriptions_viewmodel.dart';

class _SpyNotificationService implements NotificationService {
  int dailyCalls = 0;
  int oneTimeCalls = 0;
  Duration? lastOneTimeDelay;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> scheduleDailyMedicationReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    dailyCalls++;
  }

  @override
  Future<void> scheduleOneTimeMedicationReminder({
    required int id,
    required String title,
    required String body,
    required Duration delay,
  }) async {
    oneTimeCalls++;
    lastOneTimeDelay = delay;
  }

  @override
  Future<void> cancelReminder(int id) async {}

  @override
  Future<void> cancelAllReminders() async {}
}

class _StubMedicalRecordRepository implements MedicalRecordRepository {
  final List<MedicalEvent> events;
  _StubMedicalRecordRepository(this.events);

  @override
  Future<List<MedicalEvent>> getMedicalTimeline({String? userId, String? memberId}) async =>
      events;

  @override
  Future<MedicalEvent?> getMedicalEventById(String id) async =>
      events.where((e) => e.id == id).firstOrNull;

  @override
  Future<void> saveMedicalEvent(MedicalEvent event) async => events.add(event);

  @override
  Future<void> deleteMedicalEvent(String id) async =>
      events.removeWhere((e) => e.id == id);

  @override
  Future<String> exportHealthPdf() async => '/tmp/export.pdf';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  group('Prescription Slot Classification, Cross-Year Date Math & Undo/Snooze Tests', () {
    test('Night-only medication ("Tối 1 lần/ngày trước khi đi ngủ") is ONLY placed in nightMeds, never morningMeds', () {
      final morning = <MedicationItem>[];
      final noon = <MedicationItem>[];
      final afternoon = <MedicationItem>[];
      final night = <MedicationItem>[];

      PrescriptionsViewModel.classifyMedicineIntoSlots(
        medicine: const Medicine(
          id: 'med_atorvastatin',
          name: 'Atorvastatin 20mg',
          dosage: '1 viên',
          frequency: 'Tối 1 lần/ngày trước khi đi ngủ',
        ),
        morningMeds: morning,
        noonMeds: noon,
        afternoonMeds: afternoon,
        nightMeds: night,
      );

      expect(morning, isEmpty);
      expect(noon, isEmpty);
      expect(afternoon, isEmpty);
      expect(night.length, equals(1));
      expect(night.first.name, equals('Atorvastatin 20mg'));
    });

    test('Cross-month/cross-year prescription duration formats endDate cleanly (25/12/2026 + 14 days = 08/01/2027, never 39/12)', () async {
      final spyNotif = _SpyNotificationService();
      final start = DateTime(2026, 12, 25);
      final end = start.add(const Duration(days: 14));
      final formattedEnd =
          '${end.day.toString().padLeft(2, "0")}/${end.month.toString().padLeft(2, "0")}/${end.year}';
      expect(formattedEnd, equals('08/01/2027'));

      final now = DateTime.now();
      final repo = _StubMedicalRecordRepository([
        MedicalEvent(
          id: '44444444-5555-4666-8777-888888888888',
          title: 'Đơn ngoại trú cuối tháng',
          date: now,
          type: MedicalEventType.generalCheckup,
          prescription: Prescription(
            id: 'rx_active',
            doctorName: 'BS. Trần Thanh',
            issuedDate: now,
            durationDays: 10,
            status: 'active',
            medicines: const [
              Medicine(
                id: 'm_night',
                name: 'Montelukast 10mg',
                dosage: '1 viên',
                frequency: 'Uống tối trước khi ngủ',
              ),
            ],
          ),
        ),
      ]);

      final vm = PrescriptionsViewModel(
        notificationService: spyNotif,
        repository: repo,
      );
      await vm.loadFromRepository();

      expect(vm.state.slots.length, equals(1));
      expect(vm.state.slots.first.id, equals('night'));
      expect(vm.state.activePlan?.totalDays, equals(10));
      vm.dispose();
    });

    test('Expired prescription from 6 months ago does not schedule active daily alarms', () async {
      final spyNotif = _SpyNotificationService();
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
      final repo = _StubMedicalRecordRepository([
        MedicalEvent(
          id: '55555555-6666-4777-8888-999999999999',
          title: 'Đơn cũ đã hết hạn',
          date: sixMonthsAgo,
          type: MedicalEventType.generalCheckup,
          prescription: Prescription(
            id: 'rx_old',
            doctorName: 'BS. Cũ',
            issuedDate: sixMonthsAgo,
            durationDays: 7,
            status: 'active',
            medicines: const [
              Medicine(
                id: 'm_old',
                name: 'Amoxicillin 500mg',
                dosage: '1 viên',
                frequency: 'Ngày 2 lần sáng tối',
              ),
            ],
          ),
        ),
      ]);

      final vm = PrescriptionsViewModel(
        notificationService: spyNotif,
        repository: repo,
      );
      await vm.loadFromRepository();

      expect(vm.state.slots, isEmpty);
      vm.dispose();
    });

    test('markDoseTaken supports Undo on second tap and snoozeDose schedules a one-time 15m reminder', () async {
      final spyNotif = _SpyNotificationService();
      final initialState = PrescriptionsState.initial().copyWith(
        planSubtitle: 'Phác đồ test',
        adherencePercent: 0,
        slots: const [
          MedicationDoseSlot(
            id: 'morning',
            title: 'Cữ Sáng',
            timeLabel: '07:30',
            status: DoseSlotStatus.upcoming,
            statusBadge: 'Chưa đến giờ',
            slotIconAsset: 'assets/icons/ic_rx_sun_morning.svg',
            medications: [
              MedicationItem(
                name: 'Esomeprazole 40mg',
                instruction: '1 viên • Trước ăn sáng',
                iconAsset: 'assets/icons/ic_rx_med_bottle.svg',
              ),
            ],
          ),
        ],
      );

      final vm = PrescriptionsViewModel(
        notificationService: spyNotif,
        initialState: initialState,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Tap 1: Mark completed -> 100%
      vm.markDoseTaken('morning');
      expect(vm.state.slots.first.status, equals(DoseSlotStatus.completed));
      expect(vm.state.adherencePercent, equals(100));

      // Tap 2: Undo -> back to upcoming & 0%
      vm.markDoseTaken('morning');
      expect(vm.state.slots.first.status, equals(DoseSlotStatus.upcoming));
      expect(vm.state.adherencePercent, equals(0));

      // Snooze: must schedule one-time 15-minute notification, NOT daily repeating alarm
      final dailyBeforeSnooze = spyNotif.dailyCalls;
      vm.snoozeDose('morning');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(spyNotif.oneTimeCalls, equals(1));
      expect(spyNotif.lastOneTimeDelay, equals(const Duration(minutes: 15)));
      expect(spyNotif.dailyCalls, equals(dailyBeforeSnooze));
      vm.dispose();
    });
  });
}
