import 'package:flutter/material.dart';
import '../features/timeline/view/timeline_screen.dart';
import '../features/add_record/view/add_record_screen.dart';
import '../features/record_detail/view/record_detail_screen.dart';
import '../features/emergency_card/view/emergency_card_screen.dart';
import '../features/paywall/view/paywall_screen.dart';
import '../features/auth/view/login_screen.dart';
import '../features/auth/view/register_screen.dart';
import '../features/prescriptions/view/prescriptions_screen.dart';

class AppRoutes {
  static const String timeline = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String addRecord = '/add-record';
  static const String recordDetail = '/record-detail';
  static const String emergencyCard = '/emergency-card';
  static const String prescriptions = '/prescriptions';
  static const String paywall = '/paywall';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case timeline:
        return MaterialPageRoute(builder: (_) => const TimelineScreen());
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
      case paywall:
        return MaterialPageRoute(builder: (_) => const PaywallScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Không tìm thấy đường dẫn: ${settings.name}')),
          ),
        );
    }
  }
}
