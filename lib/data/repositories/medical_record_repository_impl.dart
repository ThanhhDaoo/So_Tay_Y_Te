import '../../domain/entities/medical_event.dart';
import '../../domain/repositories/medical_record_repository.dart';
import '../datasources/local/medical_local_datasource.dart';
import '../models/medical_event_model.dart';

class MedicalRecordRepositoryImpl implements MedicalRecordRepository {
  final MedicalLocalDataSource localDataSource;

  MedicalRecordRepositoryImpl({required this.localDataSource});

  @override
  Future<List<MedicalEvent>> getMedicalTimeline({String? userId}) async {
    final models = await localDataSource.getAllEvents(userId: userId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<MedicalEvent?> getMedicalEventById(String id) async {
    final model = await localDataSource.getEventById(id);
    return model?.toEntity();
  }

  @override
  Future<void> saveMedicalEvent(MedicalEvent event) async {
    final model = MedicalEventModel(
      id: event.id,
      userId: event.userId,
      title: event.title,
      description: event.description,
      date: event.date,
      type: event.type,
      facilityName: event.facilityName,
      doctorName: event.doctorName,
      department: event.department,
      diagnosis: event.diagnosis,
      bloodPressure: event.bloodPressure,
      heartRate: event.heartRate,
      prescription: event.prescription,
      attachments: event.attachments,
      hospitalFee: event.hospitalFee,
      createdAt: event.createdAt,
      updatedAt: event.updatedAt,
    );
    await localDataSource.insertOrUpdateEvent(model);
  }

  @override
  Future<void> deleteMedicalEvent(String id) async {
    await localDataSource.deleteEvent(id);
  }

  @override
  Future<String> exportHealthPdf() async {
    // Logic render và lưu file PDF
    return '/storage/health_summary.pdf';
  }
}
