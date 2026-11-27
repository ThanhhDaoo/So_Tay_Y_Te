import 'package:uuid/uuid.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/user_session_manager.dart';
import '../../domain/entities/daily_health_task.dart';
import '../../domain/entities/daily_vital_log.dart';
import '../../domain/entities/doctor_contact.dart';
import '../../domain/entities/health_video.dart';
import '../../domain/entities/medical_event.dart';
import '../../domain/entities/medication_popup_reminder.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/nutrition_item.dart';
import '../../domain/repositories/elder_care_repository.dart';
import '../../domain/repositories/medical_record_repository.dart';
import '../datasources/local/app_preferences_datasource.dart';
import '../datasources/local/elder_care_local_datasource.dart';

class ElderCareRepositoryImpl implements ElderCareRepository {
  final ElderCareLocalDataSource localDataSource;
  final MedicalRecordRepository? medicalRecordRepository;
  final AppPreferencesDataSource? preferencesDataSource;
  final NotificationService? notificationService;
  final Uuid _uuid = const Uuid();

  ElderCareRepositoryImpl({
    required this.localDataSource,
    this.medicalRecordRepository,
    this.preferencesDataSource,
    this.notificationService,
  });

  Future<String> _resolveUserId(String? explicitUserId) async {
    if (explicitUserId != null && explicitUserId.trim().isNotEmpty) {
      return explicitUserId.trim();
    }
    try {
      final uid = await preferencesDataSource?.getSessionUserId();
      return uid ?? '';
    } catch (_) {
      return '';
    }
  }

  String _resolveMemberId(String? explicitMemberId) {
    if (explicitMemberId != null && explicitMemberId.trim().isNotEmpty) {
      return explicitMemberId.trim();
    }
    return AppSessionNotifier.instance.activeMemberId;
  }

