import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/input_validators.dart';
import '../../../../../domain/entities/user_account.dart';
import '../../../../routes/app_routes.dart';
import '../../viewmodel/register_viewmodel.dart';

class RegistrationOtpBottomSheet extends StatefulWidget {
  final RegisterViewModel viewModel;
  final void Function(UserAccount account) onSuccess;

  const RegistrationOtpBottomSheet({
    super.key,
    required this.viewModel,
    required this.onSuccess,
  });

  static Future<void> show({
    required BuildContext context,
    required RegisterViewModel viewModel,
    required void Function(UserAccount account) onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RegistrationOtpBottomSheet(
        viewModel: viewModel,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<RegistrationOtpBottomSheet> createState() =>
      _RegistrationOtpBottomSheetState();
}

class _RegistrationOtpBottomSheetState
    extends State<RegistrationOtpBottomSheet> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  String? _errorMessage;
  String? _sandboxOtpCode;
  bool _isLoading = false;
  Timer? _resendTimer;
  int _secondsRemaining = 60;

  @override
  void initState() {
    super.initState();
    _sandboxOtpCode = widget.viewModel.peekSandboxOtp();
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_otpFocusNodes.isNotEmpty && mounted) {
        _otpFocusNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
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

  void _fillOtpDigits(String raw) {
    final clean = raw.replaceAll(RegExp(r'\D'), '');
    for (int i = 0; i < 6; i++) {
      _otpControllers[i].text = i < clean.length ? clean[i] : '';
    }
    setState(() => _errorMessage = null);
    if (clean.length >= 6) {
      _otpFocusNodes[5].requestFocus();
    }
  }

  Future<void> _handleResend() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.viewModel.sendRegistrationOtp();
      if (!mounted) return;
      for (final c in _otpControllers) {
        c.clear();
      }
      setState(() {
        _sandboxOtpCode = widget.viewModel.peekSandboxOtp();
        _isLoading = false;
      });
      _startCountdown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otpCode = _otpControllers.map((c) => c.text).join().trim();
    if (otpCode.length < 6) {
      setState(
        () => _errorMessage = 'Vui lòng nhập đủ 6 chữ số mã xác thực.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await widget.viewModel.verifyOtpAndRegister(otpCode);

    if (!mounted) return;

    if (success) {
      final user = widget.viewModel.state.createdAccount;
      if (user != null) {
        Navigator.pop(context);
        widget.onSuccess(user);
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = widget.viewModel.state.errorMessage ??
            'Mã xác thực không chính xác hoặc đã hết hạn.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final rawContact = widget.viewModel.contactController.text.trim();
    final isEmail = widget.viewModel.isPendingEmailOtp || rawContact.contains('@');
    final displayContact = isEmail
        ? rawContact.toLowerCase()
        : InputValidators.normalizePhoneLocal(rawContact);

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
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isEmail
                        ? Icons.mark_email_read_outlined
                        : Icons.sms_outlined,
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
                        isEmail ? 'Xác Thực Email Đăng Ký' : 'Xác Thực Số Điện Thoại',
                        style: AppTypography.heading2.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isEmail
                            ? 'Nhập mã 6 số hoặc mở hộp thư nhấn Link xác nhận: $displayContact'
                            : 'Nhập mã 6 số gửi tới: $displayContact',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            if (_sandboxOtpCode != null && !isEmail) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.iceOlive.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.sms_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'SMS OTP vừa nhận: $_sandboxOtpCode',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _fillOtpDigits(_sandboxOtpCode!),
                      child: const Text(
                        'Điền nhanh',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
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
                    textAlign: TextAlign.center,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: AppColors.secCardBorder),
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
                        _handleVerifyOtp();
                      }
                    },
                  ),
                );
              }),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_errorMessage!.contains('đã được đăng ký')) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.login, size: 16),
                          label: const Text('Chuyển sang Đăng Nhập ngay'),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.login,
                              arguments: displayContact,
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Center(
              child: _secondsRemaining > 0
                  ? Text(
                      'Gửi lại mã sau (${_secondsRemaining}s)',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    )
                  : GestureDetector(
                      onTap: _isLoading ? null : _handleResend,
                      child: Text(
                        'Gửi lại mã OTP',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                onPressed: _isLoading ? null : _handleVerifyOtp,
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
                        'Xác Thực & Tạo Hồ Sơ Y Tế',
                        style: AppTypography.labelSemiBold.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            if (isEmail) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    'Tôi đã bấm Link xác nhận trong Email',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() {
                            _isLoading = true;
                            _errorMessage = null;
                          });
                          final ok = await widget.viewModel
                              .confirmEmailLinkVerified();
                          if (!context.mounted) return;
                          if (ok &&
                              widget.viewModel.state.createdAccount != null) {
                            Navigator.pop(context);
                            widget.onSuccess(
                              widget.viewModel.state.createdAccount!,
                            );
                          } else {
                            setState(() {
                              _isLoading = false;
                              _errorMessage =
                                  widget.viewModel.state.errorMessage ??
                                      'Email chưa được xác nhận. Vui lòng mở thư và nhấn vào liên kết xác nhận trước.';
                            });
                          }
                        },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
