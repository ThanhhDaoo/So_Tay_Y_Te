import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/security/biometric_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/repositories/auth_repository.dart';
import '../../../routes/app_routes.dart';
import '../viewmodel/security_settings_viewmodel.dart';

class AppLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  final SecuritySettingsViewModel? viewModel;

  const AppLockScreen({
    super.key,
    required this.onUnlocked,
    this.viewModel,
  });

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  late final SecuritySettingsViewModel _viewModel;
  String _pin = '';
  String? _errorMessage;
  bool _isAuthenticating = false;
  bool _hasPinConfigured = true;
  int _lockoutRemainingSeconds = 0;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    AppRoutes.isAppLockShowing = true;
    _viewModel = widget.viewModel ?? SecuritySettingsViewModel();
    _syncLockState();
    // Auto-prompt Face ID upon opening if biometrics is enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptBiometricAuth();
    });
  }

  Future<void> _syncLockState() async {
    final hasPin = await _viewModel.hasConfiguredPin();
    final rem = await _viewModel.getPinLockoutRemainingSeconds();
    if (!mounted) return;
    setState(() {
      _hasPinConfigured = hasPin;
      _lockoutRemainingSeconds = rem;
      if (rem > 0) {
        _errorMessage = 'Nhập sai quá số lần quy định. Tạm khóa sau ${rem}s.';
      }
    });
    if (rem > 0) {
      _startLockoutCountdown();
    }
  }

  void _startLockoutCountdown() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final rem = await _viewModel.getPinLockoutRemainingSeconds();
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _lockoutRemainingSeconds = rem;
        if (rem > 0) {
          _errorMessage = 'Nhập sai quá số lần quy định. Tạm khóa sau ${rem}s.';
        } else {
          _errorMessage = null;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    AppRoutes.isAppLockShowing = false;
    super.dispose();
  }

  Future<void> _attemptBiometricAuth() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    try {
      final biometricService = sl.isRegistered<BiometricService>()
          ? sl<BiometricService>()
          : BiometricServiceImpl();

      final isAvailable = await biometricService.isBiometricAvailable();
      if (isAvailable) {
        final success = await biometricService.authenticate(
          localizedReason: 'Xác thực Face ID để mở khóa Sổ Tay Y Tế',
        );
        if (success && mounted) {
          AppRoutes.isAppLockShowing = false;
          widget.onUnlocked();
          return;
        }
      }
    } catch (_) {} finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  Future<void> _onKeyPress(String key) async {
    if (_lockoutRemainingSeconds > 0) return;

    if (!_hasPinConfigured) {
      setState(() {
        _errorMessage =
            'Bạn chưa thiết lập mã PIN 6 số. Vui lòng quét Face ID hoặc mở khóa bằng mật khẩu tài khoản bên dưới.';
      });
      return;
    }

    if (_pin.length < 6) {
      setState(() {
        _pin += key;
        _errorMessage = null;
      });

      if (_pin.length == 6) {
        final entered = _pin;
        final isValid = await _viewModel.verifyPin(entered);
        if (!mounted) return;

        if (isValid) {
          HapticFeedback.lightImpact();
          AppRoutes.isAppLockShowing = false;
          widget.onUnlocked();
        } else {
          HapticFeedback.heavyImpact();
          final lockoutSec = await _viewModel.getPinLockoutRemainingSeconds();
          if (!mounted) return;
          setState(() {
            _pin = '';
            _lockoutRemainingSeconds = lockoutSec;
            _errorMessage = lockoutSec > 0
                ? 'Nhập sai quá 5 lần. Tạm khóa bàn phím trong ${lockoutSec}s!'
                : 'Mã PIN không chính xác. Vui lòng thử lại!';
          });
          if (lockoutSec > 0) {
            _startLockoutCountdown();
          }
        }
      }
    }
  }

  void _onDelete() {
    if (_lockoutRemainingSeconds > 0) return;
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _showPasswordUnlockDialog() {
    final pwdCtrl = TextEditingController();
    String? dialogErr;
    bool submitting = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Mở Khóa Bằng Mật Khẩu Hồ Sơ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nhập mật khẩu đăng nhập tài khoản hiện tại để mở khóa hoặc đăng xuất về màn hình chính.',
                style: TextStyle(fontSize: 12.5, color: AppColors.iceTextSlate),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pwdCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu tài khoản',
                  errorText: dialogErr,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                if (sl.isRegistered<AuthRepository>()) {
                  await sl<AuthRepository>().logout();
                }
                if (mounted) {
                  AppRoutes.isAppLockShowing = false;
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.login,
                    (route) => false,
                  );
                }
              },
              child: const Text('Đăng xuất', style: TextStyle(color: AppColors.error)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: submitting
                  ? null
                  : () async {
                      setDialogState(() {
                        submitting = true;
                        dialogErr = null;
                      });
                      final ok = await _viewModel.unlockWithAccountPassword(pwdCtrl.text);
                      if (!ctx.mounted) return;
                      if (ok) {
                        Navigator.pop(ctx);
                        AppRoutes.isAppLockShowing = false;
                        widget.onUnlocked();
                      } else {
                        setDialogState(() {
                          submitting = false;
                          dialogErr = 'Mật khẩu không chính xác.';
                        });
                      }
                    },
              child: const Text('Mở khóa'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.secBackground,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Brand & Lock Icon
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.lock_rounded,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Sổ Tay Y Tế',
                style: AppTypography.heading2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Hồ sơ sức khỏe đang được khóa bảo vệ',
                style: AppTypography.caption.copyWith(
                  fontSize: 13,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),

              // PIN Indicators (6 dots)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final isFilled = index < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: isFilled ? 16 : 14,
                    height: isFilled ? 16 : 14,
                    decoration: BoxDecoration(
                      color: isFilled ? AppColors.primary : AppColors.surfaceMuted,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isFilled ? AppColors.primary : AppColors.secCardBorder,
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],

              const Spacer(),

              // Numeric Keypad
              Opacity(
                opacity: _lockoutRemainingSeconds > 0 ? 0.45 : 1.0,
                child: _buildKeypad(),
              ),

              const SizedBox(height: 8),

              // Fallback Password / Logout Shortcut (prevents permanent lockout)
              TextButton(
                onPressed: _showPasswordUnlockDialog,
                child: Text(
                  _hasPinConfigured
                      ? 'Quên mã PIN? Mở khóa bằng mật khẩu tài khoản'
                      : 'Mở khóa bằng mật khẩu tài khoản / Đăng xuất',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.iceTextSlate,
                  ),
                ),
              ),

              // Emergency ICE Card Shortcut
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.emergencyCard,
                      arguments: true,
                    );
                  },
                  icon: const Icon(Icons.emergency_rounded, color: AppColors.error, size: 20),
                  label: const Text(
                    'Mở Thẻ Cấp Cứu Khẩn Cấp (ICE)',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKeypadButton('1'),
            _buildKeypadButton('2'),
            _buildKeypadButton('3'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKeypadButton('4'),
            _buildKeypadButton('5'),
            _buildKeypadButton('6'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKeypadButton('7'),
            _buildKeypadButton('8'),
            _buildKeypadButton('9'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Face ID Key
            _buildActionButton(
              icon: Icons.face_rounded,
              color: AppColors.primary,
              onTap: _attemptBiometricAuth,
            ),
            _buildKeypadButton('0'),
            // Delete Key
            _buildActionButton(
              icon: Icons.backspace_outlined,
              color: AppColors.textSecondaryLight,
              onTap: _onDelete,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Material(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(36),
        child: InkWell(
          borderRadius: BorderRadius.circular(36),
          onTap: _lockoutRemainingSeconds > 0 ? null : () => _onKeyPress(text),
          child: Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.secCardBorder),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(36),
        child: InkWell(
          borderRadius: BorderRadius.circular(36),
          onTap: onTap,
          child: SizedBox(
            width: 72,
            height: 72,
            child: Icon(icon, color: color, size: 28),
          ),
        ),
      ),
    );
  }
}
