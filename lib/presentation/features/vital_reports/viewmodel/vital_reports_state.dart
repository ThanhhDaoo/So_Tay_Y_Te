enum VitalMetricType {
  bloodPressure,
  bloodGlucose,
  heartRate,
  bmiAndWeight,
}

enum VitalTimeframe {
  week,
  month,
}

enum ExportActionType {
  none,
  pdf,
  print,
  sendDoctor,
}

class VitalChartPoint {
  final String dayLabel;
  final int systolic;
  final int diastolic;
  final bool isLatest;

  const VitalChartPoint({
    required this.dayLabel,
    required this.systolic,
    required this.diastolic,
    this.isLatest = false,
  });
}

class DiagnosticEncounter {
  final String date;
  final String facility;
  final String diagnosis;
  final String resultBadge;

  const DiagnosticEncounter({
    required this.date,
    required this.facility,
    required this.diagnosis,
    required this.resultBadge,
  });
}

class PrescriptionSummaryItem {
  final String order;
  final String name;
  final String dosage;

  const PrescriptionSummaryItem({
    required this.order,
    required this.name,
    required this.dosage,
  });
}

class VitalReportsState {
  final VitalMetricType selectedMetric;
  final VitalTimeframe selectedTimeframe;
  final ExportActionType exportingAction;
  final String? notificationMessage;

  // Patient dossier info
  final String patientName;
  final String patientDob;
  final String patientBloodGroup;
  final String patientNationalId;
  final String dossierCode;
  final String doctorName;
  final String signatureSha256;

  // Vitals summary
  final String latestValue;
  final String latestUnit;
  final String latestTimestamp;
  final String latestClassification;
  final String monitoringFrequency;
  final String monitoringSchedule;
  final String compliancePercent;
  final String monthlyAverageBp;
  final String monthlyAverageHeart;

  // Chart data points
  final List<VitalChartPoint> chartPoints;
  final List<PrescriptionSummaryItem> activePrescriptions;
  final List<DiagnosticEncounter> recentEncounters;

  const VitalReportsState({
    this.selectedMetric = VitalMetricType.bloodPressure,
    this.selectedTimeframe = VitalTimeframe.week,
    this.exportingAction = ExportActionType.none,
    this.notificationMessage,
    this.patientName = 'Nguyễn Văn An',
    this.patientDob = '14/08/1984 (40t)',
    this.patientBloodGroup = 'O+ Rh Dương',
    this.patientNationalId = '001084******',
    this.dossierCode = '#MV-892401',
    this.doctorName = 'TS.BS. Lê Quang Minh',
    this.signatureSha256 = 'SHA256: 7f8a9...b401',
    this.latestValue = '118/78',
    this.latestUnit = 'mmHg',
    this.latestTimestamp = 'Hôm nay 07:15',
    this.latestClassification = 'Tối ưu (WHO)',
    this.monitoringFrequency = 'Đều đặn 2 lần/ngày',
    this.monitoringSchedule = 'Sáng (07:00) • Tối (20:30)',
    this.compliancePercent = '96%',
    this.monthlyAverageBp = '119/79',
    this.monthlyAverageHeart = '73',
    this.chartPoints = const [
      VitalChartPoint(dayLabel: 'T2', systolic: 122, diastolic: 81),
      VitalChartPoint(dayLabel: 'T3', systolic: 125, diastolic: 82),
      VitalChartPoint(dayLabel: 'T4', systolic: 120, diastolic: 79),
      VitalChartPoint(dayLabel: 'T5', systolic: 124, diastolic: 82),
      VitalChartPoint(dayLabel: 'T6', systolic: 123, diastolic: 81),
      VitalChartPoint(dayLabel: 'T7', systolic: 121, diastolic: 80),
      VitalChartPoint(dayLabel: 'Hôm nay', systolic: 118, diastolic: 78, isLatest: true),
    ],
    this.activePrescriptions = const [
      PrescriptionSummaryItem(
        order: '1.',
        name: 'Amlodipine 5mg',
        dosage: '1 viên/ngày (08:00 sáng)',
      ),
      PrescriptionSummaryItem(
        order: '2.',
        name: 'Rosuvastatin 10mg',
        dosage: '1 viên/tối sau ăn',
      ),
    ],
    this.recentEncounters = const [
      DiagnosticEncounter(
        date: '15/10/2024',
        facility: 'BV Bạch Mai',
        diagnosis: 'Khám Tim Mạch Định Kỳ',
        resultBadge: 'HA 118/78',
      ),
      DiagnosticEncounter(
        date: '12/07/2024',
        facility: 'BV Đại Học Y',
        diagnosis: 'Xét nghiệm Sinh hóa máu',
        resultBadge: 'HbA1c 5.4%',
      ),
      DiagnosticEncounter(
        date: '03/04/2024',
        facility: 'Phòng khám Chuyên khoa',
        diagnosis: 'Khám tổng quát & Siêu âm Doppler tim',
        resultBadge: 'Bình thường',
      ),
    ],
  });

  VitalReportsState copyWith({
    VitalMetricType? selectedMetric,
    VitalTimeframe? selectedTimeframe,
    ExportActionType? exportingAction,
    String? notificationMessage,
    String? patientName,
    String? patientDob,
    String? patientBloodGroup,
    String? patientNationalId,
    String? dossierCode,
    String? doctorName,
    String? signatureSha256,
    String? latestValue,
    String? latestUnit,
    String? latestTimestamp,
    String? latestClassification,
    String? monitoringFrequency,
    String? monitoringSchedule,
    String? compliancePercent,
    String? monthlyAverageBp,
    String? monthlyAverageHeart,
    List<VitalChartPoint>? chartPoints,
    List<PrescriptionSummaryItem>? activePrescriptions,
    List<DiagnosticEncounter>? recentEncounters,
  }) {
    return VitalReportsState(
      selectedMetric: selectedMetric ?? this.selectedMetric,
      selectedTimeframe: selectedTimeframe ?? this.selectedTimeframe,
      exportingAction: exportingAction ?? this.exportingAction,
      notificationMessage: notificationMessage,
      patientName: patientName ?? this.patientName,
      patientDob: patientDob ?? this.patientDob,
      patientBloodGroup: patientBloodGroup ?? this.patientBloodGroup,
      patientNationalId: patientNationalId ?? this.patientNationalId,
      dossierCode: dossierCode ?? this.dossierCode,
      doctorName: doctorName ?? this.doctorName,
      signatureSha256: signatureSha256 ?? this.signatureSha256,
      latestValue: latestValue ?? this.latestValue,
      latestUnit: latestUnit ?? this.latestUnit,
      latestTimestamp: latestTimestamp ?? this.latestTimestamp,
      latestClassification: latestClassification ?? this.latestClassification,
      monitoringFrequency: monitoringFrequency ?? this.monitoringFrequency,
      monitoringSchedule: monitoringSchedule ?? this.monitoringSchedule,
      compliancePercent: compliancePercent ?? this.compliancePercent,
      monthlyAverageBp: monthlyAverageBp ?? this.monthlyAverageBp,
      monthlyAverageHeart: monthlyAverageHeart ?? this.monthlyAverageHeart,
      chartPoints: chartPoints ?? this.chartPoints,
      activePrescriptions: activePrescriptions ?? this.activePrescriptions,
      recentEncounters: recentEncounters ?? this.recentEncounters,
    );
  }
}

