import 'package:flutter/foundation.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../domain/repositories/auth_repository.dart';
import 'profile_state.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel() : _state = _buildInitialState() {
    loadCurrentUserProfile();
  }

  ProfileState _state;
  ProfileState get state => _state;

  Future<void> loadCurrentUserProfile() async {
    try {
      if (sl.isRegistered<AuthRepository>()) {
        final session = await sl<AuthRepository>().getActiveSession();
        if (session != null && !session.isGuest) {
          final shortName = session.fullName.trim().split(' ').last;
          final primaryMember = FamilyMemberChip(
            id: 'primary',
            name: shortName,
            subtitle: 'Chính • Hồ sơ gốc',
            avatarAsset: session.avatarUrl ?? 'assets/images/img_profile_thu_trang.png',
          );

          String dobFormatted = '14/06/1993';
          if (session.dateOfBirth != null && session.dateOfBirth!.isNotEmpty) {
            final parts = session.dateOfBirth!.split('-');
            if (parts.length == 3) {
              dobFormatted = '${parts[2]}/${parts[1]}/${parts[0]}';
            } else {
              dobFormatted = session.dateOfBirth!;
            }
          }

          final primaryProfile = MemberMedicalProfile(
            id: 'primary',
            fullName: session.fullName.isNotEmpty ? session.fullName : 'Chưa cập nhật',
            recordCode: session.patientCode,
            bhytStatus: 'BHYT: Chưa liên kết',
            dob: dobFormatted,
            region: session.primaryContact,
            heroImageAsset: session.avatarUrl ?? 'assets/images/img_profile_hero_portrait.png',
            vitalsUpdatedAt: 'Chưa có',
            bloodType: session.bloodType != null && session.bloodType != 'Chưa rõ'
                ? session.bloodType!
                : 'Chưa rõ',
            bloodNote: 'Chưa xác nhận',
            bmiValue: '--',
            bmiStatusLabel: 'Chưa tính',
            heightText: '-- cm',
            weightText: '-- kg',
            allergies: const [],
            chronicConditions: const [],
            immunizations: const [],
          );

          final updatedProfiles = Map<String, MemberMedicalProfile>.from(_state.profilesById);
          updatedProfiles['primary'] = primaryProfile;

          final updatedMembers = [
            primaryMember,
            ..._state.familyMembers.where((m) => m.id != 'primary' && m.id != 'thu_trang'),
          ];

          _state = _state.copyWith(
            familyMembers: updatedMembers,
            profilesById: updatedProfiles,
            selectedMemberId: 'primary',
          );
          notifyListeners();
        }
      }
    } catch (_) {}
  }

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
        id: 'primary',
        name: 'Hồ sơ của tôi',
        subtitle: 'Chính • Bản thân',
        avatarAsset: 'assets/images/img_profile_avatar.png',
      ),
    ];

    const profiles = {
      'primary': MemberMedicalProfile(
        id: 'primary',
        fullName: 'Chưa cập nhật',
        recordCode: 'STYT-GUEST',
        bhytStatus: 'BHYT: Chưa liên kết',
        dob: 'Chưa rõ',
        region: 'Chưa cập nhật',
        heroImageAsset: 'assets/images/img_profile_hero_portrait.png',
        vitalsUpdatedAt: 'Chưa có',
        bloodType: 'Chưa rõ',
        bloodNote: 'Chưa xác nhận',
        bmiValue: '--',
        bmiStatusLabel: 'Chưa tính',
        heightText: '-- cm',
        weightText: '-- kg',
        allergies: [],
        chronicConditions: [],
        immunizations: [],
      ),
    };

    return const ProfileState(
      familyMembers: members,
      selectedMemberId: 'primary',
      profilesById: profiles,
    );
  }
}


