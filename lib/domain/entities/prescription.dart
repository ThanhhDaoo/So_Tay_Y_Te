import 'medicine.dart';

class Prescription {
  final String id;
  final String doctorName;
  final String? hospital;
  final DateTime issuedDate;
  final List<Medicine> medicines;
  final String? note;

  const Prescription({
    required this.id,
    required this.doctorName,
    this.hospital,
    required this.issuedDate,
    required this.medicines,
    this.note,
  });
}
