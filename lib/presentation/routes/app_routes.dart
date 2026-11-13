import 'package:flutter/material.dart';
import '../features/timeline/view/timeline_screen.dart';
import '../features/add_record/view/add_record_screen.dart';
import '../features/record_detail/view/record_detail_screen.dart';
import '../features/emergency_card/view/emergency_card_screen.dart';
import '../features/paywall/view/paywall_screen.dart';
import '../features/auth/view/login_screen.dart';
import '../features/auth/view/register_screen.dart';
import '../features/prescriptions/view/prescriptions_screen.dart';
import '../features/profile/view/profile_screen.dart';
import '../features/documents/view/documents_screen.dart';
import '../features/main_shell/view/main_shell_screen.dart';
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

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case timeline:
        return MaterialPageRoute(builder: (_) => const TimelineScreen());
      case mainShell:
        return MaterialPageRoute(builder: (_) => const MainShellScreen());
      case addRecord:
        return MaterialPageRoute(builder: (_) => const AddRecordScreen());
      case recordDetail:
        final recordId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => RecordDetailScreen(recordId: recordId ?? ''),
        );
      case emergencyCard:
        return MaterialPageRoute(builder: (_) => const EmergencyCardScreen());
      case prescriptions:
        return MaterialPageRoute(builder: (_) => const PrescriptionsScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case documents:
        return MaterialPageRoute(builder: (_) => const DocumentsScreen());
      case paywall:
        return MaterialPageRoute(builder: (_) => const PaywallScreen());
      case vitalReports:
      case vitalReport:
        return MaterialPageRoute(builder: (_) => const VitalReportsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Không tìm thấy đường dẫn: ${settings.name}')),
          ),
        );
    }
  }
}
