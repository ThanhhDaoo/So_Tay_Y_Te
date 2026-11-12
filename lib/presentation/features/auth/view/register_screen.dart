import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../routes/app_routes.dart';
import '../viewmodel/register_viewmodel.dart';
import 'widgets/auth_divider.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/guest_migration_notice_card.dart';
import 'widgets/password_strength_meter.dart';
import 'widgets/social_auth_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final RegisterViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = RegisterViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _navigateToTimeline() {
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.emergencyCard,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
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
                    _buildTopAssuranceBlock(),
                    const SizedBox(height: 24),
                    Form(
                      key: _viewModel.formKey,
                      child: Column(
                        children: [
                          AuthTextField(
                            label: 'Họ và tên chủ hồ sơ',
                            isRequired: true,
                            hintText: 'Nguyễn Văn An',
                            prefixIconAsset: 'assets/icons/ic_user_badge.svg',
                            controller: _viewModel.fullNameController,
                            validator: InputValidators.validateRequired,
                          ),
                          const SizedBox(height: 16),
                          AuthTextField(
                            label: 'Số điện thoại hoặc Email',
                            isRequired: true,
                            hintText: 'example@sotayyte.vn hoặc 0912...',
                            hintColor: AppColors.textHintAlt,
                            prefixIconAsset: 'assets/icons/ic_contact_mail.svg',
                            prefixIconWidth: 20,
                            prefixIconHeight: 15,
                            controller: _viewModel.contactController,
                            validator: InputValidators.validateRequired,
                          ),
                          const SizedBox(height: 16),
                          AuthTextField(
                            label: 'Mật khẩu bảo mật',
                            isRequired: true,
                            trailingLabel: state.passwordStrength.label,
                            trailingLabelColor: AppColors.textWarmBrown,
                            hintText: 'Nhập mật khẩu tối thiểu 6 ký tự',
                            hintColor: AppColors.textHintAlt,
                            prefixIconAsset:
                                'assets/icons/ic_password_shield.svg',
                            prefixIconWidth: 13.33,
                            prefixIconHeight: 16.67,
                            controller: _viewModel.passwordController,
                            obscureText: state.obscurePassword,
                            onToggleObscure:
                                _viewModel.togglePasswordVisibility,
                            suffixIconAsset: 'assets/icons/ic_eye_toggle.svg',
                            suffixIconWidth: 26.33,
                            suffixIconHeight: 26.5,
                            onChanged: _viewModel.onPasswordChanged,
                            validator: InputValidators.validateRequired,
                          ),
                          const SizedBox(height: 8),
                          PasswordStrengthMeter(
                            strength: state.passwordStrength,
                          ),
                          const SizedBox(height: 16),
                          AuthTextField(
                            label: 'Xác nhận lại mật khẩu',
                            isRequired: true,
                            hintText: 'Nhập lại mật khẩu bảo mật',
                            hintColor: AppColors.textHintAlt,
                            prefixIconAsset: 'assets/icons/ic_lock_reset.svg',
                            controller: _viewModel.confirmPasswordController,
                            obscureText: true,
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Vui lòng xác nhận mật khẩu';
                              }
                              if (val != _viewModel.passwordController.text) {
                                return 'Mật khẩu xác nhận không khớp';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildSecurityOptionsCard(
                      enableBiometric: state.enableBiometric,
                      acceptedTerms: state.acceptedTerms,
                    ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        state.errorMessage!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _buildPrimaryCtaButton(state.isLoading),
                    const SizedBox(height: 22),
                    const AuthDivider(
                      text: 'HOẶC ĐĂNG KÝ NHANH',
                      uppercase: true,
                      textColor: AppColors.textHint,
                    ),
                    const SizedBox(height: 16),
                    _buildSocialButtons(state.isLoading),
                    const SizedBox(height: 20),
                    const GuestMigrationNoticeCard(),
                    const SizedBox(height: 20),
                    _buildSignInRedirect(),
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

  Widget _buildTopAssuranceBlock() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/icons/ic_shield_lock.svg',
                  width: 10.67,
                  height: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  'BẢO MẬT CHUẨN Y KHOA TOÀN CẦU',
                  style: AppTypography.badge.copyWith(
                    color: AppColors.textWarmBrownMuted,
                    letterSpacing: 0.275,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tạo Tài Khoản Mới',
            textAlign: TextAlign.center,
            style: AppTypography.heading1,
          ),
          const SizedBox(height: 6),
          Text(
            'Khởi tạo két bảo mật y tế cá nhân & gia đình được mã hóa đầu cuối an toàn.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityOptionsCard({
    required bool enableBiometric,
    required bool acceptedTerms,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _viewModel.toggleBiometric(!enableBiometric),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCheckboxBox(enableBiometric),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Kích hoạt sinh trắc học',
                            style: AppTypography.labelSmallSemiBold,
                          ),
                          const SizedBox(width: 6),
                          SvgPicture.asset(
                            'assets/icons/ic_fingerprint_small.svg',
                            width: 12.03,
                            height: 13.31,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mở khóa nhanh bằng Face ID hoặc Vân tay.',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _viewModel.toggleAcceptedTerms(!acceptedTerms),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCheckboxBox(acceptedTerms),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppTypography.body.copyWith(
                        color: AppColors.textPrimaryLight,
                      ),
                      children: [
                        const TextSpan(text: 'Tôi đồng ý với '),
                        TextSpan(
                          text: 'Điều khoản Dịch vụ',
                          style: AppTypography.labelSemiBold.copyWith(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primary,
                          ),
                        ),
                        const TextSpan(text: ' & '),
                        TextSpan(
                          text: 'Chính sách Bảo mật Y tế HIPAA',
                          style: AppTypography.labelSemiBold.copyWith(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primary,
                          ),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxBox(bool checked) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: checked ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(4),
          border: checked
              ? null
              : Border.all(color: AppColors.checkboxBorder, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: checked
            ? const Center(
                child: Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildPrimaryCtaButton(bool isLoading) {
    return Container(
      width: double.infinity,
      height: 50,
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
                  final ok = await _viewModel.submitRegistration();
                  if (ok) _navigateToTimeline();
                },
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryPeach,
                  ),
                )
              else ...[
                Text(
                  'Đăng Ký Tài Khoản',
                  style: AppTypography.ctaLarge.copyWith(fontSize: 16),
                ),
                const SizedBox(width: 8),
                SvgPicture.asset(
                  'assets/icons/ic_arrow_right_lg.svg',
                  width: 14.67,
                  height: 14.67,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButtons(bool isLoading) {
    return Row(
      children: [
        Expanded(
          child: SocialAuthButton(
            text: 'Apple ID',
            iconAsset: 'assets/icons/ic_apple_dark.svg',
            iconWidth: 16,
            iconHeight: 16,
            height: 44,
            fontSize: 13,
            letterSpacing: 0.3,
            backgroundColor: AppColors.surfaceLight,
            textColor: AppColors.textPrimaryLight,
            onPressed: isLoading
                ? () {}
                : () async {
                    final ok = await _viewModel.registerWithSocial('apple');
                    if (ok) _navigateToTimeline();
                  },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SocialAuthButton(
            text: 'Google',
            iconAsset: 'assets/icons/ic_google.svg',
            iconWidth: 16,
            iconHeight: 16,
            height: 44,
            fontSize: 13,
            letterSpacing: 0.3,
            backgroundColor: AppColors.surfaceLight,
            textColor: AppColors.textPrimaryLight,
            onPressed: isLoading
                ? () {}
                : () async {
                    final ok = await _viewModel.registerWithSocial('google');
                    if (ok) _navigateToTimeline();
                  },
          ),
        ),
      ],
    );
  }

  Widget _buildSignInRedirect() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Đã có tài khoản Sổ Tay Y Tế?',
          style: AppTypography.body,
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Đăng nhập ngay',
                  style: AppTypography.labelSemiBold.copyWith(
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                SvgPicture.asset(
                  'assets/icons/ic_login_redirect.svg',
                  width: 13.5,
                  height: 13.5,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
