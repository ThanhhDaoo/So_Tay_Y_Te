import 'medicine.dart';

class Prescription {
  final String id;
  final String doctorName;
  final String? hospital;
  final DateTime issuedDate;
  final int? durationDays;
  final String status;
  final List<Medicine> medicines;
  final String? note;

  const Prescription({
    required this.id,
    required this.doctorName,
    this.hospital,
    required this.issuedDate,
    this.durationDays,
    this.status = 'active',
    required this.medicines,
    this.note,
  });

  bool get isExpiredByDuration {
    if (status == 'completed' || status == 'stopped') return true;
    final days = durationDays;
    if (days == null || days <= 0) return false;
    final endEndOfDay = DateTime(
      issuedDate.year,
      issuedDate.month,
      issuedDate.day,
      23,
      59,
      59,
    ).add(Duration(days: days));
    return DateTime.now().isAfter(endEndOfDay);
  }
}
