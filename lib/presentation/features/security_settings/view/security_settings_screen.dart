import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../emergency_card/view/widgets/ice_bottom_nav_bar.dart';
import '../../main_shell/view/main_shell_screen.dart';
import '../viewmodel/security_settings_state.dart';
import '../viewmodel/security_settings_viewmodel.dart';
import 'widgets/app_lock_biometrics_card.dart';
import 'widgets/backup_restore_card.dart';
import 'widgets/danger_zone_wipe_card.dart';
import 'widgets/encryption_privacy_card.dart';
import 'widgets/master_shield_security_card.dart';
import 'widgets/security_settings_header.dart';

class SecuritySettingsScreen extends StatefulWidget {
  final bool showBottomNav;
  final ValueChanged<int>? onSelectMainTab;

  const SecuritySettingsScreen({
    super.key,
    this.showBottomNav = true,
    this.onSelectMainTab,
  });

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  late final SecuritySettingsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SecuritySettingsViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _listenForFeedback(BuildContext context, SecuritySettingsState state) {
    if (state.feedbackMessage != null) {
      final msg = state.feedbackMessage!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(seconds: 3),
            backgroundColor: AppColors.secOlive,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        _viewModel.clearFeedbackMessage();
      });
    }
  }

  void _onBottomNavSelect(int index) {
    if (index == 4) return; // already on Settings tab
    if (widget.onSelectMainTab != null) {
      widget.onSelectMainTab!(index);
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainShellScreen(initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final state = _viewModel.state;
        _listenForFeedback(context, state);

        return Scaffold(
          backgroundColor: AppColors.secBackground,
          appBar: SecuritySettingsHeader(
            onProfileTap: () {},
          ),
          body: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 110,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero / Master Shield Security Center Card
                MasterShieldSecurityCard(state: state),
                const SizedBox(height: 20),

                // 2. Khóa Ứng Dụng & Sinh Trắc Học
                AppLockBiometricsCard(
                  state: state,
                  onToggleBiometrics: _viewModel.toggleBiometricLock,
                  onChangePin: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tính năng đổi mã PIN 6 chữ số đang được bảo mật.'),
                        backgroundColor: AppColors.secOlive,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  onSelectTimeout: _viewModel.setAutoLockTimeout,
                ),
                const SizedBox(height: 20),

                // 3. Mã Hóa & Quyền Riêng Tư (Local-First)
                EncryptionPrivacyCard(
                  state: state,
                  onCopyUuid: _viewModel.copyGuestUuid,
                  onTogglePrivacyScreen: _viewModel.togglePrivacyScreen,
                ),
                const SizedBox(height: 20),

                // 4. Sao Lưu & Khôi Phục Dữ Liệu
                BackupRestoreCard(
                  state: state,
                  onExportBackup: _viewModel.exportBackup,
                  onRestoreBackup: _viewModel.restoreBackup,
                ),
                const SizedBox(height: 20),

                // 5. Danger Zone: Vùng Thao Tác Nguy Hiểm
                DangerZoneWipeCard(
                  state: state,
                  onWipeData: _viewModel.wipeAllLocalData,
                ),
              ],
            ),
          ),
          bottomNavigationBar: widget.showBottomNav
              ? IceBottomNavBar(
                  selectedIndex: 4, // 'Cài đặt'
                  onSelectTab: _onBottomNavSelect,
                )
              : null,
        );
      },
    );
  }
}
