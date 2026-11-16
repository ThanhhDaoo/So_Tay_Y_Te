import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  /// Điền URL của dự án Supabase từ Dashboard (Settings -> API)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://vwdcavexizkqbzhzdjib.supabase.co',
  );

  /// Điền Anon Key (Public) từ Dashboard (Settings -> API)
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy_anon_key',
  );

  static bool _isInitialized = false;
  static bool get isConfigured =>
      _isInitialized &&
      !supabaseAnonKey.contains('dummy');

  static SupabaseClient? get client {
    if (!_isInitialized) return null;
    return Supabase.instance.client;
  }

  static Future<void> initialize() async {
    // Bỏ qua gọi mạng trong môi trường kiểm thử tự động offline
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      _isInitialized = true;
      debugPrint('[SupabaseConfig] Test environment: Giữ chế độ Local Sandbox.');
      return;
    }

    // Nếu chưa cấu hình Anon Key thật, bỏ qua để ứng dụng chạy chế độ Local-First an toàn
    if (supabaseAnonKey.contains('dummy')) {
      debugPrint('[SupabaseConfig] Project URL: $supabaseUrl đã sẵn sàng. Cần SUPABASE_ANON_KEY để kích hoạt kết nối đám mây.');
      return;
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: supabaseAnonKey,
      );
      _isInitialized = true;
      debugPrint('[SupabaseConfig] Kết nối Supabase Cloud thành công!');
    } catch (e) {
      debugPrint('[SupabaseConfig] Không thể kết nối Supabase, fallback về Local SQLite: $e');
    }
  }
}
