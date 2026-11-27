import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/safe_avatar_image.dart';
import '../../../common_widgets/layout/app_layout.dart';
import '../../emergency_card/view/widgets/ice_bottom_nav_bar.dart';
import '../../main_shell/view/main_shell_screen.dart';
import '../../../routes/app_routes.dart';
import '../viewmodel/profile_viewmodel.dart';
import 'widgets/add_family_member_sheet.dart';
import 'widgets/edit_personal_profile_sheet.dart';
import 'widgets/medical_history_sheet.dart';
import 'widgets/profile_allergy_warning_card.dart';
import 'widgets/profile_chronic_conditions_card.dart';
import 'widgets/profile_documents_card.dart';
import 'widgets/profile_family_switcher.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_immunization_card.dart';
import 'widgets/profile_patient_hero_card.dart';
import 'widgets/profile_security_actions_bar.dart';
import 'widgets/profile_vault_pro_banner.dart';
import 'widgets/profile_vitals_bento_grid.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.showBottomNav = true,
  });

  final bool showBottomNav;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.iceOlive,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _onSelectBottomTab(int index) {
    if (index == 3) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => MainShellScreen(initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      extendBody: true,
      bottomNavigationBar: widget.showBottomNav
          ? IceBottomNavBar(
              selectedIndex: 3,
              onSelectTab: _onSelectBottomTab,
            )
          : null,
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final state = _viewModel.state;
          final activeProfile = state.activeProfile;
          final isPrimary = activeProfile.id == 'primary';
          final primaryMember = state.familyMembers.firstWhere(
            (m) => m.id == 'primary',
            orElse: () => state.familyMembers.first,
          );
          final activeChip = state.familyMembers.firstWhere(
            (m) => m.id == state.selectedMemberId,
            orElse: () => state.familyMembers.first,
          );

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ProfileHeader(
                  activeMemberName: activeChip.name,
                  activeAvatarAsset: activeChip.avatarAsset,
                  isViewingFamilyMember: !isPrimary,
                  primaryMemberName: primaryMember.name,
                  onProfileTap: () {
                    if (!isPrimary) {
                      _viewModel.selectMember('primary');
                      _showSnack(
                        'Đã quay lại hồ sơ gốc: ${primaryMember.name}',
                      );
                    } else {
                      _showSnack(
                        'Đang xem hồ sơ gốc: ${activeProfile.fullName}',
                      );
                    }
                  },
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(top: 16),
                sliver: SliverToBoxAdapter(
                  child: ProfileFamilySwitcher(
                    members: state.familyMembers,
                    selectedMemberId: state.selectedMemberId,
                    onSelectMember: _viewModel.selectMember,
                    onAddMemberTap: () => AddFamilyMemberSheet.show(
                      context,
                      onAdd: (name, rel, blood, [dob]) async {
                        await _viewModel.addFamilyMember(
                          name: name,
                          relationship: rel,
                          bloodType: blood,
                          dob: dob,
                        );
                        _showSnack(
                          'Đã thêm hồ sơ: $name ($rel). Chạm "Hồ sơ gốc" để quay lại tài khoản của bạn.',
                        );
                      },
                    ),
                    onVaultProTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.paywall),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppLayoutTokens.screenPadding,
                  16,
                  AppLayoutTokens.screenPadding,
                  112 + bottomPadding,
                ),
                sliver: SliverList.list(
                  children: [
                    // Cụm 1: Thẻ định danh bệnh nhân gọn ngang
                    ProfilePatientHeroCard(
                      profile: activeProfile,
                      isPrimary: isPrimary,
                      onDeleteTap: !isPrimary
                          ? () => _confirmDeleteFamilyMember(
                                context,
                                activeProfile.id,
                                activeProfile.fullName,
                              )
                          : null,
                      onPickAvatar: () {
                        if (state.isEditLocked) {
                          _showSnack(
                            'Hồ sơ đang bật khóa chỉnh sửa. Hãy bấm Mở khóa ở cuối trang để cập nhật.',
                          );
                          return;
                        }
                        pickAndSaveAvatar(
                          context,
                          onAvatarSaved: (localPath) async {
                            if (isPrimary) {
                              await _viewModel.updateAvatar(localPath);
                            } else {
                              await _viewModel.updateFamilyMemberAvatar(
                                activeProfile.id,
                                localPath,
                              );
                            }
                            _showSnack('Đã cập nhật ảnh đại diện thành công!');
                          },
                        );
                      },
                      onEditTap: () {
                        if (state.isEditLocked) {
                          _showSnack(
                            'Hồ sơ đang bật khóa chỉnh sửa. Hãy bấm Mở khóa ở cuối trang để cập nhật.',
                          );
                          return;
                        }
                        EditPersonalProfileSheet.show(
                          context,
                          sheetTitle: isPrimary
                              ? 'Cập Nhật Hồ Sơ Gốc'
                              : 'Cập Nhật Hồ Sơ: ${activeProfile.fullName}',
                          initialFullName: activeProfile.fullName,
                          initialDob: activeProfile.dob,
                          initialGender: activeProfile.gender,
                          initialBloodType: activeProfile.bloodType,
                          initialHeight:
                              activeProfile.heightText.replaceAll(' cm', ''),
                          initialWeight:
                              activeProfile.weightText.replaceAll(' kg', ''),
                          initialEmergencyContact: activeProfile.contact,
                          initialRegion: (activeProfile.region !=
                                      'Chưa cập nhật' &&
                                  !activeProfile.region.contains('@'))
                              ? activeProfile.region
                              : '',
                          initialAvatarUrl: activeProfile.heroImageAsset,
                          onAvatarChanged: (newPath) async {
                            if (isPrimary) {
                              await _viewModel.updateAvatar(newPath);
                            } else {
                              await _viewModel.updateFamilyMemberAvatar(
                                activeProfile.id,
                                newPath,
                              );
                            }
                            _showSnack('Đã cập nhật ảnh đại diện thành công!');
                          },
                          initialAllergies: activeProfile.allergies
                              .map((a) => a.title)
                              .join(', '),
                          initialChronicConditions: activeProfile
                              .chronicConditions
                              .map((c) => c.title)
                              .join(', '),
                          onSave: ({
                            required fullName,
                            allergies,
                            bloodType,
                            chronicConditions,
                            dateOfBirth,
                            emergencyContact,
                            gender,
                            height,
                            organDonor,
                            weight,
                            region,
                            avatarUrl,
                          }) async {
                            if (isPrimary) {
                              await _viewModel.updateCurrentUserProfile(
                                fullName: fullName,
                                dateOfBirth: dateOfBirth,
                                gender: gender,
                                bloodType: bloodType,
                                height: height,
                                weight: weight,
                                emergencyContact: emergencyContact,
                                allergies: allergies,
                                chronicConditions: chronicConditions,
                                organDonor: organDonor,
                                region: region,
                                avatarUrl: avatarUrl,
                              );
                            } else {
                              await _viewModel.updateFamilyMemberProfile(
                                memberId: activeProfile.id,
                                fullName: fullName,
                                dateOfBirth: dateOfBirth,
                                gender: gender,
                                bloodType: bloodType,
                                height: height,
                                weight: weight,
                                emergencyContact: emergencyContact,
                                allergies: allergies,
                                chronicConditions: chronicConditions,
                                avatarUrl: avatarUrl,
                              );
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: AppLayoutTokens.sectionGap),

                    // Cụm 2: Thể chất nền (Bento 2x2)
                    ProfileVitalsBentoGrid(profile: activeProfile),
                    const SizedBox(height: AppLayoutTokens.sectionGap),

                    // Cụm 3: Tiền sử & Cảnh báo lâm sàng
                    SectionContainer(
                      title: 'Tiền sử & Cảnh báo lâm sàng',
                      icon: Icons.assignment_ind_outlined,
                      bottomSpacing: AppLayoutTokens.sectionGap,
                      child: Column(
                        children: [
                          ProfileAllergyWarningCard(
                            allergies: activeProfile.allergies,
                          ),
                          const SizedBox(height: AppLayoutTokens.cardGap),
                          ProfileChronicConditionsCard(
                            conditions: activeProfile.chronicConditions,
                            onDetailTap: () => MedicalHistorySheet.show(
                              context,
                              patientName: activeProfile.fullName,
                              chronicConditions: activeProfile.chronicConditions
                                  .map((c) => c.title)
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: AppLayoutTokens.cardGap),
                          ProfileImmunizationCard(
                            immunizations: activeProfile.immunizations,
                          ),
                        ],
                      ),
                    ),

                    // Cụm 4: Lưu trữ, Nâng cấp & Bảo mật hồ sơ
                    SectionContainer(
                      title: 'Tài liệu & Tiện ích bảo mật',
                      icon: Icons.folder_special_outlined,
                      bottomSpacing: 0,
                      child: Column(
                        children: [
                          ProfileDocumentsCard(
                            onTap: () => Navigator.of(context)
                                .pushNamed(AppRoutes.documents),
                          ),
                          const SizedBox(height: AppLayoutTokens.cardGap),
                          ProfileVaultProBanner(
                            onTap: () => Navigator.of(context)
                                .pushNamed(AppRoutes.paywall),
                          ),
                          const SizedBox(height: AppLayoutTokens.cardGap),
                          ProfileSecurityActionsBar(
                            isEditLocked: state.isEditLocked,
                            onToggleLock: _viewModel.toggleEditLock,
                            onExportPdf: () => Navigator.of(context)
                                .pushNamed(AppRoutes.vitalReports),
                            onShareEmergency: () => Navigator.of(context)
                                .pushNamed(AppRoutes.emergencyCard),
                          ),
                          const SizedBox(height: AppLayoutTokens.cardGap),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.iceTextNavy,
                                side: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () => Navigator.of(context)
                                  .pushNamed(AppRoutes.securitySettings),
                              icon: const Icon(
                                Icons.security_rounded,
                                size: 28,
                                color: AppColors.primary,
                              ),
                              label: const Text(
                                'Cài đặt Bảo mật, Khóa PIN & Sao lưu',
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteFamilyMember(
    BuildContext context,
    String memberId,
    String memberName,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa hồ sơ'),
        content: Text(
          'Bạn có chắc chắn muốn xóa hồ sơ thành viên "$memberName" không? '
          'Hồ sơ này sẽ bị xóa khỏi danh sách gia đình và không ảnh hưởng đến tài khoản gốc của bạn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _viewModel.deleteFamilyMember(memberId);
              _showSnack('Đã xóa hồ sơ thành viên "$memberName" thành công!');
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
