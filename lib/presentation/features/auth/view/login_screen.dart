import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/supabase_config.dart';
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
import 'widgets/cloud_backend_status_badge.dart';
import 'widgets/forgot_password_bottom_sheet.dart';
import 'widgets/guest_mode_card.dart';
import 'widgets/phone_otp_bottom_sheet.dart';
import 'widgets/pulsing_biometric_button.dart';
import 'widgets/social_auth_button.dart';

class LoginScreen extends StatefulWidget {
  final String? initialIdentifier;

  const LoginScreen({
    super.key,
    this.initialIdentifier,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  late final LoginViewModel _viewModel;
  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _viewModel = LoginViewModel();
    if (widget.initialIdentifier != null &&
        widget.initialIdentifier!.isNotEmpty) {
      _viewModel.identifierController.text = widget.initialIdentifier!;
    }
    _initOAuthListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoLogin();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _viewModel.isAwaitingOAuth) {
      // Đợi ngắn để Deep Link OAuth callback kịp xử lý nếu người dùng vừa xác thực xong
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && _viewModel.isAwaitingOAuth) {
          _viewModel.cancelPendingOAuth();
        }
      });
    }
  }

  void _initOAuthListener() {
    final client = SupabaseConfig.client;
    if (client != null) {
      _authStateSubscription = client.auth.onAuthStateChange.listen(
        (data) async {
          final event = data.event;
          final session = data.session;
          // CHỈ bắt sự kiện signedIn khi màn hình này đang chủ động chờ OAuth callback
          if (event == AuthChangeEvent.signedIn &&
              session != null &&
              mounted &&
              _viewModel.isAwaitingOAuth) {
            try {
              await closeInAppWebView();
            } catch (_) {}
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
              await _handleLoginSuccess();
            }
          }
        },
        onError: (Object error) async {
          if (!mounted) return;
          if (_viewModel.isAwaitingOAuth) {
            try {
              await closeInAppWebView();
            } catch (_) {}
            _viewModel.handleOAuthError(error);
          }
        },
      );
    }
  }

  Future<void> _checkAutoLogin() async {
    final hasActiveSession = await _viewModel.checkAutoLogin();
    if (!hasActiveSession || !mounted) return;

    if (_viewModel.state.requiresAppLockUnlock) {
      Navigator.pushNamed(
        context,
        AppRoutes.appLock,
        arguments: () {
          if (mounted) {
            _handleLoginSuccess();
          }
        },
      );
    } else {
      await _handleLoginSuccess();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authStateSubscription?.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleLoginSuccess() async {
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
                              label: 'Số điện thoại, Email hoặc Mã hồ sơ',
                              trailingLabel: 'VD: 0912... hoặc STYT',
                              trailingLabelColor: AppColors.textMuted,
                              hintText: '0912345678 hoặc ten@gmail.com',
                              prefixIconAsset: 'assets/icons/ic_badge_id.svg',
                              controller: _viewModel.identifierController,
                              validator: InputValidators.validateLoginIdentifier,
                            ),
                          ),
                          const SizedBox(height: 16),
                          AuthAnimatedEntrance(
                            delay: const Duration(milliseconds: 200),
                            child: AuthTextField(
                              label: 'Mật khẩu hồ sơ',
                              hintText: 'Nhập mật khẩu bảo mật',
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
                              validator: InputValidators.validatePassword,
                            ),
                          ),
                          const SizedBox(height: 14),
                          AuthAnimatedEntrance(
                            delay: const Duration(milliseconds: 260),
                            child: _buildRememberAndForgot(state.rememberMe),
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
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.iceDangerBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      AppColors.error.withValues(alpha: 0.35),
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
          const CloudBackendStatusBadge(),
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
                        if (ok) {
                          if (!_viewModel.state.isAwaitingOAuth &&
                              _viewModel.state.loggedInUser != null) {
                            await _handleLoginSuccess();
                          }
                        } else if (mounted) {
                          _showSocialAuthNotice(
                            context,
                            title: 'Đăng nhập Apple ID',
                            message: _viewModel.state.errorMessage ??
                                'Chưa kích hoạt Apple Sign-In.',
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
                iconWidth: 18,
                iconHeight: 18,
                height: 44,
                backgroundColor: AppColors.surfaceLight,
                textColor: AppColors.textPrimaryLight,
                onPressed: isLoading
                    ? () {}
                    : () async {
                        final ok = await _viewModel.signInWithSocial('google');
                        if (ok) {
                          if (!_viewModel.state.isAwaitingOAuth &&
                              _viewModel.state.loggedInUser != null) {
                            await _handleLoginSuccess();
                          }
                        } else if (mounted) {
                          _showSocialAuthNotice(
                            context,
                            title: 'Đăng nhập Google Account',
                            message: _viewModel.state.errorMessage ??
                                'Chưa kích hoạt Google Sign-In.',
                          );
                        }
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
              : () {
                  PhoneOtpBottomSheet.show(
                    context: context,
                    viewModel: _viewModel,
                    onSuccess: (account) async {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Xin chào ${account.fullName}! Mã hồ sơ: ${account.patientCode}',
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      await _handleLoginSuccess();
                    },
                  );
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
          onTap: _openForgotPasswordFlow,
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
            final ok = await _viewModel.signInWithBiometrics();
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

  void _openForgotPasswordFlow() {
    ForgotPasswordBottomSheet.show(
      context: context,
      viewModel: _viewModel,
      initialIdentifier: _viewModel.identifierController.text.trim(),
      onPasswordResetSuccess: (recoveredId) {
        if (!mounted) return;
        _viewModel.identifierController.text = recoveredId;
        _viewModel.passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đã xác minh danh tính và cập nhật mật khẩu mới thành công! Vui lòng đăng nhập.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      },
    );
  }

  void _showSocialAuthNotice(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: AppTypography.heading2.copyWith(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: AppTypography.body),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(80),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '💡 Gợi ý: Bạn có thể sử dụng "Đăng nhập với Số Điện Thoại / OTP" hoặc tạo tài khoản Email để đồng bộ dữ liệu ngay lập tức.',
                style: AppTypography.caption
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, AppRoutes.register);
            },
            child: const Text(
              'Đăng Ký Tài Khoản',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
