import '../../repositories/medical_record_repository.dart';

class ExportHealthPdfUseCase {
  final MedicalRecordRepository repository;

  ExportHealthPdfUseCase(this.repository);

  Future<String> call() async {
    return await repository.exportHealthPdf();
  }
}
