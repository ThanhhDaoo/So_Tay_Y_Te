import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  /// Điền URL của dự án Supabase từ Dashboard (Settings -> API)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xyzcompany.supabase.co',
  );

  /// Điền Anon Key (Public) từ Dashboard (Settings -> API)
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy_anon_key',
  );

  static bool _isInitialized = false;
  static bool get isConfigured =>
      _isInitialized &&
      supabaseUrl != 'https://xyzcompany.supabase.co' &&
      !supabaseAnonKey.contains('dummy');

  static SupabaseClient? get client {
    if (!_isInitialized) return null;
    return Supabase.instance.client;
  }

  static Future<void> initialize() async {
    // Nếu chưa cấu hình URL thật, bỏ qua để ứng dụng chạy chế độ Local-First an toàn
    if (supabaseUrl == 'https://xyzcompany.supabase.co' ||
        supabaseAnonKey.contains('dummy')) {
      debugPrint('[SupabaseConfig] Đang dùng CSDL Cục bộ (Local-First). Cấu hình SUPABASE_URL để kết nối đám mây.');
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
