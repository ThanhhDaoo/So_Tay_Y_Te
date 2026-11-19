import '../entities/medical_event.dart';

abstract class MedicalRecordRepository {
  Future<List<MedicalEvent>> getMedicalTimeline({String? userId});
  Future<MedicalEvent?> getMedicalEventById(String id);
  Future<void> saveMedicalEvent(MedicalEvent event);
  Future<void> deleteMedicalEvent(String id);
  Future<String> exportHealthPdf();
}
