import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../domain/repositories/auth_repository.dart';
import 'emergency_card_state.dart';

/// ViewModel quản lý trạng thái và tương tác cho màn hình Thẻ Cấp Cứu Khẩn Cấp (ICE).
class EmergencyCardViewModel extends ChangeNotifier {
  EmergencyCardState _state = EmergencyCardState.initial();

  EmergencyCardState get state => _state;

  Future<void> loadProfile() async {
    try {
      if (sl.isRegistered<AuthRepository>()) {
        final session = await sl<AuthRepository>().getActiveSession();
        if (session != null) {
          String demographics = session.gender ?? 'Chưa rõ';
          if (session.dateOfBirth != null && session.dateOfBirth!.isNotEmpty) {
            demographics += ' • ${session.dateOfBirth}';
          }
          _state = _state.copyWith(
            patient: _state.patient.copyWith(
              fullName: session.fullName,
              demographics: demographics,
              bloodType: session.bloodType != null && session.bloodType!.isNotEmpty && session.bloodType != 'Chưa rõ'
                  ? session.bloodType!
                  : _state.patient.bloodType,
            ),
          );
          notifyListeners();
        }
      }
    } catch (_) {}
  }

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
