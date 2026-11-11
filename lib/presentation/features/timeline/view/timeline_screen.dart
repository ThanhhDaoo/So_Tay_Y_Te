import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../domain/entities/medical_event.dart';
import '../../../routes/app_routes.dart';
import 'widgets/timeline_item_card.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final List<MedicalEvent> _events = [
    MedicalEvent(
      id: '1',
      title: 'Khám sức khỏe tổng quát',
      description: 'Huyết áp bình thường, men gan hơi cao nhẹ.',
      date: DateTime.now().subtract(const Duration(days: 2)),
      type: MedicalEventType.generalCheckup,
    ),
    MedicalEvent(
      id: '2',
      title: 'Tiêm chủng cúm mùa',
      description: 'Mũi nhắc lại hàng năm tại VNVC.',
      date: DateTime.now().subtract(const Duration(days: 15)),
      type: MedicalEventType.vaccination,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.contact_emergency),
            tooltip: 'Thẻ cấp cứu',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.emergencyCard),
          ),
          IconButton(
            icon: const Icon(Icons.star),
            tooltip: 'Nâng cấp Pro',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.paywall),
          ),
        ],
      ),
      body: _events.isEmpty
          ? const Center(
              child: Text('Chưa có dữ liệu y tế nào. Hãy tạo đợt khám đầu tiên!'),
            )
          : ListView.builder(
              itemCount: _events.length,
              itemBuilder: (context, index) {
                final event = _events[index];
                return TimelineItemCard(
                  event: event,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.recordDetail,
                      arguments: event.id,
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addRecord),
        icon: const Icon(Icons.add),
        label: const Text('Thêm hồ sơ'),
      ),
    );
  }
}
