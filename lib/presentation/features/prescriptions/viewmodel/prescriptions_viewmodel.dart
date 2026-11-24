import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/ocr_service.dart';
import '../../../../core/services/user_session_manager.dart';
import '../../../../data/datasources/local/app_preferences_datasource.dart';
import '../../../../domain/entities/medical_event.dart';
import '../../../../domain/entities/medicine.dart';
import '../../../../domain/entities/prescription.dart';
import '../../../../domain/repositories/medical_record_repository.dart';
import 'prescriptions_state.dart';

/// ViewModel quản lý lịch nhắc uống thuốc và đơn thuốc đang điều trị.
class PrescriptionsViewModel extends ChangeNotifier {
  final NotificationService _notificationService;
  final MedicalRecordRepository? _repository;
  final bool _hasCustomInitialState;
  final Uuid _uuid = const Uuid();
  int _lastRecordsVersion = AppSessionNotifier.instance.medicalRecordsVersion;
  PrescriptionsState _state;

  PrescriptionsState get state => _state;

  PrescriptionsViewModel({
    NotificationService? notificationService,
    MedicalRecordRepository? repository,
    PrescriptionsState? initialState,
  })  : _notificationService = notificationService ??
            (sl.isRegistered<NotificationService>()
                ? sl<NotificationService>()
                : NotificationServiceImpl()),
        _repository = repository ??
            (sl.isRegistered<MedicalRecordRepository>()
                ? sl<MedicalRecordRepository>()
                : null),
        _hasCustomInitialState = initialState != null,
        _state = initialState ?? PrescriptionsState.initial() {
    initNotifications();
    if (!_hasCustomInitialState) {
      loadFromRepository();
      AppSessionNotifier.instance.addListener(_onGlobalSessionChanged);
    }
  }

  void _onGlobalSessionChanged() {
    final currentVer = AppSessionNotifier.instance.medicalRecordsVersion;
    if (currentVer != _lastRecordsVersion) {
      _lastRecordsVersion = currentVer;
      loadFromRepository();
    }
  }

  @override
  void dispose() {
    if (!_hasCustomInitialState) {
      AppSessionNotifier.instance.removeListener(_onGlobalSessionChanged);
    }
    super.dispose();
  }

  String _todayDateKey() {
    final now = DateTime.now();
    final memberSuffix = AppSessionNotifier.instance.activeMemberId;
    return '${now.year}-${now.month.toString().padLeft(2, "0")}-${now.day.toString().padLeft(2, "0")}_$memberSuffix';
  }

  Future<void> initNotifications() async {
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
    if (_state.slots.isEmpty) {
      await _notificationService.cancelAllReminders();
    } else {
      await scheduleAllReminders();
    }
  }

  /// Phân loại thuốc vào đúng khung giờ lâm sàng, tránh đẩy nhầm thuốc "uống tối 1 lần/ngày" sang Cữ Sáng.
  static void classifyMedicineIntoSlots({
    required Medicine medicine,
    required List<MedicationItem> morningMeds,
    required List<MedicationItem> noonMeds,
    required List<MedicationItem> afternoonMeds,
    required List<MedicationItem> nightMeds,
  }) {
    final freq = (medicine.instructions != null && medicine.instructions!.trim().isNotEmpty)
        ? '${medicine.frequency} ${medicine.instructions}'.toLowerCase()
        : medicine.frequency.toLowerCase();

    final item = MedicationItem(
      name: medicine.name,
      instruction: '${medicine.dosage} • ${medicine.frequency}',
      iconAsset: 'assets/icons/ic_rx_med_bottle.svg',
    );

    final hasMorning = freq.contains('sáng') || freq.contains('điểm tâm');
    final hasNoon = freq.contains('trưa');
    final hasAfternoon = freq.contains('chiều');
    final hasNight = freq.contains('tối') ||
        freq.contains('đêm') ||
        freq.contains('trước khi ngủ') ||
        freq.contains('trước khi đi ngủ') ||
        freq.contains('đi ngủ');

    // 1. Nếu đơn bác sĩ có ghi rõ buổi cụ thể -> chỉ đặt chuông đúng những buổi đó!
    if (hasMorning || hasNoon || hasAfternoon || hasNight) {
      if (hasMorning) morningMeds.add(item);
      if (hasNoon) noonMeds.add(item);
      if (hasAfternoon) afternoonMeds.add(item);
      if (hasNight) nightMeds.add(item);
      return;
    }

    // 2. Nếu chỉ ghi số lần/ngày mà không ghi buổi -> phân bổ chuẩn dược lâm sàng
    if (freq.contains('4 lần') || freq.contains('chia 4')) {
      morningMeds.add(item);
      noonMeds.add(item);
      afternoonMeds.add(item);
      nightMeds.add(item);
    } else if (freq.contains('3 lần') || freq.contains('chia 3')) {
      morningMeds.add(item);
      noonMeds.add(item);
      nightMeds.add(item);
    } else if (freq.contains('2 lần') || freq.contains('chia 2')) {
      morningMeds.add(item);
      nightMeds.add(item);
    } else {
      morningMeds.add(item);
    }
  }

