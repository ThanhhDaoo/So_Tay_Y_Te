import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/input_validators.dart';
import '../../../../../domain/repositories/auth_repository.dart';
import '../../viewmodel/login_viewmodel.dart';

enum _RecoveryStep { enterIdentifier, verifyOtp, emailLinkSent, setNewPassword }

class ForgotPasswordBottomSheet extends StatefulWidget {
  final LoginViewModel viewModel;
  final String? initialIdentifier;
  final void Function(String recoveredIdentifier) onPasswordResetSuccess;

  const ForgotPasswordBottomSheet({
    super.key,
    required this.viewModel,
    this.initialIdentifier,
    required this.onPasswordResetSuccess,
  });

  static Future<void> show({
    required BuildContext context,
    required LoginViewModel viewModel,
    String? initialIdentifier,
    required void Function(String recoveredIdentifier) onPasswordResetSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ForgotPasswordBottomSheet(
        viewModel: viewModel,
        initialIdentifier: initialIdentifier,
        onPasswordResetSuccess: onPasswordResetSuccess,
      ),
    );
  }

  @override
  State<ForgotPasswordBottomSheet> createState() =>
      _ForgotPasswordBottomSheetState();
}

class _ForgotPasswordBottomSheetState extends State<ForgotPasswordBottomSheet> {
  late final TextEditingController _identifierController;
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  _RecoveryStep _step = _RecoveryStep.enterIdentifier;
  PasswordRecoveryChallenge? _challenge;
  String _verifiedOtpCode = '';
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  Timer? _resendTimer;
  int _secondsRemaining = 60;

