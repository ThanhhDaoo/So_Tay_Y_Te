import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/security/biometric_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
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

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? SecuritySettingsViewModel();
    // Auto-prompt Face ID upon opening if biometrics is enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptBiometricAuth();
    });
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

  void _onKeyPress(String key) async {
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
          widget.onUnlocked();
        } else {
          HapticFeedback.heavyImpact();
          setState(() {
            _pin = '';
            _errorMessage = 'Mã PIN không chính xác. Vui lòng thử lại!';
          });
        }
      }
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
    }
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
              const SizedBox(height: 24),
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
              const SizedBox(height: 16),
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
              const SizedBox(height: 28),

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
              _buildKeypad(),

              const SizedBox(height: 16),

              // Emergency ICE Card Shortcut
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.emergencyCard);
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
              const SizedBox(height: 8),
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
          onTap: () => _onKeyPress(text),
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
