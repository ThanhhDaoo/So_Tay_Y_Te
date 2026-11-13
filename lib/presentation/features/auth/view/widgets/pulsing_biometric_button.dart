import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';

class PulsingBiometricButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isLoading;

  const PulsingBiometricButton({
    super.key,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  State<PulsingBiometricButton> createState() => _PulsingBiometricButtonState();
}

class _PulsingBiometricButtonState extends State<PulsingBiometricButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.45, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (!widget.isLoading) widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        child: SizedBox(
          width: 56,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing aura ring
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 48,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.iceOlive.withValues(alpha: _fadeAnimation.value),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  );
                },
              ),
              // Main button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.iceOlive.withValues(alpha: 0.25),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/ic_fingerprint.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      AppColors.iceOliveDark,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