  @override
  void initState() {
    super.initState();
    _identifierController = TextEditingController(
      text: widget.initialIdentifier ?? '',
    );
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _resendTimer?.cancel();
    setState(() => _secondsRemaining = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  void _fillOtpDigits(String digits) {
    final clean = digits.replaceAll(RegExp(r'\D'), '');
    for (int i = 0; i < 6; i++) {
      _otpControllers[i].text = i < clean.length ? clean[i] : '';
    }
    setState(() => _errorMessage = null);
    if (clean.length >= 6) {
      _otpFocusNodes[5].requestFocus();
    }
  }

  Future<void> _handleSendChallenge() async {
    final id = _identifierController.text.trim();
    final err = InputValidators.validateLoginIdentifier(id);
    if (err != null) {
      setState(() => _errorMessage = err);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final challenge =
          await widget.viewModel.sendPasswordRecoveryChallenge(id);
      if (!mounted) return;
      for (final c in _otpControllers) {
        c.clear();
      }

      if (challenge.isEmailLinkSent) {
        setState(() {
          _challenge = challenge;
          _step = _RecoveryStep.emailLinkSent;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _challenge = challenge;
        _step = _RecoveryStep.verifyOtp;
        _isLoading = false;
      });
      _startCountdown();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_otpFocusNodes.isNotEmpty && mounted) {
          _otpFocusNodes[0].requestFocus();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _handleProceedToNewPassword() {
    final code = _otpControllers.map((c) => c.text).join().trim();
    if (code.length < 6) {
      setState(
        () => _errorMessage = 'Vui lòng nhập đủ 6 chữ số mã xác minh danh tính.',
      );
      return;
    }

    // Kiểm tra nhanh với mã sandbox nếu có để phản hồi ngay tại bước 2
    final expectedPreview = _challenge?.sandboxOtpPreview;
    if (expectedPreview != null && code != expectedPreview) {
      setState(
        () => _errorMessage =
            'Mã xác minh danh tính không chính xác. Vui lòng kiểm tra lại.',
      );
      return;
    }

    setState(() {
      _verifiedOtpCode = code;
      _errorMessage = null;
      _step = _RecoveryStep.setNewPassword;
    });
  }

  Future<void> _handleSubmitNewPassword() async {
    final passErr =
        InputValidators.validatePassword(_newPasswordController.text);
    if (passErr != null) {
      setState(() => _errorMessage = passErr);
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(
        () => _errorMessage = 'Mật khẩu xác nhận không khớp. Vui lòng kiểm tra lại.',
      );
      return;
    }

    final challenge = _challenge;
    if (challenge == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final ok = await widget.viewModel.verifyRecoveryAndResetPassword(
      identifier: _identifierController.text.trim(),
      verificationId: challenge.verificationId,
      otpCode: _verifiedOtpCode,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;

    if (ok) {
      final recoveredId = _identifierController.text.trim();
      Navigator.pop(context);
      widget.onPasswordResetSuccess(recoveredId);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = widget.viewModel.state.errorMessage ??
            'Không thể đặt lại mật khẩu. Vui lòng thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 24),
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _buildHeader(),
            const Divider(height: 28),
            if (_step == _RecoveryStep.enterIdentifier) _buildIdentifierStep(),
            if (_step == _RecoveryStep.verifyOtp) _buildOtpStep(),
            if (_step == _RecoveryStep.emailLinkSent) _buildEmailLinkSentStep(),
            if (_step == _RecoveryStep.setNewPassword) _buildNewPasswordStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String title = 'Khôi Phục Mật Khẩu';
    String subtitle = 'Bước 1/3 • Định danh chủ hồ sơ y tế';
    if (_step == _RecoveryStep.verifyOtp) {
      title = 'Xác Minh Danh Tính';
      subtitle = 'Bước 2/3 • Nhập mã OTP gửi tới ${_challenge?.maskedContact ?? ''}';
    } else if (_step == _RecoveryStep.setNewPassword) {
      title = 'Thiết Lập Mật Khẩu Mới';
      subtitle = 'Bước 3/3 • Mã hóa bảo mật SHA-256';
    } else if (_step == _RecoveryStep.emailLinkSent) {
      title = 'Kiểm Tra Hộp Thư Email';
      subtitle = 'Đã gửi liên kết đặt lại mật khẩu bảo mật';
    }

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.verified_user_outlined,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.heading2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIdentifierStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nhập Số điện thoại, Email hoặc Mã hồ sơ đã đăng ký để nhận mã xác minh danh tính chính chủ.',
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _identifierController,
          decoration: InputDecoration(
            labelText: 'SĐT, Email hoặc Mã hồ sơ (STYT-XXXXXX)',
            hintText: 'VD: 0912345678 hoặc ten@gmail.com',
            prefixIcon: const Icon(Icons.badge_outlined, size: 20),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.secCardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 10),
          _buildErrorBanner(_errorMessage!),
        ],
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
            onPressed: _isLoading ? null : _handleSendChallenge,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Gửi Mã Xác Minh Danh Tính',
                    style: AppTypography.labelSemiBold.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Mã bảo mật đã gửi tới: ${_challenge?.maskedContact ?? ''}',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _step = _RecoveryStep.enterIdentifier;
                  _errorMessage = null;
                });
              },
              child: Text(
                'Đổi tài khoản',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 44,
              height: 52,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.secCardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                onChanged: (value) {
                  if (value.length > 1) {
                    _fillOtpDigits(value);
                    return;
                  }
                  if (value.isNotEmpty && index < 5) {
                    _otpFocusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }
                  if (index == 5 && value.isNotEmpty) {
                    _handleProceedToNewPassword();
                  }
                },
              ),
            );
          }),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 10),
          _buildErrorBanner(_errorMessage!),
        ],
        const SizedBox(height: 14),
        Center(
          child: _secondsRemaining > 0
              ? Text(
                  'Gửi lại mã sau (${_secondsRemaining}s)',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                )
              : GestureDetector(
                  onTap: _isLoading ? null : _handleSendChallenge,
                  child: Text(
                    'Gửi lại mã OTP mới',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 18),
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
            onPressed: _isLoading ? null : _handleProceedToNewPassword,
            child: Text(
              'Xác Minh Danh Tính',
              style: AppTypography.labelSemiBold.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailLinkSentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.iceOlive),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.mark_email_read_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hệ thống đã gửi liên kết khôi phục mật khẩu chính chủ tới hộp thư ${_challenge?.maskedContact ?? ''}.\n\nVui lòng mở Email (kiểm tra cả mục Quảng cáo/Spam) và nhấn vào liên kết để tạo mật khẩu mới.',
                  style: AppTypography.body,
                ),
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
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Đã Hiểu, Quay Lại Đăng Nhập',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _newPasswordController,
          obscureText: _obscureNew,
          decoration: InputDecoration(
            labelText: 'Mật khẩu mới (tối thiểu 6 ký tự)',
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
              icon: Icon(
                _obscureNew
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
            ),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            labelText: 'Nhập lại mật khẩu mới',
            prefixIcon: const Icon(Icons.verified_outlined, size: 20),
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
            ),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 10),
          _buildErrorBanner(_errorMessage!),
        ],
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
            onPressed: _isLoading ? null : _handleSubmitNewPassword,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Lưu Mật Khẩu Mới',
                    style: AppTypography.labelSemiBold.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
