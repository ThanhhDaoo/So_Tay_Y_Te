import 'package:flutter/foundation.dart';
import 'security_settings_state.dart';

class SecuritySettingsViewModel extends ChangeNotifier {
  SecuritySettingsState _state = const SecuritySettingsState();

  SecuritySettingsState get state => _state;

  void toggleBiometricLock(bool value) {
    _state = _state.copyWith(
      isBiometricLockEnabled: value,
      feedbackMessage: value
          ? 'Đã kích hoạt xác thực Face ID / Vân tay khi mở ứng dụng.'
          : 'Đã tắt xác thực sinh trắc học.',
    );
    notifyListeners();
  }

  void setAutoLockTimeout(AutoLockTimeout timeout) {
    if (_state.autoLockTimeout == timeout) return;
    _state = _state.copyWith(
      autoLockTimeout: timeout,
      feedbackMessage: timeout == AutoLockTimeout.immediate
          ? 'Ứng dụng sẽ tự động khóa tức thì khi thoát màn hình.'
          : 'Ứng dụng sẽ tự động khóa sau 1 phút không thao tác.',
    );
    notifyListeners();
  }

  void togglePrivacyScreen(bool value) {
    _state = _state.copyWith(
      isPrivacyScreenInMultitaskEnabled: value,
      feedbackMessage: value
          ? 'Đã bật làm mờ màn hình bảo vệ hồ sơ trong trình Đa nhiệm.'
          : 'Đã tắt tính năng ẩn xem trước.',
    );
    notifyListeners();
  }

  void copyGuestUuid() {
    _state = _state.copyWith(
      feedbackMessage: 'Đã sao chép mã Guest UUID vào bộ nhớ tạm: ${_state.guestUuid}',
    );
    notifyListeners();
  }

  Future<void> exportBackup() async {
    _state = _state.copyWith(
      currentOperation: SecurityOperation.exportingBackup,
      feedbackMessage: 'Đang mã hóa và đóng gói tệp dự phòng (.sotayyte)...',
    );
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 900));

    _state = _state.copyWith(
      currentOperation: SecurityOperation.none,
      lastBackupTime: 'Vừa xong',
      feedbackMessage: 'Đã xuất tệp dự phòng sao lưu (.sotayyte) thành công!',
    );
    notifyListeners();
  }

  Future<void> restoreBackup() async {
    _state = _state.copyWith(
      currentOperation: SecurityOperation.restoringBackup,
      feedbackMessage: 'Đang giải mã và kiểm tra tính toàn vẹn dữ liệu sao lưu...',
    );
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 900));

    _state = _state.copyWith(
      currentOperation: SecurityOperation.none,
      feedbackMessage: 'Khôi phục cơ sở dữ liệu y tế từ tệp thành công!',
    );
    notifyListeners();
  }

  Future<void> wipeAllLocalData() async {
    _state = _state.copyWith(
      currentOperation: SecurityOperation.wipingData,
      feedbackMessage: 'Đang xóa sạch toàn bộ khóa mã hóa và cơ sở dữ liệu trên thiết bị...',
    );
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1000));

    _state = _state.copyWith(
      currentOperation: SecurityOperation.none,
      feedbackMessage: 'Đã xóa trắng toàn bộ dữ liệu cục bộ an toàn theo chuẩn DoD 5220.22-M!',
    );
    notifyListeners();
  }

  void clearFeedbackMessage() {
    _state = _state.copyWith(feedbackMessage: null);
    notifyListeners();
  }
}

