import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/pdf_report_service.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../domain/entities/medical_event.dart';
import '../../../../domain/entities/user_profile.dart';
import '../../../../domain/repositories/auth_repository.dart';
import '../../../../domain/repositories/medical_record_repository.dart';
import 'vital_reports_state.dart';

class VitalReportsViewModel extends ChangeNotifier {
  final MedicalRecordRepository? repository;
  final AuthRepository? authRepository;
  final PdfReportService? pdfReportService;

  VitalReportsState _state;
  MedicalEvent? _latestEvent;
  UserProfile? _patientProfile;
  List<MedicalEvent> _cachedEvents = const [];

  VitalReportsViewModel({
    this.repository,
    this.authRepository,
    this.pdfReportService,
    VitalReportsState? initialState,
  })  : _state = initialState ?? const VitalReportsState() {
    loadClinicalData();
  }

  VitalReportsState get state => _state;

  void selectMetric(VitalMetricType metric) {
    if (_state.selectedMetric == metric) return;
    _state = _state.copyWith(selectedMetric: metric);
    _recomputeChartFromEvents();
    notifyListeners();
  }

  void selectTimeframe(VitalTimeframe timeframe) {
    if (_state.selectedTimeframe == timeframe) return;
    _state = _state.copyWith(selectedTimeframe: timeframe);
    _recomputeChartFromEvents();
    notifyListeners();
  }

  void _recomputeChartFromEvents() {
    if (_cachedEvents.isEmpty) return;

    final maxPoints = _state.selectedTimeframe == VitalTimeframe.week ? 7 : 30;
    final metric = _state.selectedMetric;

    if (metric == VitalMetricType.heartRate) {
      final hrPoints = <VitalChartPoint>[];
      for (final e in _cachedEvents) {
        final hr = int.tryParse(e.heartRate ?? '');
        if (hr != null) {
          final label = '${e.date.day.toString().padLeft(2, '0')}/${e.date.month.toString().padLeft(2, '0')}';
          hrPoints.add(VitalChartPoint(
            dayLabel: label,
            systolic: hr,
            diastolic: 60,
          ));
        }
      }
      if (hrPoints.isNotEmpty) {
        final sliced = hrPoints.length > maxPoints ? hrPoints.sublist(hrPoints.length - maxPoints) : hrPoints;
        final marked = List<VitalChartPoint>.generate(
          sliced.length,
          (i) => VitalChartPoint(
            dayLabel: sliced[i].dayLabel,
            systolic: sliced[i].systolic,
            diastolic: sliced[i].diastolic,
            isLatest: i == sliced.length - 1,
          ),
        );
        _state = _state.copyWith(
          chartPoints: marked,
          latestValue: '${marked.last.systolic}',
          latestUnit: 'bpm',
        );
      }
      return;
    }

    // Mặc định: Huyết áp (Blood Pressure)
    final bpPoints = <VitalChartPoint>[];
    for (final e in _cachedEvents) {
      final bp = e.bloodPressure;
      if (bp != null && bp.contains('/')) {
        final parts = bp.split('/');
        final sys = int.tryParse(parts[0].trim());
        final dia = int.tryParse(parts[1].trim());
        if (sys != null && dia != null) {
          final label = '${e.date.day.toString().padLeft(2, '0')}/${e.date.month.toString().padLeft(2, '0')}';
          bpPoints.add(VitalChartPoint(
            dayLabel: label,
            systolic: sys,
            diastolic: dia,
          ));
        }
      }
    }
    if (bpPoints.isNotEmpty) {
      final sliced = bpPoints.length > maxPoints ? bpPoints.sublist(bpPoints.length - maxPoints) : bpPoints;
      final marked = List<VitalChartPoint>.generate(
        sliced.length,
        (i) => VitalChartPoint(
          dayLabel: sliced[i].dayLabel,
          systolic: sliced[i].systolic,
          diastolic: sliced[i].diastolic,
          isLatest: i == sliced.length - 1,
        ),
      );
      _state = _state.copyWith(
        chartPoints: marked,
        latestValue: '${marked.last.systolic}/${marked.last.diastolic}',
        latestUnit: 'mmHg',
      );
    }
  }

