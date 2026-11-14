import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../routes/app_routes.dart';
import '../viewmodel/login_viewmodel.dart';
import 'widgets/auth_ambient_background.dart';
import 'widgets/auth_animated_entrance.dart';
import 'widgets/auth_divider.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/guest_mode_card.dart';
import 'widgets/pulsing_biometric_button.dart';
import 'widgets/social_auth_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = LoginViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoLogin();
    });
  }

  Future<void> _checkAutoLogin() async {
    final hasActiveSession = await _viewModel.checkAutoLogin();
    if (hasActiveSession && mounted) {
      _handleLoginSuccess();
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleLoginSuccess() async {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.mainShell);
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          const Positioned.fill(
            child: AuthAmbientBackground(),
          ),
          ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              final state = _viewModel.state;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  topPadding + 60 + 20,
                  20,
                  28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AuthAnimatedEntrance(
                      delay: const Duration(milliseconds: 60),
                      child: _buildWelcomeHeading(),
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _viewModel.formKey,
                      child: Column(
                        children: [
                          AuthAnimatedEntrance(
                            delay: const Duration(milliseconds: 140),
                            child: AuthTextField(
                              label: 'Email hoặc Mã hồ sơ',
                              trailingLabel: 'VD: STYT-892410',
                              trailingLabelColor: AppColors.textMuted,
                              hintText: 'bacsitu@sotayyte.vn hoặc STYT-XXXX',
                              prefixIconAsset: 'assets/icons/ic_badge_id.svg',
                              controller: _viewModel.identifierController,
                              validator: InputValidators.validateRequired,
                            ),
                          ),
                          const SizedBox(height: 16),
                          AuthAnimatedEntrance(
                            delay: const Duration(milliseconds: 200),
                            child: AuthTextField(
                              label: 'Mật khẩu hồ sơ',
                              hintText: 'Nhập mật khẩu an toàn',
                              prefixIconAsset: 'assets/icons/ic_lock.svg',
                              prefixIconWidth: 13.33,
                              prefixIconHeight: 17.5,
                              controller: _viewModel.passwordController,
                              obscureText: state.obscurePassword,
                              onToggleObscure:
                                  _viewModel.togglePasswordVisibility,
                              suffixIconAsset: 'assets/icons/ic_eye.svg',
                              suffixIconWidth: 18.33,
                              suffixIconHeight: 12.5,
                              validator: InputValidators.validateRequired,
                            ),
                          ),
                          const SizedBox(height: 14),
                          AuthAnimatedEntrance(
                            delay: const Duration(milliseconds: 260),
                            child: _buildRememberAndForgot(state.rememberMe),
                          ),
                          if (state.errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.iceDangerBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.error.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                state.errorMessage!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          AuthAnimatedEntrance(
                            delay: const Duration(milliseconds: 320),
                            child: _buildPrimaryActionRow(state.isLoading),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const AuthAnimatedEntrance(
                      delay: Duration(milliseconds: 380),
                      child: AuthDivider(
                        text: 'Hoặc tiếp tục nhanh với',
                      ),
                    ),
                    const SizedBox(height: 16),
                    AuthAnimatedEntrance(
                      delay: const Duration(milliseconds: 440),
                      child: _buildSocialOptions(state.isLoading),
                    ),
                    const SizedBox(height: 24),
                    AuthAnimatedEntrance(
                      delay: const Duration(milliseconds: 500),
                      child: GuestModeCard(
                        onContinueAsGuest: () async {
                          final ok = await _viewModel.continueAsGuestOffline();
                          if (ok) await _handleLoginSuccess();
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    AuthAnimatedEntrance(
                      delay: const Duration(milliseconds: 560),
                      child: _buildSignUpRedirect(),
                    ),
                    const SizedBox(height: 16),
                    AuthAnimatedEntrance(
                      delay: const Duration(milliseconds: 620),
                      child: _buildSecurityFootnote(),
                    ),
                  ],
                ),
              );
            },
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AuthHeader(),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeading() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Cổng Dữ Liệu Y Tế An Toàn',
                  style: AppTypography.badge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Chào mừng trở lại',
            textAlign: TextAlign.center,
            style: AppTypography.heading1,
          ),
          const SizedBox(height: 6),
          Text(
            'Đăng nhập để đồng bộ hồ sơ sức khỏe với Cloud và chia sẻ an toàn cùng bác sĩ.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(height: 24 / 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialOptions(bool isLoading) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SocialAuthButton(
                text: 'Apple',
                iconAsset: 'assets/icons/ic_apple_dark.svg',
                iconWidth: 18,
                iconHeight: 18,
                height: 44,
                backgroundColor: AppColors.surfaceLight,
                textColor: AppColors.textPrimaryLight,
                onPressed: isLoading
                    ? () {}
                    : () async {
                        final ok = await _viewModel.signInWithSocial('apple');
                        if (ok) await _handleLoginSuccess();
                      },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SocialAuthButton(
                text: 'Google',
                iconAsset: 'assets/icons/ic_google.svg',
                iconWidth: 18,
                iconHeight: 18,
                height: 44,
                backgroundColor: AppColors.surfaceLight,
                textColor: AppColors.textPrimaryLight,
                onPressed: isLoading
                    ? () {}
                    : () async {
                        final ok = await _viewModel.signInWithSocial('google');
                        if (ok) await _handleLoginSuccess();
                      },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SocialAuthButton(
          text: 'Đăng nhập với Số Điện Thoại / OTP',
          iconAsset: 'assets/icons/ic_phone.svg',
          iconWidth: 12.5,
          iconHeight: 18.33,
          height: 44,
          backgroundColor: AppColors.secondary,
          textColor: AppColors.textOtpButton,
          onPressed: isLoading
              ? () {}
              : () async {
                  final ok = await _viewModel.signInWithSocial('otp');
                  if (ok) await _handleLoginSuccess();
                },
        ),
      ],
    );
  }

  Widget _buildRememberAndForgot(bool rememberMe) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () => _viewModel.toggleRememberMe(!rememberMe),
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color:
                      rememberMe ? AppColors.primary : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(2.5),
                  border: Border.all(
                    color: rememberMe
                        ? AppColors.primary
                        : AppColors.checkboxBorder,
                    width: 1,
                  ),
                ),
                child: rememberMe
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'Ghi nhớ đăng nhập',
                style: AppTypography.body,
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => _showForgotPasswordDialog(),
          child: Text(
            'Quên mật khẩu?',
            style: AppTypography.labelSmallSemiBold.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryActionRow(bool isLoading) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 6,
                  offset: Offset(0, 4),
                ),
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: isLoading
                    ? null
                    : () async {
                        final ok = await _viewModel.signInWithEmailOrId();
                        if (ok) await _handleLoginSuccess();
                      },
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLoading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryPeach,
                        ),
                      )
                    else ...[
                      Text(
                        'Đăng Nhập Ngay',
                        style: AppTypography.labelSemiBold.copyWith(
                          color: AppColors.primaryPeach,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SvgPicture.asset(
                        'assets/icons/ic_arrow_right.svg',
                        width: 12,
                        height: 12,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        PulsingBiometricButton(
          isLoading: isLoading,
          onTap: () async {
            final ok = await _viewModel.signInWithSocial('biometric');
            if (ok) await _handleLoginSuccess();
          },
        ),
      ],
    );
  }

  Widget _buildSignUpRedirect() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Chưa có tài khoản Sổ Tay Y Tế?',
          style: AppTypography.body,
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.register),
          child: Text(
            'Đăng ký ngay',
            style: AppTypography.labelSemiBold.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityFootnote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/icons/ic_shield_check.svg',
          width: 10.67,
          height: 13.33,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Mã hóa AES-256 đầu cuối • Chuẩn bảo mật HIPAA / GDPR',
            textAlign: TextAlign.center,
            style: AppTypography.badge.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 0.25,
            ),
          ),
        ),
      ],
    );
  }

  void _showForgotPasswordDialog() {
    final idController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    String? localError;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: AppColors.surfaceLight,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock_reset, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Đặt Lại Mật Khẩu Hồ Sơ',
                          style: AppTypography.heading3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nhập Mã hồ sơ (STYT-XXXXXX) hoặc Email/SĐT đã đăng ký để tạo mật khẩu mới.',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: idController,
                      decoration: InputDecoration(
                        labelText: 'Mã hồ sơ hoặc Email/SĐT',
                        hintText: 'VD: STYT-892410 hoặc 0912...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newPassController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu mới (tối thiểu 6 ký tự)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmPassController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Xác nhận mật khẩu mới',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    if (localError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        localError!,
                        style: const TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          child: const Text('Hủy'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            if (newPassController.text != confirmPassController.text) {
                              setDialogState(() {
                                localError = 'Mật khẩu xác nhận không khớp.';
                              });
                              return;
                            }

                            final ok = await _viewModel.resetPassword(
                              identifier: idController.text.trim(),
                              newPassword: newPassController.text,
                            );

                            if (ok) {
                              if (dialogCtx.mounted) {
                                Navigator.pop(dialogCtx);
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đặt lại mật khẩu thành công! Bạn có thể đăng nhập ngay.'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } else {
                              setDialogState(() {
                                localError = _viewModel.state.errorMessage ?? 'Không tìm thấy tài khoản.';
                              });
                            }
                          },
                          child: const Text('Xác Nhận Đổi', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
