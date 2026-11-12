/// Trạng thái của một cữ uống thuốc trong ngày.
enum DoseSlotStatus { completed, dueSoon, upcoming }

/// Một loại thuốc nằm trong cữ uống.
class MedicationItem {
  final String name;
  final String instruction;
  final String? quantityBadge;
  final String iconAsset;

  const MedicationItem({
    required this.name,
    required this.instruction,
    this.quantityBadge,
    required this.iconAsset,
  });
}

/// Một cữ uống thuốc (Sáng, Trưa, Chiều, Tối).
class MedicationDoseSlot {
  final String id;
  final String title;
  final String timeLabel;
  final DoseSlotStatus status;
  final String statusBadge;
  final String slotIconAsset;
  final List<MedicationItem> medications;

  const MedicationDoseSlot({
    required this.id,
    required this.title,
    required this.timeLabel,
    required this.status,
    required this.statusBadge,
    required this.slotIconAsset,
    required this.medications,
  });

  MedicationDoseSlot copyWith({
    DoseSlotStatus? status,
    String? statusBadge,
  }) {
    return MedicationDoseSlot(
      id: id,
      title: title,
      timeLabel: timeLabel,
      status: status ?? this.status,
      statusBadge: statusBadge ?? this.statusBadge,
      slotIconAsset: slotIconAsset,
      medications: medications,
    );
  }
}

/// Thông tin phác đồ đơn thuốc đang điều trị.
class ActiveTreatmentPlan {
  final String title;
  final String subtitle;
  final String statusLabel;
  final int currentDay;
  final int totalDays;
  final String startDate;
  final String endDate;
  final String pharmacyName;
  final String totalCost;

  const ActiveTreatmentPlan({
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.currentDay,
    required this.totalDays,
    required this.startDate,
    required this.endDate,
    required this.pharmacyName,
    required this.totalCost,
  });
}

/// State bất biến cho màn hình Quản Lý Toa Thuốc & Lịch Uống.
class PrescriptionsState {
  final String dayTitle;
  final String planSubtitle;
  final int adherencePercent;
  final String nextDoseHighlight;
  final List<MedicationDoseSlot> slots;
  final ActiveTreatmentPlan activePlan;
  final String pharmacistAdvice;
  final String? lastActionMessage;

  const PrescriptionsState({
    required this.dayTitle,
    required this.planSubtitle,
    required this.adherencePercent,
    required this.nextDoseHighlight,
    required this.slots,
    required this.activePlan,
    required this.pharmacistAdvice,
    this.lastActionMessage,
  });

  int get completedCount =>
      slots.where((s) => s.status == DoseSlotStatus.completed).length;

  int get totalCount => slots.length;

  factory PrescriptionsState.initial() {
    return const PrescriptionsState(
      dayTitle: 'Hôm nay, Thứ Hai',
      planSubtitle: 'Kế hoạch dùng thuốc thường nhật',
      adherencePercent: 85,
      nextDoseHighlight: '18:30',
      slots: [
        MedicationDoseSlot(
          id: 'morning',
          title: 'Cữ Sáng',
          timeLabel: '07:30',
          status: DoseSlotStatus.completed,
          statusBadge: 'Đã uống lúc 07:35',
          slotIconAsset: 'assets/icons/ic_rx_sunrise.svg',
          medications: [
            MedicationItem(
              name: 'Nexium Mups 40mg',
              instruction: '1 viên • Uống trước bữa ăn sáng 30 phút',
              iconAsset: 'assets/icons/ic_rx_med_bottle.svg',
            ),
            MedicationItem(
              name: 'Vitamin 3B (B1-B6-B12)',
              instruction: '1 viên • Uống sau ăn sáng cùng nhiều nước',
              iconAsset: 'assets/icons/ic_rx_med_vitamins.svg',
            ),
          ],
        ),
        MedicationDoseSlot(
          id: 'noon',
          title: 'Cữ Trưa',
          timeLabel: '12:30',
          status: DoseSlotStatus.completed,
          statusBadge: 'Đã uống lúc 12:45',
          slotIconAsset: 'assets/icons/ic_rx_sun_noon.svg',
          medications: [
            MedicationItem(
              name: 'Gaviscon Dual Action',
              instruction: '1 gói hỗn dịch • Uống sau khi ăn trưa no',
              iconAsset: 'assets/icons/ic_rx_med_sachet.svg',
            ),
          ],
        ),
        MedicationDoseSlot(
          id: 'afternoon',
          title: 'Cữ Chiều',
          timeLabel: '18:30',
          status: DoseSlotStatus.dueSoon,
          statusBadge: 'Sắp đến giờ',
          slotIconAsset: 'assets/icons/ic_rx_alarm_red.svg',
          medications: [
            MedicationItem(
              name: 'Klacid (Clarithromycin) 500mg',
              instruction: 'Uống sau khi ăn tối no • Kháng sinh HP',
              quantityBadge: '1 Viên',
              iconAsset: 'assets/icons/ic_rx_med_antibiotic.svg',
            ),
          ],
        ),
        MedicationDoseSlot(
          id: 'night',
          title: 'Cữ Tối',
          timeLabel: '21:30',
          status: DoseSlotStatus.upcoming,
          statusBadge: 'Chưa đến giờ',
          slotIconAsset: 'assets/icons/ic_rx_moon_night.svg',
          medications: [
            MedicationItem(
              name: 'Men vi sinh BioGaia Protectis',
              instruction: '1 ống (5 giọt) • Uống cách kháng sinh ít nhất 2 giờ',
              iconAsset: 'assets/icons/ic_rx_med_drops.svg',
            ),
          ],
        ),
      ],
      activePlan: ActiveTreatmentPlan(
        title: 'Điều trị Viêm dạ dày HP',
        subtitle: 'Phác đồ 4 thuốc phối hợp • BS. Trần Văn Minh',
        statusLabel: 'Đang áp dụng',
        currentDay: 6,
        totalDays: 14,
        startDate: '15/04/2024',
        endDate: '29/04/2024',
        pharmacyName: 'Long Châu - CN Quận 1',
        totalCost: '860.000 đ',
      ),
      pharmacistAdvice:
          'Cần uống kháng sinh đúng giờ và tuyệt đối không ngắt quãng liệu trình 14 ngày để tránh tình trạng vi khuẩn HP kháng thuốc.',
    );
  }

  PrescriptionsState copyWith({
    int? adherencePercent,
    List<MedicationDoseSlot>? slots,
    String? lastActionMessage,
    bool clearActionMessage = false,
  }) {
    return PrescriptionsState(
      dayTitle: dayTitle,
      planSubtitle: planSubtitle,
      adherencePercent: adherencePercent ?? this.adherencePercent,
      nextDoseHighlight: nextDoseHighlight,
      slots: slots ?? this.slots,
      activePlan: activePlan,
      pharmacistAdvice: pharmacistAdvice,
      lastActionMessage: clearActionMessage
          ? null
          : (lastActionMessage ?? this.lastActionMessage),
    );
  }
}

