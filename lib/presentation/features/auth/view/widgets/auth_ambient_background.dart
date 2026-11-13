import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class AuthAmbientBackground extends StatefulWidget {
  const AuthAmbientBackground({super.key});

  @override
  State<AuthAmbientBackground> createState() => _AuthAmbientBackgroundState();
}

class _AuthAmbientBackgroundState extends State<AuthAmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final val = _controller.value;
        final float1 = math.sin(val * math.pi) * 15;
        final float2 = math.cos(val * math.pi) * 12;

        return Stack(
          children: [
            // Ambient soft olive glow top right
            Positioned(
              top: -60 + float1,
              right: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.iceOlive.withValues(alpha: 0.12),
                      AppColors.iceOlive.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Ambient warm gold glow middle left
            Positioned(
              top: 240 + float2,
              left: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFE8D2B5).withValues(alpha: 0.25),
                      const Color(0xFFE8D2B5).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Subtle cyan tint at bottom right
            Positioned(
              bottom: 80 - float1,
              right: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00685F).withValues(alpha: 0.08),
                      const Color(0xFF00685F).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
