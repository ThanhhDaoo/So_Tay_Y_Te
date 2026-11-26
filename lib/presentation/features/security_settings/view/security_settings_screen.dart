import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/repositories/auth_repository.dart';
import '../../../common_widgets/layout/app_layout.dart';
import '../../../routes/app_routes.dart';
import '../../emergency_card/view/widgets/ice_bottom_nav_bar.dart';
import '../../main_shell/view/main_shell_screen.dart';
import '../viewmodel/security_settings_state.dart';
import '../viewmodel/security_settings_viewmodel.dart';
import 'widgets/app_lock_biometrics_card.dart';
import 'widgets/backup_restore_card.dart';
import 'widgets/change_pin_modal.dart';
import 'widgets/cloud_sync_card.dart';
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        _viewModel.clearFeedbackMessage();
      });
    }
  }

  void _onBottomNavSelect(int index) {
    if (index == 4) return;
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
              left: AppLayoutTokens.screenPadding,
              right: AppLayoutTokens.screenPadding,
              top: 16,
              bottom: 112,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Tổng quan bảo vệ phần cứng
                MasterShieldSecurityCard(state: state),
                const SizedBox(height: AppLayoutTokens.sectionGap),

                // 2. Khóa Ứng Dụng & Sinh Trắc Học
                AppLockBiometricsCard(
                  state: state,
                  onToggleBiometrics: _viewModel.toggleBiometricLock,
                  onLockNow: () {
                    if (AppRoutes.isAppLockShowing) return;
                    AppRoutes.isAppLockShowing = true;
                    Navigator.of(context).pushNamed(
                      AppRoutes.appLock,
                      arguments: () {
                        AppRoutes.isAppLockShowing = false;
                      },
                    );
                  },
                  onChangePin: () {
                    ChangePinModal.show(
                      context,
                      onVerifyCurrentPin: state.hasPinCode
                          ? (oldPin) => _viewModel.verifyPin(oldPin)
                          : null,
                      onPinCreated: (pin) => _viewModel.saveNewPin(pin),
                      onSuccess: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Mã PIN 6 chữ số đã được cập nhật và mã hóa thành công!',
                            ),
                            backgroundColor: AppColors.secOlive,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    );
                  },
                  onSelectTimeout: _viewModel.setAutoLockTimeout,
                ),
                const SizedBox(height: AppLayoutTokens.sectionGap),

                // 3. Mã Hóa & Quyền Riêng Tư
                EncryptionPrivacyCard(
                  state: state,
                  onCopyUuid: _viewModel.copyGuestUuid,
                  onTogglePrivacyScreen: _viewModel.togglePrivacyScreen,
                ),
                const SizedBox(height: AppLayoutTokens.sectionGap),

                // 4. Đồng Bộ Đám Mây Supabase
                CloudSyncCard(
                  state: state,
                  onSyncNow: _viewModel.syncCloudNow,
                  onToggleAutoSync: _viewModel.toggleAutoCloudSync,
                ),
                const SizedBox(height: AppLayoutTokens.sectionGap),

                // 5. Sao Lưu & Khôi Phục Dữ Liệu
                BackupRestoreCard(
                  state: state,
                  onExportBackup: _viewModel.exportBackup,
                  onRestoreBackup: _viewModel.restoreBackup,
                ),
                const SizedBox(height: 32),

                // 6. Phiên đăng nhập & Vùng Thao Tác Nguy Hiểm (tách nhịp nghỉ rộng 32px)
                CleanCard(
                  borderColor: AppColors.divider,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  onTap: () => _showLogoutConfirmDialog(context),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(22),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          size: 19,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đăng xuất khỏi thiết bị',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.error,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Dữ liệu bệnh án trên máy vẫn được giữ an toàn',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.secOliveMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.secOliveMuted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppLayoutTokens.cardGap),
                DangerZoneWipeCard(
                  state: state,
                  onWipeData: () async {
                    await _viewModel.wipeAllLocalData();
                    if (context.mounted && sl.isRegistered<AuthRepository>()) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.login,
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          bottomNavigationBar: widget.showBottomNav
              ? IceBottomNavBar(
                  selectedIndex: 4,
                  onSelectTab: _onBottomNavSelect,
                )
              : null,
        );
      },
    );
  }

  void _showLogoutConfirmDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng Xuất Tài Khoản'),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất? Bạn sẽ cần nhập lại mật khẩu hoặc Face ID để truy cập hồ sơ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (sl.isRegistered<AuthRepository>()) {
                await sl<AuthRepository>().logout();
              }
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Đăng Xuất',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
