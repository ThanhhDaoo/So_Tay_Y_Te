import '../entities/daily_health_task.dart';
import '../entities/daily_vital_log.dart';
import '../entities/doctor_contact.dart';
import '../entities/health_video.dart';
import '../entities/medication_popup_reminder.dart';
import '../entities/nutrition_item.dart';

abstract class ElderCareRepository {
  // 1. Huyết áp Hôm qua vs Hôm nay
  Future<YesterdayTodayBpComparison> getYesterdayTodayBpComparison({
    String? userId,
    String? memberId,
  });

  Future<DailyVitalLog> saveDailyBloodPressure({
    required int systolic,
    required int diastolic,
    int? heartRate,
    String source = 'manual',
    String? imagePath,
    String? note,
    String? userId,
    String? memberId,
    bool syncToMedicalTimeline = true,
  });

  // 2. Tiến độ thuốc & Việc cần làm trong ngày
  Future<TodayMedicationProgress> getTodayMedicationProgress({
    String? userId,
    String? memberId,
  });

  Future<void> markMedicationSlotTaken({
    required String slotId,
    required bool isTaken,
    String? userId,
    String? memberId,
  });

  Future<void> snoozeMedicationSlot({
    required MedicationPopupReminder reminder,
    Duration delay = const Duration(minutes: 15),
  });

  Future<List<DailyHealthTask>> getOrCreateTodayTasks({
    String? userId,
    String? memberId,
  });

  Future<void> toggleHealthTask({
    required DailyHealthTask task,
    String? userId,
    String? memberId,
  });

  Future<DailyHealthTask> addCustomHealthTask({
    required String title,
    String? subtitle,
    String? timeLabel,
    HealthTaskCategory category = HealthTaskCategory.custom,
    String? userId,
    String? memberId,
  });

  Future<void> deleteHealthTask(String taskId);

  // 3. Lưu ý đặc biệt về tiền sử bệnh
  Future<String> getSpecialHistoryNote({
    String? userId,
    String? memberId,
  });

  Future<void> saveSpecialHistoryNote({
    required String note,
    String? userId,
    String? memberId,
  });

  // 4. Danh bạ bác sĩ đã khám
  Future<List<DoctorContact>> getDoctors({
    String? userId,
    String? memberId,
  });

  Future<void> saveDoctor(DoctorContact doctor);
  Future<void> deleteDoctor(String doctorId);

  // 5. Video sức khỏe
  Future<List<HealthVideo>> getHealthVideos({String? category});
  Future<void> toggleSaveVideo(String videoId, bool isSaved);
  Future<void> markVideoWatched(String videoId);

  // 6. Dinh dưỡng & Thực phẩm chức năng
  Future<List<NutritionGuideline>> getNutritionGuidelines({
    String? userId,
    String? memberId,
    String? healthTag,
  });

  Future<void> saveNutritionGuideline(NutritionGuideline item);

  Future<List<DietarySupplement>> getSupplements({
    String? userId,
    String? memberId,
  });

  Future<void> saveSupplement(DietarySupplement item);
  Future<void> deleteSupplement(String supplementId);
}
