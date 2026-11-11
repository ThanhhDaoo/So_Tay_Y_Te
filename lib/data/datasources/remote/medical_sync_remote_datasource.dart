import '../../models/medical_event_model.dart';

abstract class MedicalSyncRemoteDataSource {
  Future<void> uploadEvents(List<MedicalEventModel> events);
  Future<List<MedicalEventModel>> fetchLatestEvents();
}

class MedicalSyncRemoteDataSourceImpl implements MedicalSyncRemoteDataSource {
  @override
  Future<void> uploadEvents(List<MedicalEventModel> events) async {}

  @override
  Future<List<MedicalEventModel>> fetchLatestEvents() async {
    return [];
  }
}
