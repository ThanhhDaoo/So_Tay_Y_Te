import '../../domain/entities/medical_event.dart';
import '../../domain/repositories/medical_record_repository.dart';
import '../datasources/local/medical_local_datasource.dart';
import '../models/medical_event_model.dart';

class MedicalRecordRepositoryImpl implements MedicalRecordRepository {
  final MedicalLocalDataSource localDataSource;

  MedicalRecordRepositoryImpl({required this.localDataSource});

  @override
  Future<List<MedicalEvent>> getMedicalTimeline() async {
    final models = await localDataSource.getAllEvents();
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
      title: event.title,
      description: event.description,
      date: event.date,
      type: event.type,
      prescription: event.prescription,
      attachments: event.attachments,
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
