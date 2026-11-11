import '../../models/medical_event_model.dart';

abstract class MedicalLocalDataSource {
  Future<List<MedicalEventModel>> getAllEvents();
  Future<MedicalEventModel?> getEventById(String id);
  Future<void> insertOrUpdateEvent(MedicalEventModel event);
  Future<void> deleteEvent(String id);
}

class MedicalLocalDataSourceImpl implements MedicalLocalDataSource {
  @override
  Future<List<MedicalEventModel>> getAllEvents() async {
    // Truy vấn SQLite / Drift / Isar
    return [];
  }

  @override
  Future<MedicalEventModel?> getEventById(String id) async {
    return null;
  }

  @override
  Future<void> insertOrUpdateEvent(MedicalEventModel event) async {}

  @override
  Future<void> deleteEvent(String id) async {}
}
