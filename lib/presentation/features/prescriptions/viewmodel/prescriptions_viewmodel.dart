import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/notification_service.dart';
import 'prescriptions_state.dart';

/// ViewModel quản lý lịch nhắc uống thuốc và đơn thuốc đang điều trị.
class PrescriptionsViewModel extends ChangeNotifier {
  final NotificationService _notificationService;
  PrescriptionsState _state = PrescriptionsState.initial();

  PrescriptionsState get state => _state;

  PrescriptionsViewModel({NotificationService? notificationService})
      : _notificationService = notificationService ??
            (sl.isRegistered<NotificationService>()
                ? sl<NotificationService>()
                : NotificationServiceImpl()) {
    initNotifications();
  }

  Future<void> initNotifications() async {
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
    await scheduleAllReminders();
  }

  Future<void> scheduleAllReminders() async {
    for (final slot in _state.slots) {
      final parts = slot.timeLabel.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]) ?? 8;
        final minute = int.tryParse(parts[1]) ?? 0;
        final medsSummary = slot.medications
            .map((m) => '${m.name} (${m.instruction})')
            .join(', ');

        await _notificationService.scheduleDailyMedicationReminder(
          id: slot.id.hashCode.abs() % 100000,
          title: '🔔 Nhắc nhở uống thuốc: ${slot.title} (${slot.timeLabel})',
          body: medsSummary.isNotEmpty
              ? medsSummary
              : 'Đã đến giờ uống thuốc theo phác đồ điều trị.',
          hour: hour,
          minute: minute,
        );
      }
    }
  }

  Future<void> testSendInstantReminder() async {
    await _notificationService.showInstantNotification(
      id: 99999,
      title: '🔔 [Thử Chuông] Nhắc Nhở Uống Thuốc Sổ Tay Y Tế',
      body: 'Klacid (Clarithromycin) 500mg - 1 viên. Uống sau ăn no.',
    );
    _state = _state.copyWith(
      lastActionMessage:
          'Đã phát chuông thông báo thử nghiệm thành công! Kiểm tra thanh thông báo.',
    );
    notifyListeners();
  }

  /// Đánh dấu một cữ thuốc đã uống.
  void markDoseTaken(String slotId) {
    final updated = _state.slots.map((slot) {
      if (slot.id != slotId) return slot;
      return slot.copyWith(
        status: DoseSlotStatus.completed,
        statusBadge: 'Đã uống vừa xong',
      );
    }).toList();

    final completed =
        updated.where((s) => s.status == DoseSlotStatus.completed).length;
    final percent = ((completed / updated.length) * 100).round().clamp(0, 100);

    _state = _state.copyWith(
      slots: updated,
      adherencePercent: percent > _state.adherencePercent
          ? percent
          : _state.adherencePercent,
      lastActionMessage:
          'Đã ghi nhận uống thuốc đúng giờ! Chỉ số tuân thủ tăng lên $percent%',
    );
    notifyListeners();
  }

  /// Hoãn nhắc uống thuốc thêm 15 phút.
  void snoozeDose(String slotId) {
    _state = _state.copyWith(
      lastActionMessage: 'Sẽ nhắc lại cữ thuốc sau 15 phút nữa.',
    );
    notifyListeners();
  }

  void notifyUser(String message) {
    _state = _state.copyWith(lastActionMessage: message);
    notifyListeners();
  }

  void clearActionMessage() {
    if (_state.lastActionMessage == null) return;
    _state = _state.copyWith(clearActionMessage: true);
    notifyListeners();
  }
}
