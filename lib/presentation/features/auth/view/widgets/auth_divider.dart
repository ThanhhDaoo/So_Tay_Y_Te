import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class AuthDivider extends StatelessWidget {
  final String text;
  final bool uppercase;
  final Color textColor;

  const AuthDivider({
    super.key,
    required this.text,
    this.uppercase = false,
    this.textColor = AppColors.textSecondaryLight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: AppColors.divider,
            thickness: 1,
            height: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            uppercase ? text.toUpperCase() : text,
            style: AppTypography.badge.copyWith(
              color: textColor,
              letterSpacing: uppercase ? 0.55 : 0.275,
            ),
          ),
        ),
        const Expanded(
          child: Divider(
            color: AppColors.divider,
            thickness: 1,
            height: 1,
          ),
        ),
      ],
    );
  }
}
