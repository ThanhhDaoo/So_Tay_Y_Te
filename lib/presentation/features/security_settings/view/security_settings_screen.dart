import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/repositories/auth_repository.dart';
import '../../../routes/app_routes.dart';
import '../../emergency_card/view/widgets/ice_bottom_nav_bar.dart';
import '../../main_shell/view/main_shell_screen.dart';
import '../viewmodel/security_settings_state.dart';
import '../viewmodel/security_settings_viewmodel.dart';
import 'widgets/app_lock_biometrics_card.dart';
import 'widgets/backup_restore_card.dart';
import 'widgets/change_pin_modal.dart';
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
                    ChangePinModal.show(
                      context,
                      onSuccess: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mã PIN 6 chữ số đã được cập nhật và mã hóa thành công!'),
                            backgroundColor: AppColors.secOlive,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
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
                const SizedBox(height: 24),

                // 6. Đăng Xuất Tài Khoản Khỏi Thiết Bị
                Material(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.logout_rounded, color: AppColors.error),
                    ),
                    title: const Text(
                      'Đăng xuất khỏi thiết bị',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    subtitle: const Text(
                      'Xóa phiên làm việc hiện tại, dữ liệu bệnh án vẫn được lưu an toàn.',
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      showDialog(
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                              child: const Text('Đăng Xuất', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
