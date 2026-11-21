import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/input_validators.dart';
import '../../../../../domain/entities/user_account.dart';
import '../../viewmodel/login_viewmodel.dart';

enum _PhoneAuthStep { enterPhone, verifyOtp, completeNewProfile }

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
  final TextEditingController _fullNameController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  _PhoneAuthStep _step = _PhoneAuthStep.enterPhone;
  String _verificationId = '';
  bool _isExistingAccount = false;
  String _selectedGender = 'Nam';
  String _selectedBloodType = 'Chưa rõ';
  String? _errorMessage;
  bool _isLoading = false;

  Timer? _resendTimer;
  int _secondsRemaining = 60;

  @override
  void dispose() {
    _phoneController.dispose();
    _fullNameController.dispose();
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

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    final phoneErr = InputValidators.validatePhone(phone);
    if (phoneErr != null) {
      setState(() => _errorMessage = phoneErr);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final exists = await widget.viewModel.checkPhoneAccountExists(phone);
      final verId = await widget.viewModel.sendPhoneOtp(phone);
      if (!mounted) return;

      for (final c in _otpControllers) {
        c.clear();
      }
      setState(() {
        _isExistingAccount = exists;
        _verificationId = verId;
        _step = _PhoneAuthStep.verifyOtp;
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

  Future<void> _handleVerifyOtp() async {
    final smsCode = _otpControllers.map((c) => c.text).join().trim();
    if (smsCode.length < 6) {
      setState(
        () => _errorMessage = 'Vui lòng nhập đủ 6 chữ số mã xác thực OTP.',
      );
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
      if (user == null) return;

      final needsIdentityCompletion = !_isExistingAccount &&
          (user.fullName.startsWith('Chủ hồ sơ (') ||
              user.fullName.startsWith('Bệnh nhân ('));

      if (needsIdentityCompletion) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
          _step = _PhoneAuthStep.completeNewProfile;
        });
      } else {
        Navigator.pop(context);
        widget.onSuccess(user);
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = widget.viewModel.state.errorMessage ??
            'Mã xác thực không đúng hoặc đã hết hạn.';
      });
    }
  }

  Future<void> _handleCompleteNewProfile() async {
    final nameErr = InputValidators.validateFullName(_fullNameController.text);
    if (nameErr != null) {
      setState(() => _errorMessage = nameErr);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final ok = await widget.viewModel.completeNewPhoneUserProfile(
      fullName: _fullNameController.text.trim(),
      gender: _selectedGender,
      bloodType: _selectedBloodType,
    );

    if (!mounted) return;

    if (ok && widget.viewModel.loggedInAccount != null) {
      Navigator.pop(context);
      widget.onSuccess(widget.viewModel.loggedInAccount!);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = widget.viewModel.state.errorMessage ??
            'Không thể lưu thông tin chủ hồ sơ.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    String headerTitle = 'Đăng Nhập Số Điện Thoại';
    String headerSubtitle = 'Xác thực nhanh bằng mã SMS OTP 6 số';
    if (_step == _PhoneAuthStep.verifyOtp) {
      headerTitle = 'Xác Thực Mã OTP';
      headerSubtitle = _isExistingAccount
          ? 'Tài khoản đã đăng ký • Xác minh để mở hồ sơ'
          : 'Số điện thoại mới • Xác minh để cấp thẻ STYT';
    } else if (_step == _PhoneAuthStep.completeNewProfile) {
      headerTitle = 'Xác Minh Danh Tính Chủ Thẻ';
      headerSubtitle = 'Hoàn tất họ tên để cấp thẻ y tế STYT chính chủ';
    }

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
                  child: Icon(
                    _step == _PhoneAuthStep.completeNewProfile
                        ? Icons.badge_outlined
                        : Icons.phone_android_rounded,
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
                        headerTitle,
                        style: AppTypography.heading2.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        headerSubtitle,
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
            if (_step == _PhoneAuthStep.enterPhone) _buildPhoneStep(),
            if (_step == _PhoneAuthStep.verifyOtp) _buildOtpStep(),
            if (_step == _PhoneAuthStep.completeNewProfile)
              _buildNewProfileStep(),
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
          'Số điện thoại di động Việt Nam',
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
                      borderSide:
                          const BorderSide(color: AppColors.secCardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 1.5),
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
                  'Hệ thống gửi mã OTP 6 số qua SMS. Nếu SĐT đã đăng ký sẽ vào thẳng hồ sơ cũ; nếu SĐT mới sẽ cấp thẻ STYT-XXXXXX.',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textMuted),
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
            onPressed: _isLoading ? null : _handleSendOtp,
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
    final normalizedDisplay =
        InputValidators.normalizePhoneLocal(_phoneController.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mã gửi tới: $normalizedDisplay',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _step = _PhoneAuthStep.enterPhone;
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
                autofillHints: const [AutofillHints.oneTimeCode],
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                onTap: _isLoading ? null : _handleSendOtp,
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

  Widget _buildNewProfileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Số điện thoại đã xác thực thành công! Vui lòng nhập họ tên thật để in lên Thẻ Cấp Cứu Y Tế của bạn.',
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _fullNameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Họ và tên chủ hồ sơ *',
            hintText: 'VD: Nguyễn Văn An',
            prefixIcon: const Icon(Icons.person_outline_rounded),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: InputDecoration(
                  labelText: 'Giới tính',
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Chưa rõ', child: Text('Chưa rõ')),
                  DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                  DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                  DropdownMenuItem(value: 'Khác', child: Text('Khác')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedGender = val);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedBloodType,
                decoration: InputDecoration(
                  labelText: 'Nhóm máu',
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Chưa rõ', child: Text('Chưa rõ')),
                  DropdownMenuItem(value: 'O+', child: Text('O+')),
                  DropdownMenuItem(value: 'A+', child: Text('A+')),
                  DropdownMenuItem(value: 'B+', child: Text('B+')),
                  DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                  DropdownMenuItem(value: 'O-', child: Text('O-')),
                  DropdownMenuItem(value: 'A-', child: Text('A-')),
                  DropdownMenuItem(value: 'B-', child: Text('B-')),
                  DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedBloodType = val);
                },
              ),
            ),
          ],
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            _errorMessage!,
            style: const TextStyle(color: AppColors.error, fontSize: 12),
          ),
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
            onPressed: _isLoading ? null : _handleCompleteNewProfile,
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
                    'Hoàn Tất & Mở Sổ Tay Y Tế',
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
