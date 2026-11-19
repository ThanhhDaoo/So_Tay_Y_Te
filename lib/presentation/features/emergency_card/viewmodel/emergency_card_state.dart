/// Thông tin liên hệ khẩn cấp (ICE, bác sĩ điều trị, tổng đài 115).
class EmergencyContactInfo {
  final String label;
  final String name;
  final String phone;

  const EmergencyContactInfo({
    required this.label,
    required this.name,
    required this.phone,
  });
}

/// Thông tin tổng quan bệnh nhân hiển thị trên thẻ cấp cứu.
class PatientSnapshotInfo {
  final String fullName;
  final String demographics;
  final String bloodType;
  final String rhFactor;
  final String height;
  final String weight;
  final String organDonorStatus;
  final String avatarAsset;

  const PatientSnapshotInfo({
    required this.fullName,
    required this.demographics,
    required this.bloodType,
    required this.rhFactor,
    required this.height,
    required this.weight,
    required this.organDonorStatus,
    required this.avatarAsset,
  });

  PatientSnapshotInfo copyWith({
    String? fullName,
    String? demographics,
    String? bloodType,
    String? rhFactor,
    String? height,
    String? weight,
    String? organDonorStatus,
    String? avatarAsset,
  }) {
    return PatientSnapshotInfo(
      fullName: fullName ?? this.fullName,
      demographics: demographics ?? this.demographics,
      bloodType: bloodType ?? this.bloodType,
      rhFactor: rhFactor ?? this.rhFactor,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      organDonorStatus: organDonorStatus ?? this.organDonorStatus,
      avatarAsset: avatarAsset ?? this.avatarAsset,
    );
  }
}

/// Cảnh báo dị ứng thuốc nghiêm trọng.
class DrugAllergyWarning {
  final String severityBadge;
  final String title;
  final String description;
  final bool isSevere;

  const DrugAllergyWarning({
    required this.severityBadge,
    required this.title,
    required this.description,
    this.isSevere = false,
  });
}

/// Một mục bệnh nền mãn tính cốt lõi.
class ChronicConditionItem {
  final String title;
  final String badgeLabel;
  final String note;
  final String iconAsset;
  final bool isCriticalBadge;

  const ChronicConditionItem({
    required this.title,
    required this.badgeLabel,
    required this.note,
    required this.iconAsset,
    this.isCriticalBadge = false,
  });
}

/// State bất biến cho màn hình Thẻ Cấp Cứu Khẩn Cấp (ICE).
class EmergencyCardState {
  final EmergencyContactInfo primaryContact;
  final EmergencyContactInfo doctorContact;
  final EmergencyContactInfo hotline115;
  final PatientSnapshotInfo patient;
  final DrugAllergyWarning allergyWarning;
  final List<ChronicConditionItem> chronicConditions;
  final String verifiedFooterText;
  final bool isLockScreenWidgetEnabled;
  final int selectedNavIndex;
  final String? lastActionMessage;

  const EmergencyCardState({
    required this.primaryContact,
    required this.doctorContact,
    required this.hotline115,
    required this.patient,
    required this.allergyWarning,
    required this.chronicConditions,
    required this.verifiedFooterText,
    this.isLockScreenWidgetEnabled = true,
    this.selectedNavIndex = 2,
    this.lastActionMessage,
  });

  factory EmergencyCardState.initial() {
    return const EmergencyCardState(
      primaryContact: EmergencyContactInfo(
        label: 'NGƯỜI THÂN KHẨN CẤP (ICE)',
        name: 'Chưa thiết lập',
        phone: '',
      ),
      doctorContact: EmergencyContactInfo(
        label: 'BS ĐIỀU TRỊ',
        name: 'Chưa thiết lập',
        phone: '',
      ),
      hotline115: EmergencyContactInfo(
        label: 'TỔNG ĐÀI',
        name: 'CẤP CỨU 115',
        phone: '115',
      ),
      patient: PatientSnapshotInfo(
        fullName: 'Chưa cập nhật',
        demographics: 'Chưa cập nhật thông tin',
        bloodType: '--',
        rhFactor: 'Chưa rõ',
        height: '-- cm',
        weight: '-- kg',
        organDonorStatus: 'CHƯA ĐĂNG KÝ',
        avatarAsset: 'assets/images/img_patient_avatar.png',
      ),
      allergyWarning: DrugAllergyWarning(
        severityBadge: 'AN TOÀN',
        title: 'Chưa ghi nhận dị ứng thuốc',
        description:
            'Hồ sơ chưa có thông tin cảnh báo dị ứng thuốc hoặc sốc phản vệ nguy hiểm.',
        isSevere: false,
      ),
      chronicConditions: [],
      verifiedFooterText: 'Hồ sơ cá nhân • Chưa liên kết CSYT',
      isLockScreenWidgetEnabled: true,
      selectedNavIndex: 2,
    );
  }

  EmergencyCardState copyWith({
    EmergencyContactInfo? primaryContact,
    EmergencyContactInfo? doctorContact,
    EmergencyContactInfo? hotline115,
    PatientSnapshotInfo? patient,
    DrugAllergyWarning? allergyWarning,
    List<ChronicConditionItem>? chronicConditions,
    String? verifiedFooterText,
    bool? isLockScreenWidgetEnabled,
    int? selectedNavIndex,
    String? lastActionMessage,
    bool clearActionMessage = false,
  }) {
    return EmergencyCardState(
      primaryContact: primaryContact ?? this.primaryContact,
      doctorContact: doctorContact ?? this.doctorContact,
      hotline115: hotline115 ?? this.hotline115,
      patient: patient ?? this.patient,
      allergyWarning: allergyWarning ?? this.allergyWarning,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      verifiedFooterText: verifiedFooterText ?? this.verifiedFooterText,
      isLockScreenWidgetEnabled:
          isLockScreenWidgetEnabled ?? this.isLockScreenWidgetEnabled,
      selectedNavIndex: selectedNavIndex ?? this.selectedNavIndex,
      lastActionMessage: clearActionMessage
          ? null
          : (lastActionMessage ?? this.lastActionMessage),
    );
  }
}