  static String formatDdMmYyyy(DateTime dt) {
    return '${dt.day.toString().padLeft(2, "0")}/${dt.month.toString().padLeft(2, "0")}/${dt.year}';
  }

  Future<void> loadFromRepository() async {
    try {
      final repo = _repository ??
          (sl.isRegistered<MedicalRecordRepository>()
              ? sl<MedicalRecordRepository>()
              : null);
      if (repo != null) {
        final events = await repo.getMedicalTimeline();
        final activePrescriptionEvents = events.where((e) {
          final pres = e.prescription;
          return pres != null &&
              pres.medicines.isNotEmpty &&
              !pres.isExpiredByDuration;
        }).toList();

        if (activePrescriptionEvents.isEmpty) {
          _state = PrescriptionsState.initial();
          notifyListeners();
          await _notificationService.cancelAllReminders();
          return;
        }

        final latestEvent = activePrescriptionEvents.first;
        final pres = latestEvent.prescription!;
        final medicines = pres.medicines;

        final morningMeds = <MedicationItem>[];
        final noonMeds = <MedicationItem>[];
        final afternoonMeds = <MedicationItem>[];
        final nightMeds = <MedicationItem>[];

        for (final m in medicines) {
          classifyMedicineIntoSlots(
            medicine: m,
            morningMeds: morningMeds,
            noonMeds: noonMeds,
            afternoonMeds: afternoonMeds,
            nightMeds: nightMeds,
          );
        }

        final realSlots = <MedicationDoseSlot>[];
        if (morningMeds.isNotEmpty) {
          realSlots.add(
            MedicationDoseSlot(
              id: 'morning',
              title: 'Cữ Sáng',
              timeLabel: '08:00',
              status: DoseSlotStatus.upcoming,
              statusBadge: 'Chưa đến giờ',
              slotIconAsset: 'assets/icons/ic_rx_sunrise.svg',
              medications: morningMeds,
            ),
          );
        }
        if (noonMeds.isNotEmpty) {
          realSlots.add(
            MedicationDoseSlot(
              id: 'noon',
              title: 'Cữ Trưa',
              timeLabel: '12:30',
              status: DoseSlotStatus.upcoming,
              statusBadge: 'Chưa đến giờ',
              slotIconAsset: 'assets/icons/ic_rx_sun_noon.svg',
              medications: noonMeds,
            ),
          );
        }
        if (afternoonMeds.isNotEmpty) {
          realSlots.add(
            MedicationDoseSlot(
              id: 'afternoon',
              title: 'Cữ Chiều',
              timeLabel: '17:30',
              status: DoseSlotStatus.upcoming,
              statusBadge: 'Chưa đến giờ',
              slotIconAsset: 'assets/icons/ic_rx_sun_noon.svg',
              medications: afternoonMeds,
            ),
          );
        }
        if (nightMeds.isNotEmpty) {
          realSlots.add(
            MedicationDoseSlot(
              id: 'night',
              title: 'Cữ Tối',
              timeLabel: '20:00',
              status: DoseSlotStatus.upcoming,
              statusBadge: 'Chưa đến giờ',
              slotIconAsset: 'assets/icons/ic_rx_moon_night.svg',
              medications: nightMeds,
            ),
          );
        }

        final totalDays = (pres.durationDays != null && pres.durationDays! > 0)
            ? pres.durationDays!
            : 14;
        final startDayOnly = DateTime(
          pres.issuedDate.year,
          pres.issuedDate.month,
          pres.issuedDate.day,
        );
        final todayOnly = DateTime.now();
        final elapsedDays = DateTime(todayOnly.year, todayOnly.month, todayOnly.day)
                .difference(startDayOnly)
                .inDays +
            1;
        final currentDay = elapsedDays.clamp(1, totalDays);
        final endDateTime = startDayOnly.add(Duration(days: totalDays));

        final plan = ActiveTreatmentPlan(
          title: latestEvent.title,
          subtitle: pres.doctorName.isNotEmpty ? 'BS. ${pres.doctorName}' : (pres.hospital ?? 'Phác đồ điều trị'),
          statusLabel: 'Đang áp dụng',
          currentDay: currentDay,
          totalDays: totalDays,
          startDate: formatDdMmYyyy(startDayOnly),
          endDate: formatDdMmYyyy(endDateTime),
          pharmacyName: pres.hospital ?? 'Cơ sở khám bệnh',
          totalCost: latestEvent.hospitalFee ?? 'Chưa cập nhật chi phí',
        );

        List<String> takenToday = const [];
        if (sl.isRegistered<AppPreferencesDataSource>()) {
          try {
            takenToday = await sl<AppPreferencesDataSource>().getTakenDoseSlotsForDate(_todayDateKey());
          } catch (_) {}
        }

        final hydratedSlots = realSlots.map((slot) {
          if (takenToday.contains(slot.id)) {
            return slot.copyWith(
              status: DoseSlotStatus.completed,
              statusBadge: 'Đã uống hôm nay',
            );
          }
          return slot;
        }).toList();

        final completedCount = hydratedSlots.where((s) => s.status == DoseSlotStatus.completed).length;
        final adherence = hydratedSlots.isNotEmpty
            ? ((completedCount / hydratedSlots.length) * 100).round().clamp(0, 100)
            : 0;

        _state = _state.copyWith(
          planSubtitle: 'Phác đồ: ${latestEvent.title}',
          slots: hydratedSlots,
          activePlan: plan,
          adherencePercent: adherence,
        );
        notifyListeners();
        await scheduleAllReminders();
      }
    } catch (e) {
      debugPrint('[PrescriptionsViewModel] loadFromRepository error: $e');
    }
  }

