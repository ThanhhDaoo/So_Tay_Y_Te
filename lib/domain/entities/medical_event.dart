import 'prescription.dart';

enum MedicalEventType { generalCheckup, emergency, symptomLog, vaccination, surgery }

class MedicalEvent {
  final String id;
  final String? userId;
  final String title;
  final String? description;
  final DateTime date;
  final MedicalEventType type;
  final String? facilityName;
  final String? doctorName;
  final String? department;
  final String? diagnosis;
  final String? bloodPressure;
  final String? heartRate;
  final Prescription? prescription;
  final List<String> attachments;
  final String? hospitalFee;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MedicalEvent({
    required this.id,
    this.userId,
    required this.title,
    this.description,
    required this.date,
    required this.type,
    this.facilityName,
    this.doctorName,
    this.department,
    this.diagnosis,
    this.bloodPressure,
    this.heartRate,
    this.prescription,
    this.attachments = const [],
    this.hospitalFee,
    this.createdAt,
    this.updatedAt,
  });
}
