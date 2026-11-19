import 'package:flutter/foundation.dart';
import '../di/injection_container.dart';
import '../../domain/repositories/auth_repository.dart';

/// Notifier toàn cục quản lý ảnh đại diện và thông tin phiên người dùng,
/// giúp đồng bộ tức thì trên toàn bộ thanh Header và các Tab khi đổi Avatar.
class AppSessionNotifier extends ChangeNotifier {
  static final AppSessionNotifier instance = AppSessionNotifier._internal();
  AppSessionNotifier._internal();

  String? _avatarUrl;
  String? _fullName;

  String? get avatarUrl => _avatarUrl;
  String? get fullName => _fullName;

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
    } catch (_) {}
  }

  void notifyAvatarChanged(String newUrl) {
    _avatarUrl = newUrl;
    notifyListeners();
  }

  void updateSession({String? avatarUrl, String? fullName}) {
    if (avatarUrl != null) _avatarUrl = avatarUrl;
    if (fullName != null) _fullName = fullName;
    notifyListeners();
  }
}
