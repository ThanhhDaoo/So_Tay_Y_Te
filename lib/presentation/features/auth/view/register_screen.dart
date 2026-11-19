import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../domain/entities/user_account.dart';
import '../../../routes/app_routes.dart';
import '../viewmodel/register_state.dart';
import '../viewmodel/register_viewmodel.dart';
import 'widgets/auth_ambient_background.dart';
import 'widgets/auth_animated_entrance.dart';
import 'widgets/auth_divider.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/cloud_backend_status_badge.dart';
import 'widgets/guest_migration_notice_card.dart';
import 'widgets/password_strength_meter.dart';
import 'widgets/registration_otp_bottom_sheet.dart';
import 'widgets/social_auth_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final RegisterViewModel _viewModel;
  StreamSubscription<AuthState>? _authStateSubscription;
  bool _isProcessingOAuth = false;

  @override
  void initState() {
    super.initState();
    _viewModel = RegisterViewModel();
    _initOAuthListener();
  }

  bool _isSocialOAuthUser(User user) {
    final provider = user.appMetadata['provider'] as String?;
    if (provider == 'google' || provider == 'apple') return true;
    final identities = user.identities;
    if (identities != null) {
      return identities.any(
        (i) => i.provider == 'google' || i.provider == 'apple',
      );
    }
    return false;
  }

  void _initOAuthListener() {
    final client = SupabaseConfig.client;
    if (client != null) {
      _authStateSubscription = client.auth.onAuthStateChange.listen(
        (data) async {
          final event = data.event;
          final session = data.session;
          if (_isProcessingOAuth ||
              _viewModel.isSocialCallInFlight ||
              !mounted ||
              session == null) {
            return;
          }

          final isCurrentScreen = ModalRoute.of(context)?.isCurrent ?? true;
          final shouldHandle = event == AuthChangeEvent.signedIn &&
              (_viewModel.isAwaitingOAuth ||
                  (isCurrentScreen && _isSocialOAuthUser(session.user)));

          if (shouldHandle) {
            _isProcessingOAuth = true;
            try {
              await closeInAppWebView();
            } catch (_) {}
            try {
              final user = session.user;
              final meta = user.userMetadata ?? const <String, dynamic>{};
              final success = await _viewModel.handleOAuthSessionSuccess(
                userId: user.id,
                email: user.email,
                fullName:
                    (meta['full_name'] as String?) ?? (meta['name'] as String?),
                avatarUrl: (meta['avatar_url'] as String?) ??
                    (meta['picture'] as String?),
              );
              if (success && mounted) {
                final account = _viewModel.state.createdAccount;
                if (account != null) {
                  _showSuccessRegistrationDialog(account);
                } else {
                  _navigateToTimeline();
                }
              }
            } finally {
              _isProcessingOAuth = false;
            }
          }
        },
        onError: (Object error) async {
          if (!mounted) return;
          final isCurrentScreen = ModalRoute.of(context)?.isCurrent ?? true;
          if (_viewModel.isAwaitingOAuth || isCurrentScreen) {
            try {
              await closeInAppWebView();
            } catch (_) {}
            _viewModel.handleOAuthError(error);
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  void _navigateToTimeline() {
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.mainShell,
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
                      child: _buildTopAssuranceBlock(),
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _viewModel.formKey,
                      child: Column(
                        children: [
                          AuthAnimatedEntrance(
                            delay: const Duration(milliseconds: 140),
                            child: AuthTextField(
                              label: 'Họ và tên chủ hồ sơ',
                              isRequired: true,
                              hintText: 'Nguyễn Văn An',
                              prefixIconAsset: 'assets/icons/ic_user_badge.svg',
                              controller: _viewModel.fullNameController,
                              validator: InputValidators.validateFullName,
                            ),
                          ),
                          const SizedBox(height: 16),
                          AuthAnimatedEntrance(
                            delay: const Duration(milliseconds: 200),
                            child: AuthTextField(
                              label: 'Số điện thoại hoặc Email',
                              isRequired: true,
                              hintText: '0912345678 hoặc ten@gmail.com',
                              hintColor: AppColors.textHintAlt,
                              prefixIconAsset:
                                  'assets/icons/ic_contact_mail.svg',
                              prefixIconWidth: 20,
                              prefixIconHeight: 15,
                              controller: _viewModel.contactController,
                              validator: InputValidators.validateEmailOrPhone,
                            ),
                          ),
                          const SizedBox(height: 16),
                          AuthAnimatedEntrance(
                            delay: const Duration(milliseconds: 230),
                            child: _buildDemographicsRow(state),
                          ),
                          const SizedBox(height: 14),
                          AuthAnimatedEntrance(
                            delay: const Duration(milliseconds: 245),
                            child: _buildGenderSelector(state.gender),
                          ),
                          const SizedBox(height: 16),
                          AuthAnimatedEntrance(
                            delay: const Duration(milliseconds: 260),
                            child: Column(
                              children: [
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
                                  suffixIconAsset:
                                      'assets/icons/ic_eye_toggle.svg',
                                  suffixIconWidth: 26.33,
                                  suffixIconHeight: 26.5,
                                  onChanged: _viewModel.onPasswordChanged,
                                  validator: InputValidators.validatePassword,
                                ),
                                const SizedBox(height: 8),
                                PasswordStrengthMeter(
                                  strength: state.passwordStrength,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          AuthAnimatedEntrance(
                            delay: const Duration(milliseconds: 320),
                            child: AuthTextField(
                              label: 'Xác nhận lại mật khẩu',
                              isRequired: true,
                              hintText: 'Nhập lại mật khẩu bảo mật',
                              hintColor: AppColors.textHintAlt,
                              prefixIconAsset: 'assets/icons/ic_lock_reset.svg',
                              controller: _viewModel.confirmPasswordController,
                              obscureText: state.obscureConfirmPassword,
                              onToggleObscure:
                                  _viewModel.toggleConfirmPasswordVisibility,
                              suffixIconAsset: 'assets/icons/ic_eye_toggle.svg',
                              suffixIconWidth: 26.33,
                              suffixIconHeight: 26.5,
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
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    AuthAnimatedEntrance(
                      delay: const Duration(milliseconds: 380),
                      child: _buildSecurityOptionsCard(
                        enableBiometric: state.enableBiometric,
                        acceptedTerms: state.acceptedTerms,
                      ),
                    ),
                    if (state.isAwaitingOAuth) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.iceOlive),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Đang chờ xác thực tài khoản trên trình duyệt...',
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _viewModel.cancelPendingOAuth,
                              child: const Text('Hủy'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: AppColors.error,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    state.errorMessage!,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (state.errorMessage!
                                .contains('đã được đăng ký')) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(Icons.login, size: 16),
                                  label:
                                      const Text('Chuyển sang Đăng Nhập ngay'),
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      AppRoutes.login,
                                      arguments: _viewModel
                                          .contactController.text
                                          .trim(),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    AuthAnimatedEntrance(
                      delay: const Duration(milliseconds: 440),
                      child: _buildPrimaryCtaButton(state.isLoading),
                    ),
                    const SizedBox(height: 22),
                    const AuthAnimatedEntrance(
                      delay: Duration(milliseconds: 500),
                      child: AuthDivider(
                        text: 'HOẶC ĐĂNG KÝ NHANH',
                        uppercase: true,
                        textColor: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AuthAnimatedEntrance(
                      delay: const Duration(milliseconds: 560),
                      child: _buildSocialButtons(state.isLoading),
                    ),
                    const SizedBox(height: 20),
                    const AuthAnimatedEntrance(
                      delay: Duration(milliseconds: 620),
                      child: GuestMigrationNoticeCard(),
                    ),
                    const SizedBox(height: 20),
                    AuthAnimatedEntrance(
                      delay: const Duration(milliseconds: 680),
                      child: _buildSignInRedirect(),
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

  Widget _buildDemographicsRow(RegisterState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: AuthTextField(
            label: 'Ngày tháng năm sinh',
            isRequired: false,
            hintText: 'Chọn ngày sinh',
            prefixIconAsset: 'assets/icons/ic_prof_cake_dob.svg',
            controller: _viewModel.dobController,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                locale: const Locale('vi', 'VN'),
                helpText: 'CHỌN NGÀY SINH',
                confirmText: 'CHỌN',
                cancelText: 'HỦY',
                initialDate: state.dateOfBirth ?? DateTime(2000, 1, 1),
                firstDate: DateTime(1920),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.primary,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: AppColors.textPrimaryLight,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                _viewModel.setDateOfBirth(picked);
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nhóm máu',
                style: AppTypography.labelSemiBold,
              ),
              const SizedBox(height: 6),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: state.bloodType,
                    isExpanded: true,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'O+', child: Text('O+')),
                      DropdownMenuItem(value: 'A+', child: Text('A+')),
                      DropdownMenuItem(value: 'B+', child: Text('B+')),
                      DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                      DropdownMenuItem(value: 'O-', child: Text('O-')),
                      DropdownMenuItem(value: 'A-', child: Text('A-')),
                      DropdownMenuItem(value: 'B-', child: Text('B-')),
                      DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                      DropdownMenuItem(
                        value: 'Chưa rõ',
                        child: Text('Chưa rõ'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) _viewModel.setBloodType(val);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector(String selectedGender) {
    const genders = ['Nam', 'Nữ', 'Khác'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Giới tính sinh học',
          style: AppTypography.labelSemiBold,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (int i = 0; i < genders.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => _viewModel.setGender(genders[i]),
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selectedGender == genders[i]
                          ? AppColors.primary
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selectedGender == genders[i]
                            ? AppColors.primary
                            : AppColors.secCardBorder,
                      ),
                    ),
                    child: Text(
                      genders[i],
                      style: AppTypography.labelSmallSemiBold.copyWith(
                        color: selectedGender == genders[i]
                            ? Colors.white
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTopAssuranceBlock() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CloudBackendStatusBadge(),
          const SizedBox(height: 10),
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
                            (!kIsWeb && (Platform.isIOS || Platform.isMacOS))
                                ? 'assets/icons/ic_apple_face_id.svg'
                                : 'assets/icons/ic_fingerprint_small.svg',
                            width: 14,
                            height: 14,
                            colorFilter: const ColorFilter.mode(
                              AppColors.iceOlive,
                              BlendMode.srcIn,
                            ),
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
                  final nextStep =
                      await _viewModel.initiateRegistrationFlow();
                  if (!mounted) return;

                  if (nextStep == RegistrationFlowStep.requirePhoneOtp ||
                      nextStep == RegistrationFlowStep.requireEmailOtp) {
                    RegistrationOtpBottomSheet.show(
                      context: context,
                      viewModel: _viewModel,
                      onSuccess: (account) {
                        if (mounted) {
                          _showSuccessRegistrationDialog(account);
                        }
                      },
                    );
                  } else if (nextStep == RegistrationFlowStep.completed) {
                    final account = _viewModel.state.createdAccount;
                    if (account != null) {
                      _showSuccessRegistrationDialog(account);
                    } else {
                      _navigateToTimeline();
                    }
                  }
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
                    if (ok) {
                      if (!_viewModel.state.isAwaitingOAuth &&
                          _viewModel.state.createdAccount != null) {
                        _showSuccessRegistrationDialog(
                          _viewModel.state.createdAccount!,
                        );
                      }
                    } else if (mounted &&
                        _viewModel.state.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_viewModel.state.errorMessage!),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
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
                    if (ok) {
                      if (!_viewModel.state.isAwaitingOAuth &&
                          _viewModel.state.createdAccount != null) {
                        _showSuccessRegistrationDialog(
                          _viewModel.state.createdAccount!,
                        );
                      }
                    } else if (mounted &&
                        _viewModel.state.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_viewModel.state.errorMessage!),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
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

  void _showSuccessRegistrationDialog(UserAccount account) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppColors.surfaceLight,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/ic_shield_check.svg',
                      width: 32,
                      height: 32,
                      colorFilter: const ColorFilter.mode(
                        AppColors.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cấp Thẻ Y Tế Thành Công!',
                  style: AppTypography.heading2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Hồ sơ của bạn đã được khởi tạo và mã hóa an toàn trên hệ thống Sổ Tay Y Tế.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.iceOlive.withAlpha(120)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'MÃ ĐỊNH DANH HỒ SƠ Y TẾ',
                        style: AppTypography.caption.copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        account.patientCode,
                        style: AppTypography.heading1.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Chủ thẻ:', style: AppTypography.caption),
                          Flexible(
                            child: Text(
                              account.fullName,
                              textAlign: TextAlign.right,
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Liên hệ:', style: AppTypography.caption),
                          Flexible(
                            child: Text(
                              account.primaryContact,
                              textAlign: TextAlign.right,
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Nhóm máu:', style: AppTypography.caption),
                          Text(
                            account.bloodType ?? 'Chưa rõ',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _navigateToTimeline();
                    },
                    child: Text(
                      'Bắt Đầu Sử Dụng',
                      style: AppTypography.labelSemiBold.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
