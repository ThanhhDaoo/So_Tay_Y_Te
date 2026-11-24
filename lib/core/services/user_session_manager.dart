import 'package:flutter/foundation.dart';
import '../di/injection_container.dart';
import '../../domain/repositories/auth_repository.dart';

/// Notifier toàn cục quản lý ảnh đại diện, thông tin phiên người dùng và đồng bộ sự kiện dữ liệu
/// giữa các Tab trong IndexedStack (Hồ sơ, Bệnh án, Đơn thuốc, Thẻ ICE, Bảo mật).
class AppSessionNotifier extends ChangeNotifier {
  static final AppSessionNotifier instance = AppSessionNotifier._internal();
  AppSessionNotifier._internal();

  String? _avatarUrl;
  String? _fullName;
  bool _privacyScreenEnabled = true;
  int _medicalRecordsVersion = 0;
  int _profileVersion = 0;

  String? get avatarUrl => _avatarUrl;
  String? get fullName => _fullName;
  bool get privacyScreenEnabled => _privacyScreenEnabled;
  int get medicalRecordsVersion => _medicalRecordsVersion;
  int get profileVersion => _profileVersion;

  Future<void> initFromSession() async {
    try {
      if (sl.isRegistered<AuthRepository>()) {
        final auth = sl<AuthRepository>();
        final session = await auth.getActiveSession();
        if (session != null) {
          _avatarUrl = session.avatarUrl;
          _fullName = session.fullName;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[AppSessionNotifier] initFromSession error: $e');
    }
  }

  void notifyAvatarChanged(String newUrl) {
    _avatarUrl = newUrl;
    _profileVersion++;
    notifyListeners();
  }

  void notifyProfileChanged({String? fullName, String? avatarUrl}) {
    if (fullName != null) _fullName = fullName;
    if (avatarUrl != null) _avatarUrl = avatarUrl;
    _profileVersion++;
    notifyListeners();
  }

  void notifyMedicalRecordsChanged() {
    _medicalRecordsVersion++;
    notifyListeners();
  }

  void setPrivacyScreenEnabled(bool enabled) {
    if (_privacyScreenEnabled == enabled) return;
    _privacyScreenEnabled = enabled;
    notifyListeners();
  }

  void updateSession({String? avatarUrl, String? fullName}) {
    if (avatarUrl != null) _avatarUrl = avatarUrl;
    if (fullName != null) _fullName = fullName;
    _profileVersion++;
    notifyListeners();
  }
}
