enum BloodPressureLevel {
  low,
  normal,
  elevated,
  highStage1,
  highStage2,
}

class DailyVitalLog {
  final String id;
  final String? userId;
  final String memberId;
  final String dateKey; // YYYY-MM-DD
  final DateTime measuredAt;
  final int systolic;
  final int diastolic;
  final int? heartRate;
  final BloodPressureLevel statusLevel;
  final String source; // 'manual' | 'ocr_scan' | 'medical_event'
  final String? imagePath;
  final String? note;

  const DailyVitalLog({
    required this.id,
    this.userId,
    this.memberId = 'primary',
    required this.dateKey,
    required this.measuredAt,
    required this.systolic,
    required this.diastolic,
    this.heartRate,
    required this.statusLevel,
    this.source = 'manual',
    this.imagePath,
    this.note,
  });

  String get formattedBp => '$systolic/$diastolic';

  String get formattedPulse =>
      heartRate != null && heartRate! > 0 ? '$heartRate nhịp/phút' : 'Chưa đo nhịp tim';

  String get statusLabelVi {
    switch (statusLevel) {
      case BloodPressureLevel.low:
        return 'Huyết áp thấp';
      case BloodPressureLevel.normal:
        return 'Huyết áp ổn định';
      case BloodPressureLevel.elevated:
        return 'Hơi cao nhẹ';
      case BloodPressureLevel.highStage1:
        return 'Tăng huyết áp độ 1';
      case BloodPressureLevel.highStage2:
        return 'Tăng huyết áp cao';
    }
  }

  String get seniorAdviceVi {
    switch (statusLevel) {
      case BloodPressureLevel.low:
        return 'Nên nằm nghỉ thoáng mát, uống thêm nước ấm. Đi khám nếu hoa mắt, chóng mặt.';
      case BloodPressureLevel.normal:
        return 'Chỉ số rất tốt! Hãy duy trì uống thuốc đều và vận động nhẹ hằng ngày.';
      case BloodPressureLevel.elevated:
        return 'Hơi cao nhẹ. Nên ngồi nghỉ ngơi 10–15 phút, ăn nhạt và đo kiểm tra lại.';
      case BloodPressureLevel.highStage1:
        return 'Cao hơn mức bình thường. Hãy kiểm tra đã uống cữ thuốc huyết áp hôm nay chưa.';
      case BloodPressureLevel.highStage2:
        return 'Chỉ số cao! Cần nghỉ ngơi ngay, liên hệ bác sĩ điều trị hoặc người thân hỗ trợ.';
    }
  }

  static BloodPressureLevel evaluateLevel(int systolic, int diastolic) {
    if (systolic < 90 || diastolic < 60) {
      return BloodPressureLevel.low;
    }
    if (systolic >= 160 || diastolic >= 100) {
      return BloodPressureLevel.highStage2;
    }
    if (systolic >= 140 || diastolic >= 90) {
      return BloodPressureLevel.highStage1;
    }
    if (systolic >= 130 || diastolic >= 85) {
      return BloodPressureLevel.elevated;
    }
    return BloodPressureLevel.normal;
  }

  static String formatDateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  DailyVitalLog copyWith({
    String? id,
    String? userId,
    String? memberId,
    String? dateKey,
    DateTime? measuredAt,
    int? systolic,
    int? diastolic,
    int? heartRate,
    BloodPressureLevel? statusLevel,
    String? source,
    String? imagePath,
    String? note,
  }) {
    final nextSys = systolic ?? this.systolic;
    final nextDia = diastolic ?? this.diastolic;
    return DailyVitalLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      memberId: memberId ?? this.memberId,
      dateKey: dateKey ?? this.dateKey,
      measuredAt: measuredAt ?? this.measuredAt,
      systolic: nextSys,
      diastolic: nextDia,
      heartRate: heartRate ?? this.heartRate,
      statusLevel: statusLevel ?? evaluateLevel(nextSys, nextDia),
      source: source ?? this.source,
      imagePath: imagePath ?? this.imagePath,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId ?? '',
      'member_id': memberId,
      'date_key': dateKey,
      'measured_at': measuredAt.toIso8601String(),
      'systolic': systolic,
      'diastolic': diastolic,
      'heart_rate': heartRate,
      'status_level': statusLevel.name,
      'source': source,
      'image_path': imagePath,
      'note': note,
    };
  }

  factory DailyVitalLog.fromMap(Map<String, dynamic> map) {
    final sys = (map['systolic'] as num?)?.toInt() ?? 120;
    final dia = (map['diastolic'] as num?)?.toInt() ?? 80;
    final rawLevel = map['status_level'] as String?;
    final parsedLevel = BloodPressureLevel.values.firstWhere(
      (e) => e.name == rawLevel,
      orElse: () => evaluateLevel(sys, dia),
    );
    return DailyVitalLog(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      memberId: (map['member_id'] as String?) ?? 'primary',
      dateKey: (map['date_key'] as String?) ?? formatDateKey(DateTime.now()),
      measuredAt: DateTime.tryParse((map['measured_at'] as String?) ?? '') ?? DateTime.now(),
      systolic: sys,
      diastolic: dia,
      heartRate: (map['heart_rate'] as num?)?.toInt(),
      statusLevel: parsedLevel,
      source: (map['source'] as String?) ?? 'manual',
      imagePath: map['image_path'] as String?,
      note: map['note'] as String?,
    );
  }
}

class YesterdayTodayBpComparison {
  final DailyVitalLog? yesterday;
  final DailyVitalLog? today;

  const YesterdayTodayBpComparison({
    this.yesterday,
    this.today,
  });

  String get comparisonSummaryVi {
    if (today == null && yesterday == null) {
      return 'Chưa có số đo hôm qua và hôm nay. Hãy đo huyết áp buổi sáng để theo dõi sức khỏe.';
    }
    if (today == null && yesterday != null) {
      return 'Hôm qua: ${yesterday!.formattedBp} mmHg (${yesterday!.statusLabelVi}). Mời bác cập nhật số đo hôm nay!';
    }
    if (today != null && yesterday == null) {
      return 'Hôm nay: ${today!.statusLabelVi}. ${today!.seniorAdviceVi}';
    }
    final dSys = today!.systolic - yesterday!.systolic;
    final dDia = today!.diastolic - yesterday!.diastolic;
    if (dSys.abs() <= 5 && dDia.abs() <= 5) {
      return 'Ổn định tương đương hôm qua (${today!.statusLabelVi}).';
    }
    if (dSys > 5) {
      return 'Tâm thu tăng +$dSys mmHg so với hôm qua. ${today!.seniorAdviceVi}';
    }
    return 'Tâm thu giảm ${dSys.abs()} mmHg so với hôm qua (${today!.statusLabelVi}).';
  }
}
