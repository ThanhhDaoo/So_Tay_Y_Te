import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../features/add_record/view/add_record_screen.dart';
import '../features/auth/view/login_screen.dart';
import '../features/auth/view/register_screen.dart';
import '../features/doctors/view/my_doctors_screen.dart';
import '../features/documents/view/documents_screen.dart';
import '../features/emergency_card/view/emergency_card_screen.dart';
import '../features/health_videos/view/health_videos_screen.dart';
import '../features/main_shell/view/main_shell_screen.dart';
import '../features/nutrition/view/nutrition_supplements_screen.dart';
import '../features/paywall/view/paywall_screen.dart';
import '../features/record_detail/view/record_detail_screen.dart';
import '../features/security_settings/view/app_lock_screen.dart';
import '../features/security_settings/view/security_settings_screen.dart';
import '../features/vital_reports/view/vital_reports_screen.dart';
import '../features/vitals_scan/view/blood_pressure_scan_screen.dart';

class AppRoutes {
  static const String home = '/home';
  static const String timeline = '/';
  static const String mainShell = '/main';
  static const String login = '/login';
  static const String register = '/register';
  static const String addRecord = '/add-record';
  static const String recordDetail = '/record-detail';
  static const String emergencyCard = '/emergency-card';
  static const String prescriptions = '/prescriptions';
  static const String profile = '/profile';
  static const String documents = '/documents';
  static const String paywall = '/paywall';
  static const String vitalReports = '/vital-reports';
  static const String vitalReport = '/vital-report';
  static const String securitySettings = '/security-settings';
  static const String settings = '/settings';
  static const String appLock = '/app-lock';
  static const String myDoctors = '/my-doctors';
  static const String healthVideos = '/health-videos';
  static const String nutritionSupplements = '/nutrition-supplements';
  static const String scanBloodPressure = '/scan-blood-pressure';

  /// Cờ kiểm soát màn hình khóa đang hiển thị, tránh mở lặp khi nhận lifecycle events
  static bool isAppLockShowing = false;

  /// Cờ đánh dấu đang mở Camera / Thư viện ảnh hệ thống để không khóa nhầm ứng dụng
  static bool isExternalPickerActive = false;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name ?? '';
    // Chặn các URI callback của Supabase OAuth (?code=..., ?error=..., #access_token=...) không bị đẩy thành màn hình lỗi
    if (routeName.startsWith('/?') ||
        routeName.startsWith('/#') ||
        routeName.startsWith('/login-callback') ||
        routeName.contains('error_description=') ||
        routeName.contains('access_token=')) {
      String? oauthError;
      final uri = Uri.tryParse(routeName);
      final errDesc = uri?.queryParameters['error_description'];
      if (errDesc != null && errDesc.isNotEmpty) {
        oauthError = errDesc.contains('Unable to exchange external code')
            ? 'Client ID và Client Secret Google trên Supabase chưa khớp nhau. Vui lòng dùng đúng cặp Client ID + Client Secret của cùng 1 Web Client.'
            : errDesc;
      }
      return MaterialPageRoute(
        builder: (_) => LoginScreen(initialOAuthError: oauthError),
      );
    }

    switch (settings.name) {
      case login:
        final identifier = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => LoginScreen(initialIdentifier: identifier),
        );
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case home:
        return MaterialPageRoute(
          builder: (_) => const MainShellScreen(initialIndex: 0),
        );
      case timeline:
        return MaterialPageRoute(
          builder: (_) => const MainShellScreen(initialIndex: 1),
        );
      case prescriptions:
        return MaterialPageRoute(
          builder: (_) => const MainShellScreen(initialIndex: 2),
        );
      case emergencyCard:
        final isLockedReadOnly = settings.arguments == true;
        return MaterialPageRoute(
          builder: (_) => EmergencyCardScreen(
            showBottomNav: false,
            readOnlyLockMode: isLockedReadOnly,
          ),
        );
      case profile:
        return MaterialPageRoute(
          builder: (_) => const MainShellScreen(initialIndex: 3),
        );
      case securitySettings:
      case AppRoutes.settings:
        return CupertinoPageRoute(
          builder: (_) => const SecuritySettingsScreen(showBottomNav: false),
        );
      case mainShell:
        final initialIndex = settings.arguments as int? ?? 0;
        return MaterialPageRoute(
          builder: (_) => MainShellScreen(initialIndex: initialIndex),
        );
      case addRecord:
        return CupertinoPageRoute(builder: (_) => const AddRecordScreen());
      case recordDetail:
        final recordId = settings.arguments as String?;
        return CupertinoPageRoute(
          builder: (_) => RecordDetailScreen(recordId: recordId ?? ''),
        );
      case documents:
        return CupertinoPageRoute(
          builder: (_) => const DocumentsScreen(showBottomNav: false),
        );
      case paywall:
        return CupertinoPageRoute(builder: (_) => const PaywallScreen());
      case vitalReports:
      case vitalReport:
        return CupertinoPageRoute(builder: (_) => const VitalReportsScreen());
      case myDoctors:
        return CupertinoPageRoute(builder: (_) => const MyDoctorsScreen());
      case healthVideos:
        return CupertinoPageRoute(builder: (_) => const HealthVideosScreen());
      case nutritionSupplements:
        return CupertinoPageRoute(
          builder: (_) => const NutritionSupplementsScreen(),
        );
      case scanBloodPressure:
        return CupertinoPageRoute(
          builder: (_) => const BloodPressureScanScreen(),
        );
      case appLock:
        final onUnlocked = settings.arguments as VoidCallback? ?? () {};
        return MaterialPageRoute(
          settings: settings,
          builder: (ctx) => AppLockScreen(
            onUnlocked: () {
              isAppLockShowing = false;
              Navigator.of(ctx).pop();
              onUnlocked();
            },
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Không tìm thấy đường dẫn: ${settings.name}')),
          ),
        );
    }
  }
}