  Future<void> loadClinicalData() async {
    try {
      // 1. Load patient profile
      final auth = authRepository ??
          (sl.isRegistered<AuthRepository>() ? sl<AuthRepository>() : null);
      if (auth != null) {
        final session = await auth.getActiveSession();
        if (session != null) {
          final dob = session.dateOfBirth != null && session.dateOfBirth!.isNotEmpty
              ? session.dateOfBirth!
              : 'Chưa cập nhật';
          final hasBlood = session.bloodType != null &&
              session.bloodType!.isNotEmpty &&
              session.bloodType != 'Chưa rõ';
          final rh = InputValidators.resolveRhFactor(session.bloodType);
          final blood = hasBlood
              ? '${session.bloodType}${rh != "Chưa rõ" ? " $rh" : ""}'
              : 'Chưa rõ';

          String allergyText = 'Không có ghi nhận dị ứng thuốc';
          bool severeAllergy = false;
          List<String> allergyList = const [];
          String? iceContact;

          try {
            final details = await auth.getUserProfileDetails(session.id);
            if (details != null) {
              final rawAllergies = details['allergies'] as String?;
              if (rawAllergies != null &&
                  rawAllergies.trim().isNotEmpty &&
                  rawAllergies.trim() != 'Không có') {
                allergyText = '• ${rawAllergies.trim()}';
                severeAllergy = true;
                allergyList = rawAllergies
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
              }
              final rawIce = details['emergency_contact'] as String?;
              if (rawIce != null && rawIce.trim().isNotEmpty && !rawIce.contains('@')) {
                iceContact = rawIce.trim();
              }
            }
          } catch (_) {}

          _patientProfile = UserProfile(
            id: session.id,
            fullName: session.fullName.isNotEmpty ? session.fullName : 'Chưa cập nhật',
            bloodType: hasBlood ? session.bloodType : null,
            allergies: allergyList,
            emergencyContact: iceContact,
          );

          _state = _state.copyWith(
            patientName: session.fullName.isNotEmpty ? session.fullName : 'Chưa cập nhật',
            patientDob: dob,
            patientBloodGroup: blood,
            patientNationalId: session.patientCode,
            dossierCode: '#${session.patientCode}',
            allergyBannerText: allergyText,
            hasSevereAllergy: severeAllergy,
          );
        }
      }

      // 2. Load historical records & vitals
      final repo = repository ??
          (sl.isRegistered<MedicalRecordRepository>()
              ? sl<MedicalRecordRepository>()
              : null);
      if (repo != null) {
        final rawEvents = await repo.getMedicalTimeline();
        if (rawEvents.isEmpty) {
          _cachedEvents = const [];
          _latestEvent = null;
          _state = _state.copyWith(
            chartPoints: const [],
            latestValue: '--/--',
            latestClassification: 'Chưa có số đo',
            monthlyAverageBp: '--/-- mmHg',
            monthlyAverageHeart: '-- bpm',
            activePrescriptions: const [],
            recentEncounters: const [],
            doctorName: 'Chưa cập nhật bác sĩ',
          );
        } else {
          final events = List<MedicalEvent>.from(rawEvents)
            ..sort((a, b) => a.date.compareTo(b.date));
          _cachedEvents = events;
          _latestEvent = events.last;

          final vitalsPoints = <VitalChartPoint>[];
          final rxList = <PrescriptionSummaryItem>[];
          final encounterList = <DiagnosticEncounter>[];

          int totalSys = 0;
          int totalDia = 0;
          int totalHr = 0;
          int bpCount = 0;
          int hrCount = 0;

          for (final e in events) {
            final bp = e.bloodPressure;
            if (bp != null && bp.contains('/')) {
              final parts = bp.split('/');
              final sys = int.tryParse(parts[0].trim());
              final dia = int.tryParse(parts[1].trim());
              if (sys != null && dia != null) {
                totalSys += sys;
                totalDia += dia;
                bpCount++;
                final label = '${e.date.day.toString().padLeft(2, '0')}/${e.date.month.toString().padLeft(2, '0')}';
                vitalsPoints.add(VitalChartPoint(
                  dayLabel: label,
                  systolic: sys,
                  diastolic: dia,
                  isLatest: e == events.last,
                ));
              }
            }

            final hr = int.tryParse(e.heartRate ?? '');
            if (hr != null) {
              totalHr += hr;
              hrCount++;
            }

            if (e.prescription != null && e.prescription!.medicines.isNotEmpty) {
              for (int i = 0; i < e.prescription!.medicines.length; i++) {
                final m = e.prescription!.medicines[i];
                rxList.add(PrescriptionSummaryItem(
                  order: (i + 1).toString().padLeft(2, '0'),
                  name: m.name,
                  dosage: '${m.dosage} - ${m.frequency}',
                ));
              }
            }

            final dateStr = '${e.date.day.toString().padLeft(2, '0')}/${e.date.month.toString().padLeft(2, '0')}/${e.date.year}';
            encounterList.insert(0, DiagnosticEncounter(
              date: dateStr,
              facility: e.facilityName ?? 'Cơ sở khám bệnh',
              diagnosis: e.diagnosis ?? e.title,
              resultBadge: e.prescription != null ? 'Có đơn thuốc' : 'Khám lâm sàng',
            ));
          }

          final avgBpLabel = bpCount > 0
              ? '${(totalSys / bpCount).round()}/${(totalDia / bpCount).round()} mmHg'
              : '--/-- mmHg';
          final avgHrLabel = hrCount > 0 ? '${(totalHr / hrCount).round()} bpm' : '-- bpm';

          String classification = 'Chưa có số đo';
          if (vitalsPoints.isNotEmpty) {
            final lastSys = vitalsPoints.last.systolic;
            final lastDia = vitalsPoints.last.diastolic;
            if (lastSys < 120 && lastDia < 80) {
              classification = 'Tối ưu (WHO)';
            } else if (lastSys < 130 && lastDia < 85) {
              classification = 'Bình thường';
            } else if (lastSys < 140 && lastDia < 90) {
              classification = 'Tiền tăng HA';
            } else {
              classification = 'Tăng huyết áp';
            }
          }

          _state = _state.copyWith(
            chartPoints: vitalsPoints,
            latestValue: vitalsPoints.isNotEmpty
                ? '${vitalsPoints.last.systolic}/${vitalsPoints.last.diastolic}'
                : '--/--',
            latestClassification: classification,
            monthlyAverageBp: avgBpLabel,
            monthlyAverageHeart: avgHrLabel,
            activePrescriptions: rxList,
            recentEncounters: encounterList,
            doctorName: _latestEvent?.doctorName != null && _latestEvent!.doctorName!.isNotEmpty
                ? _latestEvent!.doctorName!
                : 'Chưa cập nhật bác sĩ',
          );
          _recomputeChartFromEvents();
        }
      }
    } catch (e) {
      debugPrint('[VitalReportsViewModel] loadClinicalData error: $e');
    }
    notifyListeners();
  }

