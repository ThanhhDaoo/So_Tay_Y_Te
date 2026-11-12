import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Danh mục lọc nhanh trên dòng thời gian.
class TimelineFilterCategory {
  final String id;
  final String label;
  final Color? dotColor;
  final bool isDangerText;

  const TimelineFilterCategory({
    required this.id,
    required this.label,
    this.dotColor,
    this.isDangerText = false,
  });
}

/// Tài liệu y tế đính kèm trong một đợt khám.
class AttachedMedicalDoc {
  final String title;
  final String imageAsset;

  const AttachedMedicalDoc({
    required this.title,
    required this.imageAsset,
  });
}

/// Tóm tắt đơn thuốc ngoại trú.
class TimelinePrescriptionSummary {
  final String title;
  final String subtitle;

  const TimelinePrescriptionSummary({
    required this.title,
    required this.subtitle,
  });
}

/// Khối chẩn đoán lâm sàng.
class TimelineDiagnosisBlock {
  final String sectionTitle;
  final String title;
  final String? description;
  final bool isBoxed;

  const TimelineDiagnosisBlock({
    required this.sectionTitle,
    required this.title,
    this.description,
    this.isBoxed = false,
  });
}

enum TimelineStatusStyle { highlightCream, neutralSoft, mutedChip }

/// Một sự kiện trên Dòng Thời Gian Bệnh Án.
class TimelineRecordItem {
  final String id;
  final int year;
  final String categoryId;
  final String dateLabel;
  final String title;
  final String statusLabel;
  final TimelineStatusStyle statusStyle;
  final Color spineDotColor;
  final String facilityName;
  final String facilitySubtitle;
  final String facilityIconAsset;
  final TimelineDiagnosisBlock? diagnosis;
  final List<AttachedMedicalDoc> attachedDocs;
  final TimelinePrescriptionSummary? prescription;
  final List<String> vaccines;
  final String? hospitalFee;

  const TimelineRecordItem({
    required this.id,
    required this.year,
    required this.categoryId,
    required this.dateLabel,
    required this.title,
    required this.statusLabel,
    required this.statusStyle,
    required this.spineDotColor,
    required this.facilityName,
    required this.facilitySubtitle,
    required this.facilityIconAsset,
    this.diagnosis,
    this.attachedDocs = const [],
    this.prescription,
    this.vaccines = const [],
    this.hospitalFee,
  });
}

/// State bất biến cho màn hình Dòng Thời Gian Bệnh Án (Life Timeline).
class TimelineState {
  final String searchQuery;
  final String selectedFilterId;
  final List<TimelineFilterCategory> filters;
  final List<TimelineRecordItem> records;
  final String? lastActionMessage;

  const TimelineState({
    this.searchQuery = '',
    this.selectedFilterId = 'all',
    required this.filters,
    required this.records,
    this.lastActionMessage,
  });

