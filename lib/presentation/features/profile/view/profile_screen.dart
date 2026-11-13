import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../emergency_card/view/widgets/ice_bottom_nav_bar.dart';
import '../../main_shell/view/main_shell_screen.dart';
import '../../../routes/app_routes.dart';
import '../viewmodel/profile_viewmodel.dart';
import 'widgets/profile_allergy_warning_card.dart';
import 'widgets/profile_chronic_conditions_card.dart';
import 'widgets/profile_family_switcher.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_immunization_card.dart';
import 'widgets/profile_patient_hero_card.dart';
import 'widgets/profile_security_actions_bar.dart';
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
    if (index <= 2) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => MainShellScreen(initialIndex: index),
        ),
      );
      return;
    }
    _showSnack('Tính năng đang được phát triển');
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
                  onProfileTap: () =>
                      _showSnack('Đang xem hồ sơ: ${activeProfile.fullName}'),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(top: 16),
                sliver: SliverToBoxAdapter(
                  child: ProfileFamilySwitcher(
                    members: state.familyMembers,
                    selectedMemberId: state.selectedMemberId,
                    onSelectMember: _viewModel.selectMember,
                    onAddMemberTap: () =>
                        _showSnack('Tính năng thêm thành viên đang phát triển'),
                    onVaultProTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.paywall),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  110 + bottomPadding,
                ),
                sliver: SliverList.list(
                  children: [
                    ProfilePatientHeroCard(profile: activeProfile),
                    const SizedBox(height: 18),
                    ProfileVitalsBentoGrid(profile: activeProfile),
                    const SizedBox(height: 18),
                    ProfileAllergyWarningCard(
                      allergies: activeProfile.allergies,
                    ),
                    const SizedBox(height: 18),
                    ProfileChronicConditionsCard(
                      conditions: activeProfile.chronicConditions,
                      onDetailTap: () =>
                          _showSnack('Chi tiết bệnh sử đang phát triển'),
                    ),
                    const SizedBox(height: 18),
                    ProfileImmunizationCard(
                      immunizations: activeProfile.immunizations,
                    ),
                    const SizedBox(height: 18),
                    ProfileSecurityActionsBar(
                      isEditLocked: state.isEditLocked,
                      onToggleLock: _viewModel.toggleEditLock,
                      onExportPdf: () => _showSnack(
                        'Đang chuẩn bị bản tóm tắt PDF cho ${activeChip.name}...',
                      ),
                      onShareEmergency: () => _showSnack(
                        'Đã tạo liên kết chia sẻ cấp cứu QR cho ${activeChip.name}',
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
}

