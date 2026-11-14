import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_tay_y_te/core/services/notification_service.dart';
import 'package:so_tay_y_te/presentation/features/prescriptions/view/prescriptions_screen.dart';
import 'package:so_tay_y_te/presentation/features/prescriptions/viewmodel/prescriptions_state.dart';
import 'package:so_tay_y_te/presentation/features/prescriptions/viewmodel/prescriptions_viewmodel.dart';

class ScheduledReminder {
  final int id;
  final String title;
  final String body;
  final int hour;
  final int minute;

  ScheduledReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
  });
}

class MockNotificationService implements NotificationService {
  final List<ScheduledReminder> scheduled = [];
  final List<String> instantAlerts = [];
  bool permissionsRequested = false;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermissions() async {
    permissionsRequested = true;
    return true;
  }

  @override
  Future<void> scheduleDailyMedicationReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    scheduled.add(ScheduledReminder(
      id: id,
      title: title,
      body: body,
      hour: hour,
      minute: minute,
    ));
  }

  @override
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    instantAlerts.add('$title: $body');
  }

  @override
  Future<void> cancelReminder(int id) async {
    scheduled.removeWhere((r) => r.id == id);
  }

  @override
  Future<void> cancelAllReminders() async {
    scheduled.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Module 3: Medication Notification & Reminder Engine Tests', () {
    late MockNotificationService mockService;
    late PrescriptionsViewModel viewModel;

    setUp(() async {
      mockService = MockNotificationService();
      viewModel = PrescriptionsViewModel(notificationService: mockService);
      // Wait for async initNotifications in constructor
      await Future.delayed(const Duration(milliseconds: 50));
    });

    test('Initializes notifications and schedules all daily dose slots', () async {
      expect(mockService.permissionsRequested, isTrue);
      // Expect 4 slots: morning (07:30), noon (12:30), afternoon (18:30), night (21:30)
      expect(mockService.scheduled.length, equals(4));

      final morning = mockService.scheduled.firstWhere((r) => r.title.contains('Cữ Sáng'));
      expect(morning.hour, equals(7));
      expect(morning.minute, equals(30));
      expect(morning.body, contains('Nexium Mups'));

      final afternoon = mockService.scheduled.firstWhere((r) => r.title.contains('Cữ Chiều'));
      expect(afternoon.hour, equals(18));
      expect(afternoon.minute, equals(30));
      expect(afternoon.body, contains('Klacid'));
    });

    test('testSendInstantReminder triggers immediate local notification', () async {
      await viewModel.testSendInstantReminder();

      expect(mockService.instantAlerts.length, equals(1));
      expect(mockService.instantAlerts.first, contains('Thử Chuông'));
      expect(viewModel.state.lastActionMessage, contains('chuông thông báo'));
    });

    test('markDoseTaken updates slot status and adherence percentage', () {
      final initialAdherence = viewModel.state.adherencePercent;
      expect(viewModel.state.slots.firstWhere((s) => s.id == 'afternoon').status,
          equals(DoseSlotStatus.dueSoon));

      viewModel.markDoseTaken('afternoon');

      final afternoonSlot = viewModel.state.slots.firstWhere((s) => s.id == 'afternoon');
      expect(afternoonSlot.status, equals(DoseSlotStatus.completed));
      expect(afternoonSlot.statusBadge, contains('Đã uống'));
      expect(viewModel.state.adherencePercent, greaterThanOrEqualTo(initialAdherence));
      expect(viewModel.state.lastActionMessage, contains('Đã ghi nhận uống thuốc'));
    });

    test('snoozeDose records snooze feedback message', () {
      viewModel.snoozeDose('afternoon');
      expect(viewModel.state.lastActionMessage, contains('15 phút nữa'));
    });

    testWidgets('PrescriptionsScreen renders reminder test button and triggers feedback',
        (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: PrescriptionsScreen(
            showBottomNav: false,
            viewModel: viewModel,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lịch nhắc thuốc hôm nay'), findsOneWidget);
      expect(find.text('Bấm để thử chuông báo thức uống thuốc ngay lập tức'), findsOneWidget);

      // Tap test button
      await tester.tap(find.text('Bấm để thử chuông báo thức uống thuốc ngay lập tức'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('chuông thông báo'), findsOneWidget);
    });
  });
}