  Future<void> saveOcrPrescription(ParsedPrescriptionResult result) async {
    try {
      final repo = _repository ??
          (sl.isRegistered<MedicalRecordRepository>()
              ? sl<MedicalRecordRepository>()
              : null);
      if (repo == null) return;

      final now = DateTime.now();
      final eventId = _uuid.v4();
      final rxId = _uuid.v4();

      final mappedMeds = result.medicines.map((m) {
        return Medicine(
          id: _uuid.v4(),
          name: m.name,
          dosage: m.dosage,
          frequency: m.instruction,
          instructions: m.instruction,
        );
      }).toList();

      final pres = Prescription(
        id: rxId,
        doctorName: result.doctorName ?? 'Bác sĩ điều trị',
        hospital: result.hospital ?? 'Bệnh viện / Cơ sở y tế',
        issuedDate: now,
        durationDays: 14,
        status: 'active',
        medicines: mappedMeds,
        note: result.advice,
      );

      final event = MedicalEvent(
        id: eventId,
        memberId: AppSessionNotifier.instance.activeMemberId,
        title: result.diagnosis != null && result.diagnosis!.isNotEmpty
            ? 'Đợt khám: ${result.diagnosis}'
            : 'Đơn thuốc quét bằng AI OCR',
        description: result.advice,
        date: now,
        type: MedicalEventType.generalCheckup,
        facilityName: result.hospital,
        doctorName: result.doctorName,
        diagnosis: result.diagnosis,
        prescription: pres,
        attachments: result.imagePath != null ? [result.imagePath!] : const [],
        createdAt: now,
        updatedAt: now,
      );

      await repo.saveMedicalEvent(event);
      await loadFromRepository();

      _state = _state.copyWith(
        lastActionMessage: 'Đã lưu toa thuốc (${mappedMeds.length} loại) vào sổ y tế và lên lịch uống thuốc tự động!',
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        lastActionMessage: 'Lỗi khi lưu toa thuốc: $e',
      );
      notifyListeners();
    }
  }

  Future<void> scheduleAllReminders() async {
    await _notificationService.cancelAllReminders();

    if (_state.slots.isEmpty) {
      return;
    }

    for (final slot in _state.slots) {
      final parts = slot.timeLabel.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]) ?? 8;
        final minute = int.tryParse(parts[1]) ?? 0;
        final medsSummary = slot.medications
            .map((m) => '${m.name} (${m.instruction})')
            .join(', ');

