import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class AuthTextField extends StatelessWidget {
  final String label;
  final bool isRequired;
  final String? trailingLabel;
  final Color? trailingLabelColor;
  final String hintText;
  final String prefixIconAsset;
  final double prefixIconWidth;
  final double prefixIconHeight;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final String? suffixIconAsset;
  final double suffixIconWidth;
  final double suffixIconHeight;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final Color hintColor;

  const AuthTextField({
    super.key,
    required this.label,
    this.isRequired = false,
    this.trailingLabel,
    this.trailingLabelColor,
    required this.hintText,
    required this.prefixIconAsset,
    this.prefixIconWidth = 16.67,
    this.prefixIconHeight = 16.67,
    required this.controller,
    this.obscureText = false,
    this.onToggleObscure,
    this.suffixIconAsset,
    this.suffixIconWidth = 18.33,
    this.suffixIconHeight = 12.5,
    this.onChanged,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.hintColor = AppColors.textHint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: AppTypography.labelSemiBold),
                if (isRequired) ...[
                  const SizedBox(width: 6),
                  Text(
                    '*',
                    style: AppTypography.labelSemiBold.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
            if (trailingLabel != null)
              Text(
                trailingLabel!,
                style: AppTypography.badge.copyWith(
                  color: trailingLabelColor ?? AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            onChanged: onChanged,
            validator: validator,
            keyboardType: keyboardType,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTypography.bodyLarge.copyWith(color: hintColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 13,
                horizontal: 16,
              ),
              prefixIcon: SizedBox(
                width: 44,
                child: Center(
                  child: SvgPicture.asset(
                    prefixIconAsset,
                    width: prefixIconWidth,
                    height: prefixIconHeight,
                  ),
                ),
              ),
              suffixIcon: onToggleObscure != null && suffixIconAsset != null
                  ? IconButton(
                      onPressed: onToggleObscure,
                      icon: SvgPicture.asset(
                        suffixIconAsset!,
                        width: suffixIconWidth,
                        height: suffixIconHeight,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
