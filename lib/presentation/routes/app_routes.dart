import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../features/add_record/view/add_record_screen.dart';
import '../features/auth/view/login_screen.dart';
import '../features/auth/view/register_screen.dart';
import '../features/documents/view/documents_screen.dart';
import '../features/main_shell/view/main_shell_screen.dart';
import '../features/paywall/view/paywall_screen.dart';
import '../features/record_detail/view/record_detail_screen.dart';
import '../features/security_settings/view/app_lock_screen.dart';
import '../features/vital_reports/view/vital_reports_screen.dart';

class AppRoutes {
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

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case timeline:
        return MaterialPageRoute(
          builder: (_) => const MainShellScreen(initialIndex: 0),
        );
      case prescriptions:
        return MaterialPageRoute(
          builder: (_) => const MainShellScreen(initialIndex: 1),
        );
      case emergencyCard:
        return MaterialPageRoute(
          builder: (_) => const MainShellScreen(initialIndex: 2),
        );
      case profile:
        return MaterialPageRoute(
          builder: (_) => const MainShellScreen(initialIndex: 3),
        );
      case securitySettings:
      case AppRoutes.settings:
        return MaterialPageRoute(
          builder: (_) => const MainShellScreen(initialIndex: 4),
        );
      case mainShell:
        final initialIndex = settings.arguments as int? ?? 2;
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
        return CupertinoPageRoute(builder: (_) => const DocumentsScreen());
      case paywall:
        return CupertinoPageRoute(builder: (_) => const PaywallScreen());
      case vitalReports:
      case vitalReport:
        return CupertinoPageRoute(builder: (_) => const VitalReportsScreen());
      case appLock:
        final onUnlocked = settings.arguments as VoidCallback? ?? () {};
        return MaterialPageRoute(
          builder: (ctx) => AppLockScreen(
            onUnlocked: () {
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
