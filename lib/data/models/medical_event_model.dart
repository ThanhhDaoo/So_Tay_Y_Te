import '../../domain/entities/medical_event.dart';
import 'prescription_model.dart';

class MedicalEventModel extends MedicalEvent {
  const MedicalEventModel({
    required super.id,
    required super.title,
    super.description,
    required super.date,
    required super.type,
    super.prescription,
    super.attachments,
  });

  factory MedicalEventModel.fromJson(Map<String, dynamic> json) {
    return MedicalEventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      type: MedicalEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MedicalEventType.generalCheckup,
      ),
      prescription: json['prescription'] != null
          ? PrescriptionModel.fromJson(json['prescription'] as Map<String, dynamic>)
          : null,
      attachments: (json['attachments'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'type': type.name,
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
    };
  }

  MedicalEvent toEntity() => this;
}
