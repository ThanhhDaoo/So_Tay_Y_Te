import 'package:flutter/material.dart';
import '../../../../../domain/entities/medical_event.dart';
import '../../../../../core/utils/date_formatter.dart';

class TimelineItemCard extends StatelessWidget {
  final MedicalEvent event;
  final VoidCallback onTap;

  const TimelineItemCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(_getIconForType(event.type)),
        ),
        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${DateFormatter.formatToVietnamese(event.date)}${event.description != null ? '\n${event.description}' : ''}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  IconData _getIconForType(MedicalEventType type) {
    switch (type) {
      case MedicalEventType.generalCheckup:
        return Icons.medical_services;
      case MedicalEventType.emergency:
        return Icons.warning_amber_rounded;
      case MedicalEventType.symptomLog:
        return Icons.notes;
      case MedicalEventType.vaccination:
        return Icons.vaccines;
      case MedicalEventType.surgery:
        return Icons.local_hospital;
    }
  }
}
