import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/medical_event.dart';
import '../../../../domain/repositories/medical_record_repository.dart';
import 'timeline_state.dart';

/// ViewModel quản lý trạng thái tìm kiếm, lọc và tương tác trên Dòng Thời Gian Bệnh Án.
class TimelineViewModel extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();
  final MedicalRecordRepository? repository;

  TimelineState _state = TimelineState.initial();
  bool _isLoading = false;

  TimelineViewModel({this.repository}) {
    loadRecords();
  }

  TimelineState get state => _state;
  bool get isLoading => _isLoading;

  Future<void> loadRecords() async {
    _isLoading = true;
    notifyListeners();

    try {
      final repo = repository ??
          (sl.isRegistered<MedicalRecordRepository>()
              ? sl<MedicalRecordRepository>()
              : null);
      if (repo != null) {
        final events = await repo.getMedicalTimeline();
        final mapped = events.map(_mapEventToTimelineItem).toList();

        final dynamicFilters = [
          TimelineFilterCategory(id: 'all', label: 'Tất cả (${mapped.length})'),
          const TimelineFilterCategory(id: 'checkup', label: 'Khám định kỳ'),
          const TimelineFilterCategory(
            id: 'emergency',
            label: 'Cấp cứu',
            dotColor: AppColors.iceDangerText,
            isDangerText: true,
          ),
          const TimelineFilterCategory(id: 'inpatient', label: 'Nội trú'),
          const TimelineFilterCategory(
            id: 'treating',
            label: 'Đang điều trị',
            dotColor: AppColors.timelineOlive,
          ),
        ];

        String? latestBp;
        String? latestHr;
        for (final e in events) {
          if (latestBp == null && e.bloodPressure != null && e.bloodPressure!.trim().isNotEmpty) {
            latestBp = e.bloodPressure!.trim();
          }
          if (latestHr == null && e.heartRate != null && e.heartRate!.trim().isNotEmpty) {
            latestHr = e.heartRate!.trim();
          }
        }

        _state = _state.copyWith(
          records: mapped,
          filters: dynamicFilters,
          latestBloodPressure: latestBp,
          latestHeartRate: latestHr,
        );
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteRecord(String id) async {
    try {
      final repo = repository ??
          (sl.isRegistered<MedicalRecordRepository>()
              ? sl<MedicalRecordRepository>()
              : null);
      if (repo != null) {
        await repo.deleteMedicalEvent(id);
        await loadRecords();
        notifyUser('Đã xóa đợt khám thành công.');
      }
    } catch (e) {
      notifyUser('Lỗi khi xóa đợt khám: $e');
    }
  }

  TimelineRecordItem _mapEventToTimelineItem(MedicalEvent event) {
    final year = event.date.year;
    final dayStr = event.date.day.toString().padLeft(2, '0');
    final monthStr = event.date.month.toString().padLeft(2, '0');
    final dateLabel = 'THÁNG $monthStr/$year · $dayStr/$monthStr';

    String categoryId = 'checkup';
    if (event.type == MedicalEventType.emergency) {
      categoryId = 'emergency';
    } else if (event.type == MedicalEventType.vaccination) {
      categoryId = 'vaccination';
    } else if (event.department != null &&
        event.department!.toLowerCase().contains('tiêu hóa')) {
      categoryId = 'treating';
    }

    TimelineDiagnosisBlock? diag;
    if (event.diagnosis != null && event.diagnosis!.isNotEmpty) {
      diag = TimelineDiagnosisBlock(
        sectionTitle: 'CHẨN ĐOÁN LÂM SÀNG',
        title: event.diagnosis!,
        description: event.description,
        isBoxed: true,
      );
    }

    TimelinePrescriptionSummary? rx;
    if (event.prescription != null &&
        event.prescription!.medicines.isNotEmpty) {
      final medCount = event.prescription!.medicines.length;
      final medNames =
          event.prescription!.medicines.take(2).map((m) => m.name).join(', ');
      rx = TimelinePrescriptionSummary(
        title: 'Đơn thuốc ngoại trú ($medCount loại)',
        subtitle: event.prescription!.doctorName.isNotEmpty
            ? '${event.prescription!.doctorName} · $medNames'
            : medNames,
      );
    }

    final docs = event.attachments.map((path) {
      final name = path.split('/').last;
      return AttachedMedicalDoc(
        title: name,
        imageAsset: path,
      );
    }).toList();

    return TimelineRecordItem(
      id: event.id,
      year: year,
      categoryId: categoryId,
      dateLabel: dateLabel,
      title: event.title,
      statusLabel: 'Hoàn thành',
      statusStyle: TimelineStatusStyle.highlightCream,
      spineDotColor: event.type == MedicalEventType.emergency
          ? AppColors.iceDangerText
          : AppColors.timelineOlive,
      facilityName: event.facilityName ?? 'Bệnh viện / Cơ sở Y tế',
      facilitySubtitle: event.doctorName != null && event.doctorName!.isNotEmpty
          ? 'BS. ${event.doctorName} · ${event.department ?? "Khoa khám"}'
          : (event.department ?? 'Đợt khám y tế'),
      facilityIconAsset: 'assets/icons/ic_hospital_clinic.svg',
      diagnosis: diag,
      attachedDocs: docs,
      prescription: rx,
      hospitalFee: event.hospitalFee,
    );
  }

  void updateSearchQuery(String query) {
    _state = _state.copyWith(searchQuery: query);
    notifyListeners();
  }

  void selectFilter(String filterId) {
    if (_state.selectedFilterId == filterId) return;
    _state = _state.copyWith(selectedFilterId: filterId);
    notifyListeners();
  }

  void notifyUser(String message) {
    _state = _state.copyWith(lastActionMessage: message);
    notifyListeners();
  }

  void clearActionMessage() {
    if (_state.lastActionMessage == null) return;
    _state = _state.copyWith(clearActionMessage: true);
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
