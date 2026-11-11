import '../../entities/medical_event.dart';
import '../../repositories/medical_record_repository.dart';

class GetMedicalTimelineUseCase {
  final MedicalRecordRepository repository;

  GetMedicalTimelineUseCase(this.repository);

  Future<List<MedicalEvent>> call() async {
    return await repository.getMedicalTimeline();
  }
}
