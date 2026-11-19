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
  final String? latestBloodPressure;
  final String? latestHeartRate;
  final String? latestSpo2;
  final String? latestBloodSugar;
  final String? lastActionMessage;

  const TimelineState({
    this.searchQuery = '',
    this.selectedFilterId = 'all',
    required this.filters,
    required this.records,
    this.latestBloodPressure,
    this.latestHeartRate,
    this.latestSpo2,
    this.latestBloodSugar,
    this.lastActionMessage,
  });

  factory TimelineState.initial() {
    return const TimelineState(
      filters: [
        TimelineFilterCategory(id: 'all', label: 'Tất cả (0)'),
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
      records: [],
      latestBloodPressure: null,
      latestHeartRate: null,
      latestSpo2: null,
      latestBloodSugar: null,
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
    List<TimelineFilterCategory>? filters,
    List<TimelineRecordItem>? records,
    String? latestBloodPressure,
    String? latestHeartRate,
    String? latestSpo2,
    String? latestBloodSugar,
    String? lastActionMessage,
    bool clearActionMessage = false,
  }) {
    return TimelineState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFilterId: selectedFilterId ?? this.selectedFilterId,
      filters: filters ?? this.filters,
      records: records ?? this.records,
      latestBloodPressure: latestBloodPressure ?? this.latestBloodPressure,
      latestHeartRate: latestHeartRate ?? this.latestHeartRate,
      latestSpo2: latestSpo2 ?? this.latestSpo2,
      latestBloodSugar: latestBloodSugar ?? this.latestBloodSugar,
      lastActionMessage: clearActionMessage
          ? null
          : (lastActionMessage ?? this.lastActionMessage),
    );
  }
}
