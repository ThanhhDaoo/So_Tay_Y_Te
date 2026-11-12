import 'package:flutter/material.dart';
import 'emergency_card_state.dart';

/// ViewModel quản lý trạng thái và tương tác cho màn hình Thẻ Cấp Cứu Khẩn Cấp (ICE).
class EmergencyCardViewModel extends ChangeNotifier {
  EmergencyCardState _state = EmergencyCardState.initial();

  EmergencyCardState get state => _state;

  /// Bật/tắt hiển thị thẻ ICE trên màn hình khóa.
  void toggleLockScreenWidget() {
    final nextValue = !_state.isLockScreenWidgetEnabled;
    _state = _state.copyWith(
      isLockScreenWidgetEnabled: nextValue,
      lastActionMessage: nextValue
          ? 'Đã bật hiển thị thẻ ICE trên màn hình khóa 24/7'
          : 'Đã tắt hiển thị thẻ ICE trên màn hình khóa',
    );
    notifyListeners();
  }

  /// Chuyển tab trên thanh điều hướng dưới cùng.
  void selectNavIndex(int index) {
    if (_state.selectedNavIndex == index) return;
    _state = _state.copyWith(selectedNavIndex: index);
    notifyListeners();
  }

  /// Kích hoạt gọi người thân khẩn cấp (ICE).
  void callPrimaryContact() {
    final c = _state.primaryContact;
    _state = _state.copyWith(
      lastActionMessage: 'Đang kết nối cuộc gọi tới ${c.name} (${c.phone})...',
    );
    notifyListeners();
  }

  /// Kích hoạt gọi bác sĩ điều trị.
  void callDoctor() {
    final c = _state.doctorContact;
    _state = _state.copyWith(
      lastActionMessage: 'Đang kết nối cuộc gọi tới ${c.name} (${c.phone})...',
    );
    notifyListeners();
  }

  /// Kích hoạt gọi tổng đài cấp cứu 115.
  void callEmergency115() {
    _state = _state.copyWith(
      lastActionMessage: 'Đang gọi Tổng đài Cấp cứu Quốc gia 115...',
    );
    notifyListeners();
  }

  void clearActionMessage() {
    if (_state.lastActionMessage == null) return;
    _state = _state.copyWith(clearActionMessage: true);
    notifyListeners();
  }
}