  factory TimelineState.initial() {
    return const TimelineState(
      filters: [
        TimelineFilterCategory(id: 'all', label: 'Tất cả (24)'),
        TimelineFilterCategory(id: 'checkup', label: 'Khám định kỳ'),
        TimelineFilterCategory(
          id: 'emergency',
          label: 'Cấp cứu',
          dotColor: AppColors.iceDangerText,
          isDangerText: true,
        ),
        TimelineFilterCategory(id: 'inpatient', label: 'Nội trú'),
        TimelineFilterCategory(
          id: 'treating',
          label: 'Đang điều trị',
          dotColor: AppColors.timelineOlive,
        ),
      ],
      records: [
        TimelineRecordItem(
          id: 'rec_2024_04',
          year: 2024,
          categoryId: 'treating',
          dateLabel: 'THÁNG 04/2024 · 18/04',
          title: 'Khám Nội tiêu hóa tổng quát',
          statusLabel: 'Hoàn thành',
          statusStyle: TimelineStatusStyle.highlightCream,
          spineDotColor: AppColors.timelineOlive,
          facilityName: 'BV Đại học Y Dược TP.HCM',
          facilitySubtitle: 'BS. Trần Văn Hùng · Khoa Tiêu hóa Gan mật',
          facilityIconAsset: 'assets/icons/ic_hospital_clinic.svg',
          diagnosis: TimelineDiagnosisBlock(
            sectionTitle: 'CHẨN ĐOÁN LÂM SÀNG',
            title: 'Viêm dạ dày - tá tràng mạn tính HP (+)',
            description:
                'Chỉ định phác đồ tiệt trừ HP 14 ngày & chế độ giảm axit dạ dày.',
            isBoxed: true,
          ),
          attachedDocs: [
            AttachedMedicalDoc(
              title: 'Nội soi dạ dày',
              imageAsset: 'assets/images/img_doc_endoscopy.png',
            ),
            AttachedMedicalDoc(
              title: 'Xét nghiệm máu',
              imageAsset: 'assets/images/img_doc_blood_test.png',
            ),
            AttachedMedicalDoc(
              title: 'Test HP nhanh',
              imageAsset: 'assets/images/img_doc_hp_test.png',
            ),
          ],
          hospitalFee: '1.450.000 đ',
        ),
        TimelineRecordItem(
          id: 'rec_2024_02',
          year: 2024,
          categoryId: 'checkup',
          dateLabel: 'THÁNG 02/2024 · 05/02',
          title: 'Khám Da liễu & Dị ứng',
          statusLabel: 'Đã khỏi',
          statusStyle: TimelineStatusStyle.neutralSoft,
          spineDotColor: AppColors.timelineDotMuted,
          facilityName: 'Bệnh viện Da Liễu TP.HCM',
          facilitySubtitle: 'Phòng khám chuyên gia Dị ứng miễn dịch',
          facilityIconAsset: 'assets/icons/ic_hospital_dermatology.svg',
          diagnosis: TimelineDiagnosisBlock(
            sectionTitle: 'CHẨN ĐOÁN',
            title: 'Viêm da tiếp xúc dị ứng thời tiết (mề đay cấp tính)',
            isBoxed: false,
          ),
          prescription: TimelinePrescriptionSummary(
            title: 'Đơn thuốc ngoại trú (04 loại)',
            subtitle: 'Thời gian dùng: 07 ngày · Kháng Histamin H1',
          ),
        ),
        TimelineRecordItem(
          id: 'rec_2023_11',
          year: 2023,
          categoryId: 'checkup',
          dateLabel: 'THÁNG 11/2023 · 14/11',
          title: 'Tiêm chủng Vắc-xin phòng bệnh',
          statusLabel: 'Định kỳ',
          statusStyle: TimelineStatusStyle.mutedChip,
          spineDotColor: AppColors.iceTextMuted,
          facilityName: 'Trung tâm Tiêm chủng VNVC',
          facilitySubtitle: 'Gói vắc-xin bảo vệ hô hấp người lớn',
          facilityIconAsset: 'assets/icons/ic_vaccine_center.svg',
          vaccines: [
            'Vắc xin Cúm mùa (Vaxigrip Tetra)',
            'Tdap (Bạch hầu - Uốn ván - Ho gà nhắc lại)',
          ],
        ),
      ],
    );
  }

  List<TimelineRecordItem> get filteredRecords {
    final query = searchQuery.trim().toLowerCase();
    return records.where((item) {
      final matchesFilter =
          selectedFilterId == 'all' || item.categoryId == selectedFilterId;
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      return item.title.toLowerCase().contains(query) ||
          item.facilityName.toLowerCase().contains(query) ||
          item.facilitySubtitle.toLowerCase().contains(query) ||
          (item.diagnosis?.title.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  TimelineState copyWith({
    String? searchQuery,
    String? selectedFilterId,
    String? lastActionMessage,
    bool clearActionMessage = false,
  }) {
    return TimelineState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFilterId: selectedFilterId ?? this.selectedFilterId,
      filters: filters,
      records: records,
      lastActionMessage: clearActionMessage
          ? null
          : (lastActionMessage ?? this.lastActionMessage),
    );
  }
}
