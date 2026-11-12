import 'package:flutter/foundation.dart';
import 'profile_state.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel() : _state = _buildInitialState();

  ProfileState _state;
  ProfileState get state => _state;

  void selectMember(String memberId) {
    if (_state.selectedMemberId == memberId) return;
    if (!_state.profilesById.containsKey(memberId)) return;
    _state = _state.copyWith(selectedMemberId: memberId);
    notifyListeners();
  }

  void toggleEditLock() {
    _state = _state.copyWith(isEditLocked: !_state.isEditLocked);
    notifyListeners();
  }

  static ProfileState _buildInitialState() {
    const members = [
      FamilyMemberChip(
        id: 'thu_trang',
        name: 'Thu Trang',
        subtitle: 'Chính • 31t',
        avatarAsset: 'assets/images/img_profile_thu_trang.png',
      ),
      FamilyMemberChip(
        id: 'be_bon',
        name: 'Bé Bon',
        subtitle: 'Con trai • 3t',
        avatarAsset: 'assets/images/img_profile_be_bon.png',
      ),
      FamilyMemberChip(
        id: 'bo_hai',
        name: 'Bố Hải',
        subtitle: 'Bố ruột • 65t',
        avatarAsset: 'assets/images/img_profile_bo_hai.png',
      ),
    ];

    const profiles = {
      'thu_trang': MemberMedicalProfile(
        id: 'thu_trang',
        fullName: 'Nguyễn Thu Trang',
        recordCode: 'VN-HN-884920',
        bhytStatus: 'BHYT: Hoạt động',
        dob: '14/06/1993',
        region: 'Cầu Giấy, HN',
        heroImageAsset: 'assets/images/img_profile_hero_portrait.png',
        vitalsUpdatedAt: '12/03/2024',
        bloodType: 'B Rh(+)',
        bloodNote: 'Sẵn sàng hiến cấp cứu',
        bmiValue: '20.6',
        bmiStatusLabel: 'Lý tưởng',
        heightText: '162 cm',
        weightText: '54.0 kg',
        allergies: [
          AllergyItem(
            title: 'Kháng sinh Beta-lactam',
            severityLabel: 'CẤP CỨU',
            isHighRisk: true,
            includes: 'Bao gồm: Penicillin, Amoxicillin, Ampicillin.',
            reaction:
                'Phản ứng: Nguy cơ Sốc phản vệ (Phù Quincke, tụt huyết áp).',
            iconAsset: 'assets/icons/ic_prof_allergy_drug.svg',
          ),
          AllergyItem(
            title: 'Hải sản có vỏ (Tôm, Cua)',
            severityLabel: 'Nhẹ - Vừa',
            isHighRisk: false,
            reaction:
                'Phản ứng: Mày đay rải rác toàn thân, ngứa niêm mạc môi.',
            iconAsset: 'assets/icons/ic_prof_allergy_food.svg',
          ),
        ],
        chronicConditions: [
          ChronicConditionItem(
            title: 'Viêm xoang dị ứng thời tiết',
            statusText: 'Phát hiện 2019',
            iconAsset: 'assets/icons/ic_prof_sinus_lungs.svg',
          ),
          ChronicConditionItem(
            title: 'Viêm loét dạ dày HP(+)',
            statusText: 'Đã tiệt trừ',
            iconAsset: 'assets/icons/ic_prof_stomach.svg',
          ),
          ChronicConditionItem(
            title: 'Mổ nội soi viêm ruột thừa',
            statusText: 'Năm 2017',
            iconAsset: 'assets/icons/ic_prof_surgery.svg',
          ),
        ],
        immunizations: [
          ImmunizationItem(
            title: 'Vắc xin HPV (Gardasil 9)',
            subtitle: 'Hoàn thành phác đồ 3 mũi (2022)',
            badgeLabel: 'Đủ 3 liều',
            isCompleted: true,
            iconAsset: 'assets/icons/ic_prof_hpv_shield.svg',
          ),
          ImmunizationItem(
            title: 'Vắc xin Cúm mùa (Vaxigrip Tetra)',
            subtitle: 'Mũi nhắc gần nhất: 18/10/2023',
            badgeLabel: 'Nhắc lại 10/2024',
            isCompleted: false,
            iconAsset: 'assets/icons/ic_prof_flu_virus.svg',
          ),
        ],
      ),
      'be_bon': MemberMedicalProfile(
        id: 'be_bon',
        fullName: 'Trần Minh Khôi (Bé Bon)',
        recordCode: 'VN-HN-903412',
        bhytStatus: 'BHYT: Trẻ em <6t',
        dob: '22/09/2023',
        region: 'Cầu Giấy, HN',
        heroImageAsset: 'assets/images/img_profile_be_bon.png',
        vitalsUpdatedAt: '05/03/2024',
        bloodType: 'O Rh(+)',
        bloodNote: 'Nhóm máu phổ biến',
        bmiValue: '15.8',
        bmiStatusLabel: 'Chuẩn WHO',
        heightText: '96 cm',
        weightText: '14.6 kg',
        allergies: [
          AllergyItem(
            title: 'Đạm sữa bò (Nhẹ)',
            severityLabel: 'Theo dõi',
            isHighRisk: false,
            reaction: 'Phản ứng: Rối loạn tiêu hóa nhẹ khi uống sữa nguyên kem.',
            iconAsset: 'assets/icons/ic_prof_allergy_food.svg',
          ),
        ],
        chronicConditions: [
          ChronicConditionItem(
            title: 'Viêm tiểu phế quản tái phát',
            statusText: 'Theo dõi định kỳ',
            iconAsset: 'assets/icons/ic_prof_sinus_lungs.svg',
          ),
        ],
        immunizations: [
          ImmunizationItem(
            title: 'Vắc xin 6 trong 1 (Hexaxim)',
            subtitle: 'Hoàn thành 4 mũi cơ bản',
            badgeLabel: 'Đủ 4 liều',
            isCompleted: true,
            iconAsset: 'assets/icons/ic_prof_hpv_shield.svg',
          ),
          ImmunizationItem(
            title: 'Vắc xin Sởi - Quai bị - Rubella',
            subtitle: 'Đã tiêm mũi 1 lúc 12 tháng',
            badgeLabel: 'Nhắc lại 4 tuổi',
            isCompleted: false,
            iconAsset: 'assets/icons/ic_prof_flu_virus.svg',
          ),
        ],
      ),
      'bo_hai': MemberMedicalProfile(
        id: 'bo_hai',
        fullName: 'Nguyễn Văn Hải',
        recordCode: 'VN-HN-412085',
        bhytStatus: 'BHYT: Hưu trí',
        dob: '03/11/1961',
        region: 'Ba Đình, HN',
        heroImageAsset: 'assets/images/img_profile_bo_hai.png',
        vitalsUpdatedAt: '10/03/2024',
        bloodType: 'A Rh(+)',
        bloodNote: 'Cần lưu ý chống đông',
        bmiValue: '23.4',
        bmiStatusLabel: 'Bình thường',
        heightText: '168 cm',
        weightText: '66.0 kg',
        allergies: [
          AllergyItem(
            title: 'Nhóm NSAID (Ibuprofen, Aspirin)',
            severityLabel: 'CẤP CỨU',
            isHighRisk: true,
            includes: 'Bao gồm: Ibuprofen, Diclofenac, Aspirin liều cao.',
            reaction: 'Phản ứng: Co thắt phế quản, xuất huyết tiêu hóa.',
            iconAsset: 'assets/icons/ic_prof_allergy_drug.svg',
          ),
        ],
        chronicConditions: [
          ChronicConditionItem(
            title: 'Tăng huyết áp vô căn độ II',
            statusText: 'Đang dùng Amlodipine 5mg',
            iconAsset: 'assets/icons/ic_prof_sinus_lungs.svg',
          ),
          ChronicConditionItem(
            title: 'Rối loạn mỡ máu hỗn hợp',
            statusText: 'Kiểm soát ổn định',
            iconAsset: 'assets/icons/ic_prof_stomach.svg',
          ),
        ],
        immunizations: [
          ImmunizationItem(
            title: 'Vắc xin Phế cầu (Prevenar 13)',
            subtitle: 'Tiêm phòng người cao tuổi (2023)',
            badgeLabel: 'Hoàn thành',
            isCompleted: true,
            iconAsset: 'assets/icons/ic_prof_hpv_shield.svg',
          ),
          ImmunizationItem(
            title: 'Vắc xin Cúm mùa (Vaxigrip Tetra)',
            subtitle: 'Mũi nhắc gần nhất: 12/10/2023',
            badgeLabel: 'Nhắc lại 10/2024',
            isCompleted: false,
            iconAsset: 'assets/icons/ic_prof_flu_virus.svg',
          ),
        ],
      ),
    };

    return const ProfileState(
      familyMembers: members,
      selectedMemberId: 'thu_trang',
      profilesById: profiles,
    );
  }
}

