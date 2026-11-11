import '../../entities/medical_event.dart';
import '../../repositories/medical_record_repository.dart';

class SaveMedicalEventUseCase {
  final MedicalRecordRepository repository;

  SaveMedicalEventUseCase(this.repository);

  Future<void> call(MedicalEvent event) async {
    await repository.saveMedicalEvent(event);
  }
}
