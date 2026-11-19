import 'dart:convert';
import '../../domain/entities/medical_event.dart';
import 'prescription_model.dart';

class MedicalEventModel extends MedicalEvent {
  const MedicalEventModel({
    required super.id,
    super.userId,
    required super.title,
    super.description,
    required super.date,
    required super.type,
    super.facilityName,
    super.doctorName,
    super.department,
    super.diagnosis,
    super.bloodPressure,
    super.heartRate,
    super.prescription,
    super.attachments,
    super.hospitalFee,
    super.createdAt,
    super.updatedAt,
  });

  factory MedicalEventModel.fromJson(Map<String, dynamic> json) {
    PrescriptionModel? pres;
    if (json['prescription'] != null) {
      if (json['prescription'] is Map<String, dynamic>) {
        pres = PrescriptionModel.fromJson(json['prescription'] as Map<String, dynamic>);
      } else if (json['prescription'] is String && (json['prescription'] as String).isNotEmpty) {
        try {
          pres = PrescriptionModel.fromJson(jsonDecode(json['prescription'] as String) as Map<String, dynamic>);
        } catch (_) {}
      }
    } else if (json['prescription_json'] != null && (json['prescription_json'] as String).isNotEmpty) {
      try {
        pres = PrescriptionModel.fromJson(jsonDecode(json['prescription_json'] as String) as Map<String, dynamic>);
      } catch (_) {}
    }

    List<String> parsedAttachments = [];
    if (json['attachments'] != null) {
      if (json['attachments'] is List) {
        parsedAttachments = (json['attachments'] as List<dynamic>).map((e) => e.toString()).toList();
      } else if (json['attachments'] is String && (json['attachments'] as String).isNotEmpty) {
        try {
          final decoded = jsonDecode(json['attachments'] as String);
          if (decoded is List) {
            parsedAttachments = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {
          parsedAttachments = (json['attachments'] as String).split(',').where((s) => s.isNotEmpty).toList();
        }
      }
    }

    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['date'] as String);
    } catch (_) {
      parsedDate = DateTime.now();
    }

    DateTime? createdAt;
    if (json['created_at'] != null) {
      try {
        createdAt = DateTime.parse(json['created_at'] as String);
      } catch (_) {}
    }

    DateTime? updatedAt;
    if (json['updated_at'] != null) {
      try {
        updatedAt = DateTime.parse(json['updated_at'] as String);
      } catch (_) {}
    }

    return MedicalEventModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      title: json['title'] as String? ?? 'Khám bệnh',
      description: json['description'] as String?,
      date: parsedDate,
      type: MedicalEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MedicalEventType.generalCheckup,
      ),
      facilityName: (json['facility_name'] ?? json['facility']) as String?,
      doctorName: (json['doctor_name'] ?? json['doctor']) as String?,
      department: json['department'] as String?,
      diagnosis: json['diagnosis'] as String?,
      bloodPressure: (json['blood_pressure'] ?? json['bp']) as String?,
      heartRate: (json['heart_rate'] ?? json['hr']) as String?,
      prescription: pres,
      attachments: parsedAttachments,
      hospitalFee: json['hospital_fee'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'type': type.name,
      'facility_name': facilityName,
      'doctor_name': doctorName,
      'department': department,
      'diagnosis': diagnosis,
      'blood_pressure': bloodPressure,
      'heart_rate': heartRate,
      'prescription': prescription != null
          ? (prescription is PrescriptionModel
              ? (prescription as PrescriptionModel).toJson()
              : PrescriptionModel(
                  id: prescription!.id,
                  doctorName: prescription!.doctorName,
                  hospital: prescription!.hospital,
                  issuedDate: prescription!.issuedDate,
                  medicines: prescription!.medicines,
                  note: prescription!.note,
                ).toJson())
          : null,
      'attachments': attachments,
      'hospital_fee': hospitalFee,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'type': type.name,
      'facility_name': facilityName,
      'doctor_name': doctorName,
      'department': department,
      'diagnosis': diagnosis,
      'blood_pressure': bloodPressure,
      'heart_rate': heartRate,
      'prescription_json': prescription != null
          ? jsonEncode((prescription is PrescriptionModel
              ? (prescription as PrescriptionModel).toJson()
              : PrescriptionModel(
                  id: prescription!.id,
                  doctorName: prescription!.doctorName,
                  hospital: prescription!.hospital,
                  issuedDate: prescription!.issuedDate,
                  medicines: prescription!.medicines,
                  note: prescription!.note,
                ).toJson()))
          : null,
      'attachments': jsonEncode(attachments),
      'hospital_fee': hospitalFee,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  MedicalEvent toEntity() => this;
}