  DailyVitalLog? _parseEventBpToLog(
    MedicalEvent event,
    String targetDateKey,
  ) {
    final bp = event.bloodPressure?.trim();
    if (bp == null || !bp.contains('/')) return null;
    final parts = bp.split('/');
    final sys = int.tryParse(parts[0].replaceAll(RegExp(r'[^0-9]'), ''));
    final dia = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), ''));
    if (sys == null || dia == null) return null;
    final hr = int.tryParse((event.heartRate ?? '').replaceAll(RegExp(r'[^0-9]'), ''));
    return DailyVitalLog(
      id: 'ev_${event.id}',
      userId: event.userId,
      memberId: event.memberId,
      dateKey: targetDateKey,
      measuredAt: event.date,
      systolic: sys,
      diastolic: dia,
      heartRate: hr,
      statusLevel: DailyVitalLog.evaluateLevel(sys, dia),
      source: 'medical_event',
      note: event.title,
    );
  }

  @override
  Future<YesterdayTodayBpComparison> getYesterdayTodayBpComparison({
    String? userId,
    String? memberId,
  }) async {
    final uid = await _resolveUserId(userId);
    final mid = _resolveMemberId(memberId);
    final now = DateTime.now();
    final todayKey = DailyVitalLog.formatDateKey(now);
    final yesterdayDate = now.subtract(const Duration(days: 1));
    final yesterdayKey = DailyVitalLog.formatDateKey(yesterdayDate);

    DailyVitalLog? todayLog = await localDataSource.getLatestVitalForDate(
      userId: uid,
      memberId: mid,
      dateKey: todayKey,
    );
    DailyVitalLog? yesterdayLog = await localDataSource.getLatestVitalForDate(
      userId: uid,
      memberId: mid,
      dateKey: yesterdayKey,
    );

    // Fallback thông minh sang bảng medical_events cũ để nối liền dữ liệu lịch sử
    if ((todayLog == null || yesterdayLog == null) &&
        medicalRecordRepository != null) {
      try {
        final events = await medicalRecordRepository!.getMedicalTimeline(
          userId: uid.isNotEmpty ? uid : null,
          memberId: mid,
        );
        for (final ev in events) {
          final evDateKey = DailyVitalLog.formatDateKey(ev.date);
          if (todayLog == null && evDateKey == todayKey) {
            todayLog = _parseEventBpToLog(ev, todayKey);
          } else if (yesterdayLog == null && evDateKey != todayKey) {
            // Lấy số đo huyết áp của ngày hôm qua hoặc lần khám gần nhất trước hôm nay
            final parsed = _parseEventBpToLog(ev, evDateKey);
            if (parsed != null) {
              yesterdayLog = parsed;
              break;
            }
          }
        }
      } catch (_) {}
    }

    // Nếu hôm qua vẫn chưa có từ medical_events, lấy số đo gần nhất trước hôm nay trong daily_vitals_logs
    if (yesterdayLog == null) {
      final recent = await localDataSource.getRecentVitalLogs(
        userId: uid,
        memberId: mid,
        limit: 10,
      );
      for (final item in recent) {
        if (item.dateKey != todayKey) {
          yesterdayLog = item;
          break;
        }
      }
    }

    return YesterdayTodayBpComparison(
      yesterday: yesterdayLog,
      today: todayLog,
    );
  }

  @override
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
  }) async {
    final uid = await _resolveUserId(userId);
    final mid = _resolveMemberId(memberId);
    final now = DateTime.now();
    final todayKey = DailyVitalLog.formatDateKey(now);

    final log = DailyVitalLog(
      id: 'bp_${todayKey}_${mid}_${now.millisecondsSinceEpoch}',
      userId: uid,
      memberId: mid,
      dateKey: todayKey,
      measuredAt: now,
      systolic: systolic,
      diastolic: diastolic,
      heartRate: heartRate,
      statusLevel: DailyVitalLog.evaluateLevel(systolic, diastolic),
      source: source,
      imagePath: imagePath,
      note: note,
    );

    await localDataSource.upsertVitalLog(log);

    // Tự động tick hoàn thành công việc "Đo huyết áp" trong ngày
    await localDataSource.markTasksCompletedByCategory(
      userId: uid,
      memberId: mid,
      dateKey: todayKey,
      category: HealthTaskCategory.bloodPressure,
    );

    // Đồng bộ vào sổ theo dõi sinh hiệu (dùng deterministic ID theo ngày để không tạo rác trùng lặp)
    if (syncToMedicalTimeline && medicalRecordRepository != null) {
      try {
        final dailyEventId = 'vital_bp_${todayKey}_$mid';
        final existing = await medicalRecordRepository!.getMedicalEventById(dailyEventId);
        final vitalEvent = MedicalEvent(
          id: dailyEventId,
          userId: uid.isNotEmpty ? uid : null,
          memberId: mid,
          title: 'Theo dõi huyết áp hằng ngày (${log.statusLabelVi})',
          description: note ??
              (source == 'ocr_scan'
                  ? 'Quét tự động từ màn hình máy đo huyết áp (${log.formattedBp} mmHg).'
                  : 'Cập nhật chỉ số huyết áp tại nhà (${log.formattedBp} mmHg).'),
          date: now,
          type: MedicalEventType.symptomLog,
          facilityName: 'Đo tại nhà',
          diagnosis: log.statusLabelVi,
          bloodPressure: log.formattedBp,
          heartRate: heartRate != null && heartRate > 0 ? '$heartRate' : existing?.heartRate,
          attachments: imagePath != null && imagePath.isNotEmpty
              ? [imagePath]
              : (existing?.attachments ?? const []),
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
        );
        await medicalRecordRepository!.saveMedicalEvent(vitalEvent);
      } catch (_) {}
    }

    AppSessionNotifier.instance.notifyMedicalRecordsChanged();
    return log;
  }

  void _classifyMedicineToPopupSlots({
    required Medicine med,
    required List<PopupMedicineDetail> morning,
    required List<PopupMedicineDetail> noon,
    required List<PopupMedicineDetail> afternoon,
    required List<PopupMedicineDetail> night,
  }) {
    final fullInst = (med.instructions != null && med.instructions!.trim().isNotEmpty)
        ? '${med.frequency} • ${med.instructions}'
        : med.frequency;
    final lower = fullInst.toLowerCase();

    final detail = PopupMedicineDetail(
      name: med.name,
      dosage: med.dosage,
      mealInstruction: fullInst,
      visualType: PopupMedicineDetail.inferVisualType('${med.name} ${med.dosage}'),
    );

    final hasMorning = lower.contains('sáng') || lower.contains('điểm tâm');
    final hasNoon = lower.contains('trưa');
    final hasAfternoon = lower.contains('chiều');
    final hasNight = lower.contains('tối') ||
        lower.contains('đêm') ||
        lower.contains('trước khi ngủ') ||
        lower.contains('đi ngủ');

    if (hasMorning || hasNoon || hasAfternoon || hasNight) {
      if (hasMorning) morning.add(detail);
      if (hasNoon) noon.add(detail);
      if (hasAfternoon) afternoon.add(detail);
      if (hasNight) night.add(detail);
      return;
    }

    if (lower.contains('4 lần') || lower.contains('chia 4')) {
      morning.add(detail);
      noon.add(detail);
      afternoon.add(detail);
      night.add(detail);
    } else if (lower.contains('3 lần') || lower.contains('chia 3')) {
      morning.add(detail);
      noon.add(detail);
      night.add(detail);
    } else if (lower.contains('2 lần') || lower.contains('chia 2')) {
      morning.add(detail);
      night.add(detail);
    } else {
      morning.add(detail);
    }
  }

  @override
  Future<TodayMedicationProgress> getTodayMedicationProgress({
    String? userId,
    String? memberId,
  }) async {
    final uid = await _resolveUserId(userId);
    final mid = _resolveMemberId(memberId);
    final now = DateTime.now();
    final baseDateKey = DailyVitalLog.formatDateKey(now);
    final memberDateKey = '${baseDateKey}_$mid';

    List<String> takenSlots = const [];
    if (preferencesDataSource != null) {
      try {
        takenSlots = await preferencesDataSource!.getTakenDoseSlotsForDate(memberDateKey);
      } catch (_) {}
    }

    final morning = <PopupMedicineDetail>[];
    final noon = <PopupMedicineDetail>[];
    final afternoon = <PopupMedicineDetail>[];
    final night = <PopupMedicineDetail>[];
    String rxTitle = 'Lịch thuốc hằng ngày';

    if (medicalRecordRepository != null) {
      try {
        final events = await medicalRecordRepository!.getMedicalTimeline(
          userId: uid.isNotEmpty ? uid : null,
          memberId: mid,
        );
        final activeRxEvent = events.where((e) {
          final rx = e.prescription;
          return rx != null && rx.medicines.isNotEmpty && !rx.isExpiredByDuration;
        }).firstOrNull;

        if (activeRxEvent != null && activeRxEvent.prescription != null) {
          rxTitle = activeRxEvent.title;
          for (final m in activeRxEvent.prescription!.medicines) {
            _classifyMedicineToPopupSlots(
              med: m,
              morning: morning,
              noon: noon,
              afternoon: afternoon,
              night: night,
            );
          }
        }
      } catch (_) {}
    }

    // Nếu người dùng mới mở app chưa nhập đơn thuốc nào, cung cấp phác đồ mẫu trực quan 3 cữ
    // để người lớn tuổi thấy rõ giao diện Tiến độ 0/3 cữ & Popup nhắc uống thuốc ngay lập tức
    if (morning.isEmpty && noon.isEmpty && afternoon.isEmpty && night.isEmpty) {
      rxTitle = 'Lịch chăm sóc tim mạch & xương khớp mẫu';
      morning.add(const PopupMedicineDetail(
        name: 'Amlodipin 5mg (Thuốc huyết áp)',
        dosage: '1 viên nén',
        mealInstruction: 'Uống sau ăn sáng 30 phút với nước ấm',
        visualType: PillVisualType.tablet,
      ));
      noon.add(const PopupMedicineDetail(
        name: 'Omega-3 Dầu cá tự nhiên 1000mg',
        dosage: '1 viên nang mềm',
        mealInstruction: 'Uống ngay sau bữa ăn trưa',
        visualType: PillVisualType.capsule,
      ));
      night.add(const PopupMedicineDetail(
        name: 'Magie - Vitamin B6 hỗ trợ giấc ngủ',
        dosage: '1 viên nén',
        mealInstruction: 'Uống sau ăn tối, trước khi ngủ 1 giờ',
        visualType: PillVisualType.tablet,
      ));
    }

    final slots = <MedicationPopupReminder>[
      if (morning.isNotEmpty)
        MedicationPopupReminder(
          slotId: 'morning',
          slotTitle: 'Cữ Sáng',
          timeLabel: '08:00',
          prescriptionTitle: rxTitle,
          medicines: morning,
          isCompleted: takenSlots.contains('morning'),
        ),
      if (noon.isNotEmpty)
        MedicationPopupReminder(
          slotId: 'noon',
          slotTitle: 'Cữ Trưa',
          timeLabel: '12:30',
          prescriptionTitle: rxTitle,
          medicines: noon,
          isCompleted: takenSlots.contains('noon'),
        ),
      if (afternoon.isNotEmpty)
        MedicationPopupReminder(
          slotId: 'afternoon',
          slotTitle: 'Cữ Chiều',
          timeLabel: '17:30',
          prescriptionTitle: rxTitle,
          medicines: afternoon,
          isCompleted: takenSlots.contains('afternoon'),
        ),
      if (night.isNotEmpty)
        MedicationPopupReminder(
          slotId: 'night',
          slotTitle: 'Cữ Tối',
          timeLabel: '20:00',
          prescriptionTitle: rxTitle,
          medicines: night,
          isCompleted: takenSlots.contains('night'),
        ),
    ];

    final completedCount = slots.where((s) => s.isCompleted).length;
    final pending = slots.where((s) => !s.isCompleted).toList();

    return TodayMedicationProgress(
      completedSlots: completedCount,
      totalSlots: slots.length,
      allSlots: slots,
      nextPendingSlot: pending.isNotEmpty ? pending.first : null,
    );
  }

  @override
  Future<void> markMedicationSlotTaken({
    required String slotId,
    required bool isTaken,
    String? userId,
    String? memberId,
  }) async {
    final uid = await _resolveUserId(userId);
    final mid = _resolveMemberId(memberId);
    final baseDateKey = DailyVitalLog.formatDateKey(DateTime.now());
    final memberDateKey = '${baseDateKey}_$mid';

    if (preferencesDataSource != null) {
      final current = List<String>.from(
        await preferencesDataSource!.getTakenDoseSlotsForDate(memberDateKey),
      );
      if (isTaken) {
        if (!current.contains(slotId)) current.add(slotId);
      } else {
        current.remove(slotId);
      }
      await preferencesDataSource!.saveTakenDoseSlotsForDate(memberDateKey, current);
      if (mid == 'primary') {
        await preferencesDataSource!.saveTakenDoseSlotsForDate(baseDateKey, current);
      }
    }

    await localDataSource.syncMedicationSlotTaskStatus(
      userId: uid,
      memberId: mid,
      dateKey: baseDateKey,
      slotId: slotId,
      completed: isTaken,
    );

    AppSessionNotifier.instance.notifyMedicalRecordsChanged();
  }

  @override
  Future<void> snoozeMedicationSlot({
    required MedicationPopupReminder reminder,
    Duration delay = const Duration(minutes: 15),
  }) async {
    final medsSummary =
        reminder.medicines.map((m) => '${m.name} (${m.dosage})').join(', ');
    await notificationService?.scheduleOneTimeMedicationReminder(
      id: 88000 + (reminder.slotId.hashCode.abs() % 1000),
      title: '🔔 Nhắc lại uống thuốc: ${reminder.slotTitle}',
      body: medsSummary.isNotEmpty
          ? medsSummary
          : 'Đã đến giờ uống cữ thuốc bác hẹn nhắc lại.',
      delay: delay,
    );
  }

  @override
  Future<List<DailyHealthTask>> getOrCreateTodayTasks({
    String? userId,
    String? memberId,
  }) async {
    final uid = await _resolveUserId(userId);
    final mid = _resolveMemberId(memberId);
    final todayKey = DailyVitalLog.formatDateKey(DateTime.now());

    final existing = await localDataSource.getTasksForDate(
      userId: uid,
      memberId: mid,
      dateKey: todayKey,
    );
    if (existing.isNotEmpty) {
      return existing;
    }

    // Tự động khởi tạo danh sách việc cần làm hằng ngày thiết thực cho người lớn tuổi (40+)
    final medProgress = await getTodayMedicationProgress(
      userId: uid,
      memberId: mid,
    );
    final todayBp = await localDataSource.getLatestVitalForDate(
      userId: uid,
      memberId: mid,
      dateKey: todayKey,
    );

    final generated = <DailyHealthTask>[
      DailyHealthTask(
        id: 'task_bp_${todayKey}_$mid',
        userId: uid,
        memberId: mid,
        dateKey: todayKey,
        title: 'Đo huyết áp buổi sáng',
        subtitle: 'Ngồi nghỉ 5 phút trước khi đo để số chính xác nhất',
        category: HealthTaskCategory.bloodPressure,
        timeLabel: '07:15',
        isCompleted: todayBp != null,
      ),
      for (final slot in medProgress.allSlots)
        DailyHealthTask(
          id: 'task_med_${slot.slotId}_${todayKey}_$mid',
          userId: uid,
          memberId: mid,
          dateKey: todayKey,
          title: 'Uống thuốc ${slot.slotTitle} (${slot.timeLabel})',
          subtitle: slot.medicines.map((m) => m.name).join(' • '),
          category: HealthTaskCategory.medication,
          timeLabel: slot.timeLabel,
          linkedSlotId: slot.slotId,
          isCompleted: slot.isCompleted,
        ),
      DailyHealthTask(
        id: 'task_walk_${todayKey}_$mid',
        userId: uid,
        memberId: mid,
        dateKey: todayKey,
        title: 'Đi bộ nhẹ hoặc tập dưỡng sinh 20 phút',
        subtitle: 'Giúp lưu thông khí huyết và dẻo dai khớp gối',
        category: HealthTaskCategory.exercise,
        timeLabel: '16:30',
        isCompleted: false,
      ),
      DailyHealthTask(
        id: 'task_water_${todayKey}_$mid',
        userId: uid,
        memberId: mid,
        dateKey: todayKey,
        title: 'Uống đủ 6–8 cốc nước ấm trong ngày',
        subtitle: 'Uống từng ngụm nhỏ, hạn chế uống nhiều sát giờ đi ngủ',
        category: HealthTaskCategory.hydration,
        timeLabel: 'Cả ngày',
        isCompleted: false,
      ),
    ];

    for (final t in generated) {
      await localDataSource.upsertTask(t);
    }

    return localDataSource.getTasksForDate(
      userId: uid,
      memberId: mid,
      dateKey: todayKey,
    );
  }

  @override
  Future<void> toggleHealthTask({
    required DailyHealthTask task,
    String? userId,
    String? memberId,
  }) async {
    final nextCompleted = !task.isCompleted;
    await localDataSource.toggleTaskStatus(task.id, nextCompleted);

    if (task.linkedSlotId != null && task.linkedSlotId!.isNotEmpty) {
      await markMedicationSlotTaken(
        slotId: task.linkedSlotId!,
        isTaken: nextCompleted,
        userId: userId,
        memberId: memberId,
      );
    }
  }

  @override
  Future<DailyHealthTask> addCustomHealthTask({
    required String title,
    String? subtitle,
    String? timeLabel,
    HealthTaskCategory category = HealthTaskCategory.custom,
    String? userId,
    String? memberId,
  }) async {
    final uid = await _resolveUserId(userId);
    final mid = _resolveMemberId(memberId);
    final todayKey = DailyVitalLog.formatDateKey(DateTime.now());
    final task = DailyHealthTask(
      id: 'task_${_uuid.v4()}',
      userId: uid,
      memberId: mid,
      dateKey: todayKey,
      title: title.trim(),
      subtitle: subtitle?.trim(),
      category: category,
      timeLabel: timeLabel ?? 'Trong ngày',
      isCompleted: false,
    );
    await localDataSource.upsertTask(task);
    return task;
  }

  @override
  Future<void> deleteHealthTask(String taskId) =>
      localDataSource.deleteTask(taskId);

  @override
  Future<String> getSpecialHistoryNote({
    String? userId,
    String? memberId,
  }) async {
    final uid = await _resolveUserId(userId);
    final mid = _resolveMemberId(memberId);
    return localDataSource.getSpecialHistoryNote(userId: uid, memberId: mid);
  }

  @override
  Future<void> saveSpecialHistoryNote({
    required String note,
    String? userId,
    String? memberId,
  }) async {
    final uid = await _resolveUserId(userId);
    final mid = _resolveMemberId(memberId);
    await localDataSource.saveSpecialHistoryNote(
      userId: uid,
      memberId: mid,
      note: note,
    );
    AppSessionNotifier.instance.notifyMedicalRecordsChanged();
  }

  @override
  Future<List<DoctorContact>> getDoctors({
    String? userId,
    String? memberId,
  }) async {
    final uid = await _resolveUserId(userId);
    final mid = _resolveMemberId(memberId);
    return localDataSource.getDoctors(userId: uid, memberId: mid);
  }

  @override
  Future<void> saveDoctor(DoctorContact doctor) async {
    final uid = await _resolveUserId(doctor.userId);
    final mid = _resolveMemberId(doctor.memberId);
    await localDataSource.upsertDoctor(
      doctor.copyWith(
        userId: uid.isNotEmpty ? uid : (doctor.userId ?? 'seed'),
        memberId: mid,
      ),
    );
  }

  @override
  Future<void> deleteDoctor(String doctorId) =>
      localDataSource.deleteDoctor(doctorId);

  @override
  Future<List<HealthVideo>> getHealthVideos({String? category}) =>
      localDataSource.getHealthVideos(category: category);

  @override
  Future<void> toggleSaveVideo(String videoId, bool isSaved) =>
      localDataSource.toggleSaveVideo(videoId, isSaved);

  @override
  Future<void> markVideoWatched(String videoId) =>
      localDataSource.markVideoWatched(videoId);

  @override
  Future<List<NutritionGuideline>> getNutritionGuidelines({
    String? userId,
    String? memberId,
    String? healthTag,
  }) async {
    final uid = await _resolveUserId(userId);
    final mid = _resolveMemberId(memberId);
    return localDataSource.getNutritionGuidelines(
      userId: uid,
      memberId: mid,
      healthTag: healthTag,
    );
  }

  @override
  Future<void> saveNutritionGuideline(NutritionGuideline item) =>
      localDataSource.upsertNutritionGuideline(item);

  @override
  Future<List<DietarySupplement>> getSupplements({
    String? userId,
    String? memberId,
  }) async {
    final uid = await _resolveUserId(userId);
    final mid = _resolveMemberId(memberId);
    return localDataSource.getSupplements(userId: uid, memberId: mid);
  }

  @override
  Future<void> saveSupplement(DietarySupplement item) async {
    final uid = await _resolveUserId(item.userId);
    final mid = _resolveMemberId(item.memberId);
    await localDataSource.upsertSupplement(
      item.copyWith(),
    );
    if (uid.isNotEmpty && (item.userId == null || item.userId!.isEmpty)) {
      await localDataSource.upsertSupplement(
        DietarySupplement(
          id: item.id,
          userId: uid,
          memberId: mid,
          productName: item.productName,
          category: item.category,
          imagePath: item.imagePath,
          benefits: item.benefits,
          dosageGuide: item.dosageGuide,
          usageStatus: item.usageStatus,
          cautionNote: item.cautionNote,
          createdAt: item.createdAt,
        ),
      );
    }
  }

  @override
  Future<void> deleteSupplement(String supplementId) =>
      localDataSource.deleteSupplement(supplementId);
}
