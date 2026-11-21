import 'package:flutter/foundation.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/user_session_manager.dart';
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
        final authRepo = sl<AuthRepository>();
        final session = await authRepo.getActiveSession();
        if (session != null && !session.isGuest) {
          final shortName = session.fullName.trim().split(' ').last;
          final primaryMember = FamilyMemberChip(
            id: 'primary',
            name: shortName,
            subtitle: 'Chính • Hồ sơ gốc',
            avatarAsset: session.avatarUrl ?? 'assets/images/img_profile_thu_trang.png',
          );

          String dobFormatted = 'Chưa cập nhật';
          if (session.dateOfBirth != null && session.dateOfBirth!.isNotEmpty) {
            final parts = session.dateOfBirth!.split('-');
            if (parts.length == 3) {
              dobFormatted = '${parts[2]}/${parts[1]}/${parts[0]}';
            } else {
              dobFormatted = session.dateOfBirth!;
            }
          }

          List<String> allergiesList = const [];
          List<String> conditionsList = const [];
          String heightStr = '-- cm';
          String weightStr = '-- kg';
          String bmiVal = '--';
          String bmiLabel = 'Chưa tính';
          String regionDisplay = 'Chưa cập nhật';

          final details = await authRepo.getUserProfileDetails(session.id);
          if (details != null) {
            final rawRegion = details['region'] as String?;
            if (rawRegion != null &&
                rawRegion.trim().isNotEmpty &&
                !rawRegion.contains('@') &&
                !rawRegion.startsWith('0') &&
                rawRegion.trim() != 'Chưa cập nhật') {
              regionDisplay = rawRegion.trim();
            } else if (rawRegion != null && (rawRegion.contains('@') || rawRegion.startsWith('0'))) {
              // Tự động dọn dẹp dữ liệu cũ nếu bị lưu nhầm email hoặc số điện thoại vào trường khu vực
              try {
                await authRepo.updateUserProfile(
                  userId: session.id,
                  fullName: session.fullName,
                  region: 'Chưa cập nhật',
                );
              } catch (_) {}
            }
            final rawAllergies = details['allergies'] as String?;
            if (rawAllergies != null && rawAllergies.trim().isNotEmpty && rawAllergies != 'Không có') {
              allergiesList = rawAllergies.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
            }
            final rawConditions = details['chronic_conditions'] as String?;
            if (rawConditions != null && rawConditions.trim().isNotEmpty && rawConditions != 'Không có') {
              conditionsList = rawConditions.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
            }
            final h = details['height'] as String?;
            final w = details['weight'] as String?;
            if (h != null && h.trim().isNotEmpty) heightStr = '${h.trim()} cm';
            if (w != null && w.trim().isNotEmpty) weightStr = '${w.trim()} kg';

            final hNum = double.tryParse(h ?? '');
            final wNum = double.tryParse(w ?? '');
            if (hNum != null && wNum != null && hNum > 0) {
              final bmi = wNum / ((hNum / 100) * (hNum / 100));
              bmiVal = bmi.toStringAsFixed(1);
              if (bmi < 18.5) {
                bmiLabel = 'Thiếu cân';
              } else if (bmi < 24.9) {
                bmiLabel = 'Bình thường';
              } else if (bmi < 29.9) {
                bmiLabel = 'Tiền béo phì';
              } else {
                bmiLabel = 'Béo phì';
              }
            }
          }

          final allergyItems = allergiesList.map((a) => AllergyItem(
            title: a,
            severityLabel: 'Cảnh báo',
            isHighRisk: true,
            reaction: 'Cần lưu ý khi kê đơn y tế',
            iconAsset: 'assets/icons/ic_prof_allergy_pill.svg',
          )).toList();

          final conditionItems = conditionsList.map((c) => ChronicConditionItem(
            title: c,
            statusText: 'Đang theo dõi',
            iconAsset: 'assets/icons/ic_prof_condition_stomach.svg',
          )).toList();

          final primaryProfile = MemberMedicalProfile(
            id: 'primary',
            fullName: session.fullName.isNotEmpty ? session.fullName : 'Chưa cập nhật',
            recordCode: session.patientCode,
            bhytStatus: 'BHYT: Chưa liên kết',
            dob: dobFormatted,
            region: regionDisplay,
            contact: session.primaryContact,
            heroImageAsset: session.avatarUrl ?? 'assets/images/img_profile_hero_portrait.png',
            vitalsUpdatedAt: 'Chưa có',
            bloodType: session.bloodType != null && session.bloodType != 'Chưa rõ'
                ? session.bloodType!
                : 'Chưa rõ',
            bloodNote: 'Chưa xác nhận',
            bmiValue: bmiVal,
            bmiStatusLabel: bmiLabel,
            heightText: heightStr,
            weightText: weightStr,
            allergies: allergyItems,
            chronicConditions: conditionItems,
            immunizations: const [],
          );

          final dbFamilyChips = <FamilyMemberChip>[];
          final dbFamilyProfiles = <String, MemberMedicalProfile>{};

          if (sl.isRegistered<DatabaseHelper>()) {
            try {
              final db = await sl<DatabaseHelper>().database;
              final rows = await db.query(
                'family_members',
                where: 'user_id = ?',
                whereArgs: [session.id],
                orderBy: 'created_at ASC',
              );
              for (final row in rows) {
                final famId = row['id'] as String;
                final famName = row['name'] as String;
                final famRel = row['relationship'] as String;
                final famBlood = row['blood_type'] as String? ?? 'Chưa rõ';
                final famDob = row['dob'] as String? ?? 'Chưa rõ';
                final famAvatar = row['avatar_asset'] as String? ?? 'assets/images/img_profile_avatar.png';

                dbFamilyChips.add(FamilyMemberChip(
                  id: famId,
                  name: famName,
                  subtitle: famRel,
                  avatarAsset: famAvatar,
                ));

                dbFamilyProfiles[famId] = MemberMedicalProfile(
                  id: famId,
                  fullName: famName,
                  recordCode: 'FAM-${famId.length >= 4 ? famId.substring(famId.length - 4) : famId}',
                  bhytStatus: 'BHYT: Chưa liên kết',
                  dob: famDob,
                  region: regionDisplay,
                  heroImageAsset: famAvatar,
                  vitalsUpdatedAt: 'Chưa có',
                  bloodType: famBlood,
                  bloodNote: 'Đã khai báo',
                  bmiValue: '--',
                  bmiStatusLabel: 'Chưa tính',
                  heightText: '-- cm',
                  weightText: '-- kg',
                  allergies: const [],
                  chronicConditions: const [],
                  immunizations: const [],
                );
              }
            } catch (_) {}
          }

          final updatedProfiles = Map<String, MemberMedicalProfile>.from(_state.profilesById);
          updatedProfiles['primary'] = primaryProfile;
          updatedProfiles.addAll(dbFamilyProfiles);

          final updatedMembers = [
            primaryMember,
            ...dbFamilyChips,
          ];

          final currentSelected = _state.selectedMemberId;
          final nextSelected = updatedProfiles.containsKey(currentSelected) ? currentSelected : 'primary';

          _state = _state.copyWith(
            familyMembers: updatedMembers,
            profilesById: updatedProfiles,
            selectedMemberId: nextSelected,
          );
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> addFamilyMember({
    required String name,
    required String relationship,
    required String bloodType,
    String? dob,
  }) async {
    try {
      if (sl.isRegistered<AuthRepository>() && sl.isRegistered<DatabaseHelper>()) {
        final auth = sl<AuthRepository>();
        final session = await auth.getActiveSession();
        if (session != null) {
          final db = await sl<DatabaseHelper>().database;
          final newId = 'fam_${DateTime.now().millisecondsSinceEpoch}';
          await db.insert('family_members', {
            'id': newId,
            'user_id': session.id,
            'name': name.trim(),
            'relationship': relationship.trim(),
            'blood_type': bloodType.trim(),
            'dob': dob ?? 'Chưa rõ',
            'gender': 'Chưa rõ',
            'phone': '',
            'allergies': '',
            'chronic_conditions': '',
            'avatar_asset': 'assets/images/img_profile_avatar.png',
            'created_at': DateTime.now().toIso8601String(),
          });
          await loadCurrentUserProfile();
          selectMember(newId);
        }
      }
    } catch (_) {}
  }

  Future<void> deleteFamilyMember(String memberId) async {
    try {
      if (sl.isRegistered<DatabaseHelper>()) {
        final db = await sl<DatabaseHelper>().database;
        await db.delete('family_members', where: 'id = ?', whereArgs: [memberId]);
        if (_state.selectedMemberId == memberId) {
          _state = _state.copyWith(selectedMemberId: 'primary');
        }
        await loadCurrentUserProfile();
      }
    } catch (_) {}
  }

  Future<void> updateCurrentUserProfile({
    required String fullName,
    String? dateOfBirth,
    String? gender,
    String? bloodType,
    String? height,
    String? weight,
    String? emergencyContact,
    String? allergies,
    String? chronicConditions,
    String? organDonor,
    String? region,
    String? avatarUrl,
  }) async {
    if (sl.isRegistered<AuthRepository>()) {
      final auth = sl<AuthRepository>();
      final session = await auth.getActiveSession();
      if (session != null) {
        await auth.updateUserProfile(
          userId: session.id,
          fullName: fullName,
          dateOfBirth: dateOfBirth,
          gender: gender,
          bloodType: bloodType,
          emergencyContact: emergencyContact,
          allergies: allergies,
          chronicConditions: chronicConditions,
          height: height,
          weight: weight,
          organDonor: organDonor,
          region: region,
          avatarUrl: avatarUrl,
        );
        if (avatarUrl != null) {
          AppSessionNotifier.instance.notifyAvatarChanged(avatarUrl);
        }
        await loadCurrentUserProfile();
      }
    }
  }

  Future<void> updateAvatar(String imagePath) async {
    if (sl.isRegistered<AuthRepository>()) {
      final auth = sl<AuthRepository>();
      final session = await auth.getActiveSession();
      if (session != null) {
        await auth.updateUserProfile(
          userId: session.id,
          fullName: session.fullName,
          avatarUrl: imagePath,
        );
        AppSessionNotifier.instance.notifyAvatarChanged(imagePath);
        await loadCurrentUserProfile();
      }
    }
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


