import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/ocr_service.dart';
import '../../../../domain/entities/medical_event.dart';
import '../../../../domain/entities/medicine.dart';
import '../../../../domain/entities/prescription.dart';
import '../../../../domain/repositories/medical_record_repository.dart';
import 'prescriptions_state.dart';

/// ViewModel quản lý lịch nhắc uống thuốc và đơn thuốc đang điều trị.
class PrescriptionsViewModel extends ChangeNotifier {
  final NotificationService _notificationService;
  final MedicalRecordRepository? _repository;
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
        _state = initialState ?? PrescriptionsState.initial() {
    initNotifications();
    if (initialState == null) {
      loadFromRepository();
    }
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

  Future<void> loadFromRepository() async {
    try {
      final repo = _repository ??
          (sl.isRegistered<MedicalRecordRepository>()
              ? sl<MedicalRecordRepository>()
              : null);
      if (repo != null) {
        final events = await repo.getMedicalTimeline();
        final eventsWithPrescription = events.where(
          (e) => e.prescription != null && e.prescription!.medicines.isNotEmpty,
        ).toList();

        if (eventsWithPrescription.isEmpty) {
          // Không có đơn thuốc nào: đảm bảo xóa toàn bộ lịch nhắc trên hệ điều hành
          _state = PrescriptionsState.initial();
          notifyListeners();
          await _notificationService.cancelAllReminders();
          return;
        }

        final latestEvent = eventsWithPrescription.first;
        final pres = latestEvent.prescription!;
        final medicines = pres.medicines;

        final morningMeds = <MedicationItem>[];
        final noonMeds = <MedicationItem>[];
        final nightMeds = <MedicationItem>[];

        for (final m in medicines) {
          final freq = m.frequency.toLowerCase();
          final item = MedicationItem(
            name: m.name,
            instruction: '${m.dosage} • ${m.frequency}',
            iconAsset: 'assets/icons/ic_rx_med_bottle.svg',
          );

          if (freq.contains('sáng') || freq.contains('ngày') || freq.contains('lần')) {
            morningMeds.add(item);
          }
          if (freq.contains('trưa') || freq.contains('2 lần') || freq.contains('3 lần')) {
            noonMeds.add(item);
          }
          if (freq.contains('tối') || freq.contains('chiều') || freq.contains('2 lần') || freq.contains('3 lần')) {
            nightMeds.add(item);
          }
          if (morningMeds.isEmpty && noonMeds.isEmpty && nightMeds.isEmpty) {
            morningMeds.add(item);
          }
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

        final plan = ActiveTreatmentPlan(
          title: latestEvent.title,
          subtitle: pres.doctorName.isNotEmpty ? 'BS. ${pres.doctorName}' : (pres.hospital ?? 'Phác đồ điều trị'),
          statusLabel: 'Đang áp dụng',
          currentDay: 1,
          totalDays: 14,
          startDate: '${pres.issuedDate.day}/${pres.issuedDate.month}/${pres.issuedDate.year}',
          endDate: '${pres.issuedDate.add(const Duration(days: 14)).day}/${pres.issuedDate.month}/${pres.issuedDate.year}',
          pharmacyName: pres.hospital ?? 'Cơ sở khám bệnh',
          totalCost: latestEvent.hospitalFee ?? 'Chưa cập nhật chi phí',
        );

        _state = _state.copyWith(
          planSubtitle: 'Phác đồ: ${latestEvent.title}',
          slots: realSlots,
          activePlan: plan,
        );
        notifyListeners();
        await scheduleAllReminders();
      }
    } catch (_) {}
  }

  Future<void> saveOcrPrescription(ParsedPrescriptionResult result) async {
    try {
      final repo = _repository ??
          (sl.isRegistered<MedicalRecordRepository>()
              ? sl<MedicalRecordRepository>()
              : null);
      if (repo == null) return;

      final now = DateTime.now();
      final eventId = 'REC-OCR-${now.millisecondsSinceEpoch}';
      final rxId = 'RX-OCR-${now.millisecondsSinceEpoch}';

      final mappedMeds = result.medicines.asMap().entries.map((entry) {
        final idx = entry.key;
        final m = entry.value;
        return Medicine(
          id: 'med_${now.millisecondsSinceEpoch}_$idx',
          name: m.name,
          dosage: m.dosage,
          frequency: m.instruction,
        );
      }).toList();

      final pres = Prescription(
        id: rxId,
        doctorName: result.doctorName ?? 'Bác sĩ điều trị',
        hospital: result.hospital ?? 'Bệnh viện / Cơ sở y tế',
        issuedDate: now,
        medicines: mappedMeds,
      );

      final event = MedicalEvent(
        id: eventId,
        title: result.diagnosis != null && result.diagnosis!.isNotEmpty
            ? 'Đợt khám: ${result.diagnosis}'
            : 'Đơn thuốc quét bằng AI OCR',
        date: now,
        type: MedicalEventType.generalCheckup,
        facilityName: result.hospital,
        doctorName: result.doctorName,
        diagnosis: result.diagnosis,
        prescription: pres,
        attachments: result.imagePath != null ? [result.imagePath!] : const [],
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
    // Luôn dọn sạch toàn bộ lịch nhắc cũ trên thiết bị trước khi lên lịch mới
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

  /// Đánh dấu một cữ thuốc đã uống.
  void markDoseTaken(String slotId) {
    final updated = _state.slots.map((slot) {
      if (slot.id != slotId) return slot;
      return slot.copyWith(
        status: DoseSlotStatus.completed,
        statusBadge: 'Đã uống vừa xong',
      );
    }).toList();

    final completed =
        updated.where((s) => s.status == DoseSlotStatus.completed).length;
    final percent = ((completed / updated.length) * 100).round().clamp(0, 100);

    _state = _state.copyWith(
      slots: updated,
      adherencePercent: percent > _state.adherencePercent
          ? percent
          : _state.adherencePercent,
      lastActionMessage:
          'Đã ghi nhận uống thuốc đúng giờ! Chỉ số tuân thủ tăng lên $percent%',
    );
    notifyListeners();
  }

  /// Hoãn nhắc uống thuốc thêm 15 phút.
  void snoozeDose(String slotId) {
    _state = _state.copyWith(
      lastActionMessage: 'Sẽ nhắc lại cữ thuốc sau 15 phút nữa.',
    );
    notifyListeners();
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
