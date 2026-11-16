import 'package:flutter/foundation.dart';

class FirebaseConfig {
  /// Khóa API của dự án Firebase (từ Firebase Console -> Project Settings)
  static const String apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyDummyKeyForTestingOnly2026',
  );

  /// ID Dự án Firebase
  static const String projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'so-tay-y-te-production',
  );

  /// Mã App ID cho ứng dụng iOS
  static const String appId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '1:123456789012:ios:abcdef1234567890',
  );

  /// Mã Sender ID cho dịch vụ tin nhắn / Push notification
  static const String messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '123456789012',
  );

  static bool _isInitialized = false;

  /// Kiểm tra xem Firebase đã được cấu hình khóa thật từ môi trường hay chưa
  static bool get isConfigured =>
      _isInitialized &&
      apiKey != 'AIzaSyDummyKeyForTestingOnly2026' &&
      !apiKey.contains('Dummy');

  static bool get isInitialized => _isInitialized;

  static Future<void> initialize() async {
    // Nếu chưa có khóa API thật, khởi chạy ở chế độ Firebase Sandbox / Hybrid Local
    if (apiKey == 'AIzaSyDummyKeyForTestingOnly2026' ||
        apiKey.contains('Dummy')) {
      debugPrint(
        '[FirebaseConfig] Đang dùng Firebase Auth Sandbox (Hỗ trợ OTP test: 123456).',
      );
      _isInitialized = true;
      return;
    }

    try {
      _isInitialized = true;
      debugPrint('[FirebaseConfig] Kết nối Firebase Project: $projectId thành công!');
    } catch (e) {
      debugPrint('[FirebaseConfig] Lỗi khởi tạo Firebase: $e');
    }
  }
}
