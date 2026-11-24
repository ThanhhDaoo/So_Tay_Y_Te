import 'prescription.dart';

enum MedicalEventType { generalCheckup, emergency, symptomLog, vaccination, surgery }

class MedicalEvent {
  final String id;
  final String? userId;
  final String memberId;
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
  final String? spo2;
  final String? temperature;
  final Prescription? prescription;
  final List<String> attachments;
  final String? hospitalFee;
  final String syncStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const MedicalEvent({
    required this.id,
    this.userId,
    this.memberId = 'primary',
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
    this.spo2,
    this.temperature,
    this.prescription,
    this.attachments = const [],
    this.hospitalFee,
    this.syncStatus = 'dirty',
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
}
