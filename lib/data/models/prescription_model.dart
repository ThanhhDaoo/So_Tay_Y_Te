import '../../domain/entities/medicine.dart';
import '../../domain/entities/prescription.dart';

class MedicineModel extends Medicine {
  const MedicineModel({
    required super.id,
    required super.name,
    required super.dosage,
    required super.frequency,
    super.instructions,
  });

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    return MedicineModel(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      dosage: (json['dosage'] as String?) ?? '',
      frequency: (json['frequency'] as String?) ?? '',
      instructions: json['instructions'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'instructions': instructions,
    };
  }
}

class PrescriptionModel extends Prescription {
  const PrescriptionModel({
    required super.id,
    required super.doctorName,
    super.hospital,
    required super.issuedDate,
    super.durationDays,
    super.status = 'active',
    required super.medicines,
    super.note,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: (json['id'] as String?) ?? '',
      doctorName: (json['doctor_name'] as String?) ?? '',
      hospital: json['hospital'] as String?,
      issuedDate: DateTime.tryParse((json['issued_date'] as String?) ?? '') ?? DateTime.now(),
      durationDays: json['duration_days'] is int
          ? json['duration_days'] as int
          : int.tryParse('${json['duration_days'] ?? ''}'),
      status: (json['status'] as String?) ?? 'active',
      medicines: (json['medicines'] as List<dynamic>?)
              ?.map((item) => MedicineModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList() ??
          [],
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctor_name': doctorName,
      'hospital': hospital,
      'issued_date': issuedDate.toIso8601String(),
      'duration_days': durationDays,
      'status': status,
      'medicines': medicines.map((m) {
        if (m is MedicineModel) return m.toJson();
        return MedicineModel(
          id: m.id,
          name: m.name,
          dosage: m.dosage,
          frequency: m.frequency,
          instructions: m.instructions,
        ).toJson();
      }).toList(),
      'note': note,
    };
  }

  Prescription toEntity() => this;
}
