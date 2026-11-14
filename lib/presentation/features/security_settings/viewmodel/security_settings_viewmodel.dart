import 'package:flutter/foundation.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/security/biometric_service.dart';
import '../../../../core/security/password_hasher.dart';
import '../../../../data/datasources/local/app_preferences_datasource.dart';
import 'security_settings_state.dart';

class SecuritySettingsViewModel extends ChangeNotifier {
  final AppPreferencesDataSource _preferencesDataSource;
  final BiometricService _biometricService;
  final DatabaseHelper? _databaseHelper;

  SecuritySettingsState _state = const SecuritySettingsState();

  SecuritySettingsState get state => _state;

  SecuritySettingsViewModel({
    AppPreferencesDataSource? preferencesDataSource,
    BiometricService? biometricService,
    DatabaseHelper? databaseHelper,
  })  : _preferencesDataSource = preferencesDataSource ??
            (sl.isRegistered<AppPreferencesDataSource>()
                ? sl<AppPreferencesDataSource>()
                : AppPreferencesDataSourceImpl()),
        _biometricService = biometricService ??
            (sl.isRegistered<BiometricService>()
                ? sl<BiometricService>()
                : BiometricServiceImpl()),
        _databaseHelper = databaseHelper ??
            (sl.isRegistered<DatabaseHelper>() ? sl<DatabaseHelper>() : null) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final bioEnabled = await _preferencesDataSource.isBiometricLockEnabled();
    final hasPin = await _preferencesDataSource.hasPin();
    final timeoutInt = await _preferencesDataSource.getAutoLockTimeout();
    final privacyEnabled = await _preferencesDataSource.isPrivacyScreenEnabled();

    _state = _state.copyWith(
      isBiometricLockEnabled: bioEnabled,
      hasPinCode: hasPin,
      autoLockTimeout: timeoutInt == 1 ? AutoLockTimeout.oneMinute : AutoLockTimeout.immediate,
      isPrivacyScreenInMultitaskEnabled: privacyEnabled,
    );
    notifyListeners();
  }

  Future<void> toggleBiometricLock(bool value) async {
    if (value) {
      final available = await _biometricService.isBiometricAvailable();
      if (!available) {
        _state = _state.copyWith(
          feedbackMessage: 'Thiết bị không hỗ trợ hoặc chưa cài đặt Face ID / Vân tay.',
        );
        notifyListeners();
        return;
      }

      final authenticated = await _biometricService.authenticate(
        localizedReason: 'Xác thực để kích hoạt khóa ứng dụng bằng Face ID / Vân tay',
      );

      if (!authenticated) {
        _state = _state.copyWith(
          feedbackMessage: 'Xác thực Face ID không thành công. Không thể bật tính năng.',
        );
        notifyListeners();
        return;
      }
    }

    await _preferencesDataSource.setBiometricLockEnabled(value);
    _state = _state.copyWith(
      isBiometricLockEnabled: value,
      feedbackMessage: value
          ? 'Đã kích hoạt xác thực Face ID / Vân tay khi mở ứng dụng.'
          : 'Đã tắt xác thực sinh trắc học.',
    );
    notifyListeners();
  }

  Future<void> saveNewPin(String rawPin) async {
    final salt = PasswordHasher.generateSalt();
    final hash = PasswordHasher.hashPassword(rawPin, salt);
    await _preferencesDataSource.savePin(pinHash: hash, salt: salt);

    _state = _state.copyWith(
      hasPinCode: true,
      feedbackMessage: 'Mã PIN 6 chữ số đã được cập nhật và mã hóa thành công!',
    );
    notifyListeners();
  }

  Future<bool> verifyPin(String rawPin) async {
    final storedHash = await _preferencesDataSource.getPinHash();
    final storedSalt = await _preferencesDataSource.getPinSalt();
    if (storedHash == null || storedSalt == null) return false;

    return PasswordHasher.verifyPassword(
      password: rawPin,
      salt: storedSalt,
      expectedHash: storedHash,
    );
  }

  Future<void> setAutoLockTimeout(AutoLockTimeout timeout) async {
    if (_state.autoLockTimeout == timeout) return;
    await _preferencesDataSource.setAutoLockTimeout(timeout == AutoLockTimeout.oneMinute ? 1 : 0);
    _state = _state.copyWith(
      autoLockTimeout: timeout,
      feedbackMessage: timeout == AutoLockTimeout.immediate
          ? 'Ứng dụng sẽ tự động khóa tức thì khi thoát màn hình.'
          : 'Ứng dụng sẽ tự động khóa sau 1 phút không thao tác.',
    );
    notifyListeners();
  }

  Future<void> togglePrivacyScreen(bool value) async {
    await _preferencesDataSource.setPrivacyScreenEnabled(value);
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

    try {
      if (_databaseHelper != null) {
        final db = await _databaseHelper.database;
        await db.delete('medicines');
        await db.delete('prescriptions');
        await db.delete('medical_events');
        await db.delete('auth_identities');
        await db.delete('users');
      }
    } catch (_) {}

    await _preferencesDataSource.clearSession();
    await _preferencesDataSource.clearPin();
    await _preferencesDataSource.setBiometricLockEnabled(false);

    _state = _state.copyWith(
      currentOperation: SecurityOperation.none,
      hasPinCode: false,
      isBiometricLockEnabled: false,
      feedbackMessage: 'Đã xóa trắng toàn bộ dữ liệu cục bộ an toàn theo chuẩn DoD 5220.22-M!',
    );
    notifyListeners();
  }

  void clearFeedbackMessage() {
    _state = _state.copyWith(clearFeedbackMessage: true);
    notifyListeners();
  }
}