        await _notificationService.scheduleDailyMedicationReminder(
          id: slot.id.hashCode.abs() % 100000,
          title: '🔔 Nhắc nhở uống thuốc: ${slot.title} (${slot.timeLabel})',
          body: medsSummary.isNotEmpty
              ? medsSummary
              : 'Đã đến giờ uống thuốc theo phác đồ điều trị.',
          hour: hour,
          minute: minute,
        );
      }
    }
  }

  /// Hủy và dọn dẹp sạch toàn bộ lịch nhắc nhở uống thuốc trên thiết bị.
  Future<void> clearAllReminders() async {
    await _notificationService.cancelAllReminders();
    _state = _state.copyWith(
      lastActionMessage: 'Đã hủy và xóa sạch tất cả chuông thông báo nhắc nhở.',
    );
    notifyListeners();
  }

  Future<void> testSendInstantReminder() async {
    await _notificationService.showInstantNotification(
      id: 99999,
      title: '🔔 [Thử Chuông] Nhắc Nhở Uống Thuốc Sổ Tay Y Tế',
      body: 'Klacid (Clarithromycin) 500mg - 1 viên. Uống sau ăn no.',
    );
    _state = _state.copyWith(
      lastActionMessage:
          'Đã phát chuông thông báo thử nghiệm thành công! Kiểm tra thanh thông báo.',
    );
    notifyListeners();
  }

  /// Đánh dấu một cữ thuốc đã uống (hoặc hoàn tác nếu bấm lại vào cữ đã hoàn thành).
  void markDoseTaken(String slotId) {
    bool wasUnmarked = false;
    final updated = _state.slots.map((slot) {
      if (slot.id != slotId) return slot;
      if (slot.status == DoseSlotStatus.completed) {
        wasUnmarked = true;
        return slot.copyWith(
          status: DoseSlotStatus.upcoming,
          statusBadge: 'Chưa đến giờ',
        );
      }
      return slot.copyWith(
        status: DoseSlotStatus.completed,
        statusBadge: 'Đã uống vừa xong',
      );
    }).toList();

    final completed =
        updated.where((s) => s.status == DoseSlotStatus.completed).length;
    final dailyPercent = updated.isNotEmpty
        ? ((completed / updated.length) * 100).round().clamp(0, 100)
        : 0;
    final percent = (!wasUnmarked && _state.adherencePercent > dailyPercent)
        ? (_state.adherencePercent + 4).clamp(0, 100)
        : dailyPercent;

    _state = _state.copyWith(
      slots: updated,
      adherencePercent: percent,
      lastActionMessage: wasUnmarked
          ? 'Đã hoàn tác trạng thái cữ thuốc. Chỉ số tuân thủ hiện tại: $percent%'
          : 'Đã ghi nhận uống thuốc đúng giờ! Chỉ số tuân thủ tăng lên $percent%',
    );
    notifyListeners();

    if (sl.isRegistered<AppPreferencesDataSource>()) {
      final completedIds = updated
          .where((s) => s.status == DoseSlotStatus.completed)
          .map((s) => s.id)
          .toList();
      sl<AppPreferencesDataSource>()
          .saveTakenDoseSlotsForDate(_todayDateKey(), completedIds)
          .catchError((_) {});
    }
  }

  /// Hoãn nhắc uống thuốc thêm 15 phút (chỉ đổ chuông 1 lần, không lặp sang ngày hôm sau).
  void snoozeDose(String slotId) {
    _state = _state.copyWith(
      lastActionMessage: 'Sẽ nhắc lại cữ thuốc sau 15 phút nữa.',
    );
    notifyListeners();

    final targetSlot = _state.slots.where((s) => s.id == slotId).firstOrNull;
    final medsSummary = targetSlot != null
        ? targetSlot.medications.map((m) => m.name).join(', ')
        : 'Đã đến giờ uống cữ thuốc đã hoãn.';
    _notificationService
        .scheduleOneTimeMedicationReminder(
          id: 88000 + (slotId.hashCode.abs() % 1000),
          title: '🔔 Nhắc lại cữ thuốc (${targetSlot?.title ?? "Sau 15 phút"})',
          body: medsSummary,
          delay: const Duration(minutes: 15),
        )
        .catchError((_) {});
  }

  void notifyUser(String message) {
    _state = _state.copyWith(lastActionMessage: message);
    notifyListeners();
  }

  void clearActionMessage() {
    if (_state.lastActionMessage == null) return;
    _state = _state.copyWith(clearActionMessage: true);
    notifyListeners();
  }
}
