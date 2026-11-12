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
}

/// Cảnh báo dị ứng thuốc nghiêm trọng.
class DrugAllergyWarning {
  final String severityBadge;
  final String title;
  final String description;

  const DrugAllergyWarning({
    required this.severityBadge,
    required this.title,
    required this.description,
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
        name: 'Anh Minh (Chồng)',
        phone: '0988 123 456',
      ),
      doctorContact: EmergencyContactInfo(
        label: 'BS ĐIỀU TRỊ',
        name: 'BS. CKII Lê Hoàng',
        phone: '0909 112 233',
      ),
      hotline115: EmergencyContactInfo(
        label: 'TỔNG ĐÀI',
        name: 'CẤP CỨU 115',
        phone: '115',
      ),
      patient: PatientSnapshotInfo(
        fullName: 'Nguyễn Thu Trang',
        demographics: 'Nữ • 32 tuổi (14/05/1992)',
        bloodType: 'O+',
        rhFactor: 'Rh Dương',
        height: '162 cm',
        weight: '54 kg',
        organDonorStatus: 'ĐÃ ĐĂNG KÝ',
        avatarAsset: 'assets/images/img_patient_avatar.png',
      ),
      allergyWarning: DrugAllergyWarning(
        severityBadge: 'CẤP ĐỘ 3',
        title: 'DỊ ỨNG PENICILLIN & ASPIRIN',
        description:
            'Nguy cơ sốc phản vệ nặng (Phản ứng độ 3: phù Quincke, co thắt thanh quản). Tuyệt đối không dùng kháng sinh nhóm Beta-lactam và NSAID không chọn lọc.',
      ),
      chronicConditions: [
        ChronicConditionItem(
          title: 'Hen phế quản mãn tính (Asthma)',
          badgeLabel: 'GĐ 2',
          note: 'Mang theo thuốc cắt cơn Ventolin Inhaler 100mcg trong túi xách.',
          iconAsset: 'assets/icons/ic_asthma_wind.svg',
        ),
        ChronicConditionItem(
          title: 'Tiền sử nhịp tim nhanh kịch phát',
          badgeLabel: 'PSVT',
          note: 'Cơn kịch phát gần nhất tháng 11/2024. Đang theo dõi tại BV Chợ Rẫy.',
          iconAsset: 'assets/icons/ic_ecg_pulse.svg',
          isCriticalBadge: true,
        ),
      ],
      verifiedFooterText: 'Được xác thực bởi BV Chợ Rẫy • Cập nhật 02 giờ trước',
      isLockScreenWidgetEnabled: true,
      selectedNavIndex: 2,
    );
  }

  EmergencyCardState copyWith({
    bool? isLockScreenWidgetEnabled,
    int? selectedNavIndex,
    String? lastActionMessage,
    bool clearActionMessage = false,
  }) {
    return EmergencyCardState(
      primaryContact: primaryContact,
      doctorContact: doctorContact,
      hotline115: hotline115,
      patient: patient,
      allergyWarning: allergyWarning,
      chronicConditions: chronicConditions,
      verifiedFooterText: verifiedFooterText,
      isLockScreenWidgetEnabled:
          isLockScreenWidgetEnabled ?? this.isLockScreenWidgetEnabled,
      selectedNavIndex: selectedNavIndex ?? this.selectedNavIndex,
      lastActionMessage: clearActionMessage
          ? null
          : (lastActionMessage ?? this.lastActionMessage),
    );
  }
}