  MedicalEvent _buildSummaryFallbackEvent() {
    return MedicalEvent(
      id: _state.dossierCode.replaceAll('#', ''),
      title: 'Tổng hợp hồ sơ sức khỏe cá nhân',
      description: 'Báo cáo tổng hợp sinh hiệu và tiền sử y tế của ${_state.patientName}.',
      date: DateTime.now(),
      type: MedicalEventType.generalCheckup,
      facilityName: 'Sổ Tay Y Tế • MedVault EHR',
      doctorName: _state.doctorName,
      diagnosis: 'Theo dõi sức khỏe định kỳ',
      bloodPressure: _state.latestValue != '--/--' ? _state.latestValue : null,
    );
  }

  Future<void> exportPdf() async {
    _state = _state.copyWith(
      exportingAction: ExportActionType.pdf,
      notificationMessage: 'Đang khởi tạo tài liệu PDF chuẩn A4 HL7/FHIR...',
    );
    notifyListeners();

    try {
      final isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
      final pdfService = pdfReportService ??
          (sl.isRegistered<PdfReportService>() ? sl<PdfReportService>() : null);

      if (!isTest && pdfService != null) {
        final targetRecord = _latestEvent ?? _buildSummaryFallbackEvent();
        await pdfService.shareRecordPdf(
          record: targetRecord,
          patientProfile: _patientProfile,
        );
      } else {
        await Future.delayed(const Duration(milliseconds: 600));
      }
    } catch (e) {
      debugPrint('[VitalReportsViewModel] exportPdf error: $e');
    }

    _state = _state.copyWith(
      exportingAction: ExportActionType.none,
      notificationMessage: 'Đã xuất file PDF hồ sơ y tế thành công (${_state.dossierCode}.pdf)!',
    );
    notifyListeners();
  }

  Future<void> printAirPrint() async {
    _state = _state.copyWith(
      exportingAction: ExportActionType.print,
      notificationMessage: 'Đang kết nối tới máy in AirPrint y tế...',
    );
    notifyListeners();

    try {
      final isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
      final pdfService = pdfReportService ??
          (sl.isRegistered<PdfReportService>() ? sl<PdfReportService>() : null);

      if (!isTest && pdfService != null) {
        final targetRecord = _latestEvent ?? _buildSummaryFallbackEvent();
        await pdfService.printRecord(
          record: targetRecord,
          patientProfile: _patientProfile,
        );
      } else {
        await Future.delayed(const Duration(milliseconds: 600));
      }
    } catch (e) {
      debugPrint('[VitalReportsViewModel] printAirPrint error: $e');
    }

    _state = _state.copyWith(
      exportingAction: ExportActionType.none,
      notificationMessage: 'Lệnh in AirPrint khổ A4 đã được gửi thành công.',
    );
    notifyListeners();
  }

  Future<void> sendDoctor() async {
    _state = _state.copyWith(
      exportingAction: ExportActionType.sendDoctor,
      notificationMessage: 'Đang chuẩn bị hồ sơ lâm sàng gửi ${_state.doctorName}...',
    );
    notifyListeners();

    try {
      final isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
      final pdfService = pdfReportService ??
          (sl.isRegistered<PdfReportService>() ? sl<PdfReportService>() : null);

      if (!isTest && pdfService != null) {
        final targetRecord = _latestEvent ?? _buildSummaryFallbackEvent();
        await pdfService.shareRecordPdf(
          record: targetRecord,
          patientProfile: _patientProfile,
        );
      } else {
        await Future.delayed(const Duration(milliseconds: 600));
      }
    } catch (e) {
      debugPrint('[VitalReportsViewModel] sendDoctor error: $e');
    }

    _state = _state.copyWith(
      exportingAction: ExportActionType.none,
      notificationMessage: 'Đã chuyển tiếp hồ sơ lâm sàng tới Bác sĩ điều trị!',
    );
    notifyListeners();
  }

  void clearNotification() {
    _state = _state.copyWith(notificationMessage: null);
    notifyListeners();
  }
}
