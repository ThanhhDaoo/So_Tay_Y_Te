import 'prescription.dart';

enum MedicalEventType { generalCheckup, emergency, symptomLog, vaccination, surgery }

class MedicalEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final MedicalEventType type;
  final Prescription? prescription;
  final List<String> attachments;

  const MedicalEvent({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    required this.type,
    this.prescription,
    this.attachments = const [],
  });
}
