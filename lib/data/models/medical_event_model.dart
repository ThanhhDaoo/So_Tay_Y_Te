import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../core/widgets/safe_avatar_image.dart';
import '../../domain/entities/medical_event.dart';
import 'prescription_model.dart';

class MedicalEventModel extends MedicalEvent {
  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  const MedicalEventModel({
    required super.id,
    super.userId,
    super.memberId = 'primary',
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
    super.spo2,
    super.temperature,
    super.prescription,
    super.attachments,
    super.hospitalFee,
    super.syncStatus = 'dirty',
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
  });

  /// Chuyển đổi định danh cũ (VD: `rec_173...`) sang UUID chuẩn RFC 4122 tất định (v5) khi gửi lên cột UUID PostgreSQL.
  static String ensureValidUuid(String rawId) {
    final trimmed = rawId.trim();
    if (_uuidRegex.hasMatch(trimmed)) return trimmed.toLowerCase();
    return const Uuid().v5(Namespace.url.value, 'sotayyte:$trimmed');
  }

  factory MedicalEventModel.fromJson(Map<String, dynamic> json) {
    PrescriptionModel? pres;
    if (json['prescription'] != null) {
      if (json['prescription'] is Map) {
        pres = PrescriptionModel.fromJson(Map<String, dynamic>.from(json['prescription'] as Map));
      } else if (json['prescription'] is String && (json['prescription'] as String).isNotEmpty) {
        try {
          pres = PrescriptionModel.fromJson(
            Map<String, dynamic>.from(jsonDecode(json['prescription'] as String) as Map),
          );
        } catch (_) {}
      }
    } else if (json['prescription_json'] != null) {
      if (json['prescription_json'] is Map) {
        pres = PrescriptionModel.fromJson(
          Map<String, dynamic>.from(json['prescription_json'] as Map),
        );
      } else if (json['prescription_json'] is String && (json['prescription_json'] as String).isNotEmpty) {
        try {
          pres = PrescriptionModel.fromJson(
            Map<String, dynamic>.from(jsonDecode(json['prescription_json'] as String) as Map),
          );
        } catch (_) {}
      }
    }

    List<String> parsedAttachments = [];
    if (json['attachments'] != null) {
      if (json['attachments'] is List) {
        parsedAttachments = (json['attachments'] as List<dynamic>)
            .map((e) => SafeAvatarHelper.resolveImagePath(e.toString()))
            .toList();
      } else if (json['attachments'] is String && (json['attachments'] as String).isNotEmpty) {
        try {
          final decoded = jsonDecode(json['attachments'] as String);
          if (decoded is List) {
            parsedAttachments = decoded
                .map((e) => SafeAvatarHelper.resolveImagePath(e.toString()))
                .toList();
          }
        } catch (_) {
          parsedAttachments = (json['attachments'] as String)
              .split(',')
              .where((s) => s.isNotEmpty)
              .map((e) => SafeAvatarHelper.resolveImagePath(e.trim()))
              .toList();
        }
      }
    }

    final rawDateStr = (json['date'] ?? json['event_date'])?.toString() ?? '';
    final parsedDate = DateTime.tryParse(rawDateStr) ?? DateTime.now();

    DateTime? createdAt;
    if (json['created_at'] != null) {
      createdAt = DateTime.tryParse(json['created_at'].toString());
    }

    DateTime? updatedAt;
    if (json['updated_at'] != null) {
      updatedAt = DateTime.tryParse(json['updated_at'].toString());
    }

    DateTime? deletedAt;
    if (json['deleted_at'] != null && json['deleted_at'].toString().isNotEmpty) {
      deletedAt = DateTime.tryParse(json['deleted_at'].toString());
    }

    final rawType = (json['type'] ?? json['event_type'])?.toString();
    final rawMember = (json['member_id'] as String?)?.trim();

    return MedicalEventModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      memberId: (rawMember != null && rawMember.isNotEmpty) ? rawMember : 'primary',
      title: json['title'] as String? ?? 'Khám bệnh',
      description: json['description'] as String?,
      date: parsedDate,
      type: MedicalEventType.values.firstWhere(
        (e) => e.name == rawType,
        orElse: () => MedicalEventType.generalCheckup,
      ),
      facilityName: (json['facility_name'] ?? json['hospital'] ?? json['facility']) as String?,
      doctorName: (json['doctor_name'] ?? json['doctor']) as String?,
      department: json['department'] as String?,
      diagnosis: json['diagnosis'] as String?,
      bloodPressure: (json['blood_pressure'] ?? json['bp']) as String?,
      heartRate: (json['heart_rate'] ?? json['hr']) as String?,
      spo2: json['spo2'] as String?,
      temperature: json['temperature'] as String?,
      prescription: pres,
      attachments: parsedAttachments,
      hospitalFee: json['hospital_fee']?.toString(),
      syncStatus: (json['sync_status'] as String?) ?? 'synced',
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  Map<String, dynamic> _prescriptionMap() {
    final p = prescription!;
    if (p is PrescriptionModel) return p.toJson();
    return PrescriptionModel(
      id: p.id,
      doctorName: p.doctorName,
      hospital: p.hospital,
      issuedDate: p.issuedDate,
      durationDays: p.durationDays,
      status: p.status,
      medicines: p.medicines,
      note: p.note,
    ).toJson();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'member_id': memberId,
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
      'spo2': spo2,
      'temperature': temperature,
      'prescription': prescription != null ? _prescriptionMap() : null,
      'attachments': attachments,
      'hospital_fee': hospitalFee,
      'sync_status': syncStatus,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toSqliteMap() {
    final nowIso = DateTime.now().toIso8601String();
    return {
      'id': id,
      'user_id': userId,
      'member_id': memberId.isNotEmpty ? memberId : 'primary',
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
      'spo2': spo2,
      'temperature': temperature,
      'prescription_json': prescription != null ? jsonEncode(_prescriptionMap()) : null,
      'attachments': jsonEncode(attachments),
      'hospital_fee': hospitalFee,
      'sync_status': syncStatus,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'updated_at': updatedAt?.toIso8601String() ?? nowIso,
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  /// Ánh xạ chuẩn 1:1 với bảng PostgreSQL `public.medical_events` trên Supabase Cloud.
  Map<String, dynamic> toSupabaseMap({String? overrideUserId, List<String>? cloudAttachments}) {
    final nowIso = DateTime.now().toIso8601String();
    return {
      'id': ensureValidUuid(id),
      'user_id': overrideUserId ?? userId,
      'member_id': memberId.isNotEmpty ? memberId : 'primary',
      'title': title,
      'description': description,
      'facility_name': facilityName,
      'hospital': facilityName,
      'doctor_name': doctorName,
      'department': department,
      'diagnosis': diagnosis,
      'blood_pressure': bloodPressure,
      'heart_rate': heartRate,
      'spo2': spo2,
      'temperature': temperature,
      'prescription_json': prescription != null ? _prescriptionMap() : null,
      'hospital_fee': hospitalFee,
      'event_date': date.toIso8601String(),
      'event_type': type.name,
      'attachments': cloudAttachments ?? attachments,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'updated_at': updatedAt?.toIso8601String() ?? nowIso,
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  MedicalEvent toEntity() => this;
}
