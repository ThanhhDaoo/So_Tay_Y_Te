import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
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
  State<RegistrationOtpBottomSheet> createState() => _RegistrationOtpBottomSheetState();
}

class _RegistrationOtpBottomSheetState extends State<RegistrationOtpBottomSheet> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  String? _errorMessage;
  bool _isLoading = false;
  Timer? _resendTimer;
  int _secondsRemaining = 60;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_otpFocusNodes.isNotEmpty) {
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
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleResend() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.viewModel.sendRegistrationOtp();
      if (!mounted) return;
      setState(() => _isLoading = false);
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
    final smsCode = _otpControllers.map((c) => c.text).join();
    if (smsCode.length < 6) {
      setState(() => _errorMessage = 'Vui lòng nhập đủ 6 chữ số mã xác thực.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await widget.viewModel.verifyOtpAndRegister(smsCode);

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
        _errorMessage = widget.viewModel.state.errorMessage ?? 'Mã xác thực không chính xác hoặc đã hết hạn.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final contact = widget.viewModel.contactController.text.trim();

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
                  child: const Icon(
                    Icons.mark_email_read_outlined,
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
                        'Xác Thực Đăng Ký',
                        style: AppTypography.heading2.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Nhập mã 6 số gửi tới: $contact',
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
            const SizedBox(height: 6),
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
                    maxLength: 1,
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
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    onChanged: (value) {
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
                        const Icon(Icons.info_outline, size: 16, color: AppColors.error),
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
                              arguments: contact,
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
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                    )
                  : GestureDetector(
                      onTap: _handleResend,
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isLoading ? null : _handleVerifyOtp,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
          ],
        ),
      ),
    );
  }
}
