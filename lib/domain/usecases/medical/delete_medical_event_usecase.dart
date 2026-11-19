import '../../repositories/medical_record_repository.dart';

class DeleteMedicalEventUseCase {
  final MedicalRecordRepository repository;

  DeleteMedicalEventUseCase(this.repository);

  Future<void> call(String id) async {
    return await repository.deleteMedicalEvent(id);
  }
}
