import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../domain/entities/user_account.dart';
import '../../viewmodel/login_viewmodel.dart';

class PhoneOtpBottomSheet extends StatefulWidget {
  final LoginViewModel viewModel;
  final void Function(UserAccount account) onSuccess;

  const PhoneOtpBottomSheet({
    super.key,
    required this.viewModel,
    required this.onSuccess,
  });

  static Future<void> show({
    required BuildContext context,
    required LoginViewModel viewModel,
    required void Function(UserAccount account) onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PhoneOtpBottomSheet(
        viewModel: viewModel,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<PhoneOtpBottomSheet> createState() => _PhoneOtpBottomSheetState();
}

class _PhoneOtpBottomSheetState extends State<PhoneOtpBottomSheet> {
  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isCodeSent = false;
  String _verificationId = '';
  String? _errorMessage;
  bool _isLoading = false;

  Timer? _resendTimer;
  int _secondsRemaining = 60;

  @override
  void dispose() {
    _phoneController.dispose();
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

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 9) {
      setState(() => _errorMessage = 'Vui lòng nhập số điện thoại hợp lệ (tối thiểu 9 số).');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final verId = await widget.viewModel.sendPhoneOtp(phone);
      if (!mounted) return;
      setState(() {
        _isCodeSent = true;
        _verificationId = verId;
        _isLoading = false;
      });
      _startCountdown();
      // Tự động focus vào ô OTP đầu tiên
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_otpFocusNodes.isNotEmpty) {
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

  Future<void> _handleVerifyOtp() async {
    final smsCode = _otpControllers.map((c) => c.text).join();
    if (smsCode.length < 6) {
      setState(() => _errorMessage = 'Vui lòng nhập đủ 6 chữ số mã xác thực OTP.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await widget.viewModel.verifyPhoneOtp(
      phoneNumber: _phoneController.text.trim(),
      verificationId: _verificationId,
      smsCode: smsCode,
    );

    if (!mounted) return;

    if (success) {
      final user = widget.viewModel.loggedInAccount;
      if (user != null) {
        Navigator.pop(context);
        widget.onSuccess(user);
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = widget.viewModel.state.errorMessage ?? 'Mã xác thực không đúng hoặc đã hết hạn.';
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phone_android_rounded,
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
                        _isCodeSent ? 'Xác Thực Mã OTP' : 'Đăng Nhập Số Điện Thoại',
                        style: AppTypography.heading2.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Bảo mật đám mây Firebase & Supabase OTP',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            if (!_isCodeSent) _buildPhoneStep() else _buildOtpStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Số điện thoại của bạn',
          style: AppTypography.labelSemiBold.copyWith(
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.secCardBorder),
              ),
              child: const Row(
                children: [
                  Text('🇻🇳', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 6),
                  Text(
                    '+84',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 50,
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: '0912 345 678',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
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
              ),
            ),
          ],
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: const TextStyle(color: AppColors.error, fontSize: 12),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.iceOlive),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hệ thống sẽ gửi mã xác minh 6 số qua SMS. Nếu chưa có hồ sơ, mã thẻ STYT-XXXXXX sẽ được cấp tự động.',
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _isLoading ? null : _handleSendOtp,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    'Gửi Mã Xác Thực (SMS OTP)',
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
            Text(
              'Mã gửi tới: ${_phoneController.text}',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isCodeSent = false;
                  _errorMessage = null;
                });
              },
              child: Text(
                'Đổi số',
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
          Text(
            _errorMessage!,
            style: const TextStyle(color: AppColors.error, fontSize: 12),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_secondsRemaining > 0)
              Text(
                'Gửi lại mã sau (${_secondsRemaining}s)',
                style: AppTypography.caption.copyWith(color: AppColors.textMuted),
              )
            else
              GestureDetector(
                onTap: _handleSendOtp,
                child: Text(
                  'Gửi lại mã OTP',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
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
                    'Xác Nhận & Đăng Nhập',
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
}
