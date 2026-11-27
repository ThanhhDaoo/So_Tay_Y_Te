enum PillVisualType {
  capsule,
  tablet,
  sachet,
  syrupBottle,
}

class PopupMedicineDetail {
  final String name;
  final String dosage;
  final String mealInstruction;
  final PillVisualType visualType;

  const PopupMedicineDetail({
    required this.name,
    required this.dosage,
    required this.mealInstruction,
    this.visualType = PillVisualType.tablet,
  });

  static PillVisualType inferVisualType(String nameAndDosage) {
    final lower = nameAndDosage.toLowerCase();
    if (lower.contains('gói') || lower.contains('bột') || lower.contains('hỗn dịch')) {
      return PillVisualType.sachet;
    }
    if (lower.contains('lọ') || lower.contains('chai') || lower.contains('ml') || lower.contains('siro')) {
      return PillVisualType.syrupBottle;
    }
    if (lower.contains('nang') || lower.contains('omega') || lower.contains('augmentin')) {
      return PillVisualType.capsule;
    }
    return PillVisualType.tablet;
  }
}

class MedicationPopupReminder {
  final String slotId; // 'morning' | 'noon' | 'afternoon' | 'night'
  final String slotTitle; // 'Cữ Sáng', 'Cữ Trưa'...
  final String timeLabel; // '08:00'
  final String prescriptionTitle;
  final List<PopupMedicineDetail> medicines;
  final bool isCompleted;

  const MedicationPopupReminder({
    required this.slotId,
    required this.slotTitle,
    required this.timeLabel,
    required this.prescriptionTitle,
    required this.medicines,
    this.isCompleted = false,
  });
}

class TodayMedicationProgress {
  final int completedSlots;
  final int totalSlots;
  final List<MedicationPopupReminder> allSlots;
  final MedicationPopupReminder? nextPendingSlot;

  const TodayMedicationProgress({
    required this.completedSlots,
    required this.totalSlots,
    required this.allSlots,
    this.nextPendingSlot,
  });

  double get ratio =>
      totalSlots <= 0 ? 0.0 : (completedSlots / totalSlots).clamp(0.0, 1.0);

  int get percent => (ratio * 100).round();

  String get fractionLabel => '$completedSlots/$totalSlots cữ';
}
