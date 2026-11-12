import 'package:flutter/material.dart';
import 'prescriptions_state.dart';

/// ViewModel quản lý lịch nhắc uống thuốc và đơn thuốc đang điều trị.
class PrescriptionsViewModel extends ChangeNotifier {
  PrescriptionsState _state = PrescriptionsState.initial();

  PrescriptionsState get state => _state;

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
      lastActionMessage: 'Đã ghi nhận uống thuốc đúng giờ!',
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

