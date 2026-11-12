import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_typography.dart';

class SocialAuthButton extends StatelessWidget {
  final String text;
  final String iconAsset;
  final double iconWidth;
  final double iconHeight;
  final Color backgroundColor;
  final Color textColor;
  final double height;
  final double fontSize;
  final double letterSpacing;
  final VoidCallback onPressed;

  const SocialAuthButton({
    super.key,
    required this.text,
    required this.iconAsset,
    this.iconWidth = 20,
    this.iconHeight = 20,
    required this.backgroundColor,
    required this.textColor,
    this.height = 48,
    this.fontSize = 14,
    this.letterSpacing = 0.14,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                iconAsset,
                width: iconWidth,
                height: iconHeight,
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: AppTypography.labelSemiBold.copyWith(
                  color: textColor,
                  fontSize: fontSize,
                  letterSpacing: letterSpacing,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
