import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  static const String fontFamily = 'Roboto';
  static const List<String> fontFallback = [
    '.SF UI Text',
    'SF Pro Text',
    'Helvetica Neue',
    'sans-serif',
  ];

  static const TextStyle vitalDisplay = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFallback,
    fontSize: 29,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.4,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle heading1 = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFallback,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 36 / 28,
    letterSpacing: -0.5,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle headerTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFallback,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 28 / 20,
    letterSpacing: -0.3,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle ctaLarge = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFallback,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 26 / 18,
    color: AppColors.primaryPeach,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFallback,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFallback,
    fontSize: 18.5,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFallback,
    fontSize: 17,
    fontWeight: FontWeight.w500,
    height: 25 / 17,
    color: AppColors.textSecondaryLight,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFallback,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 23 / 16,
    color: AppColors.textSecondaryLight,
  );

  static const TextStyle labelSemiBold = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFallback,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 21 / 15,
    letterSpacing: 0.1,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle labelSmallSemiBold = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFallback,
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    height: 18 / 13.5,
    letterSpacing: 0.25,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFallback,
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    height: 19 / 13.5,
    color: AppColors.textSecondaryLight,
  );

  static const TextStyle badge = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFallback,
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    height: 16 / 12.5,
    letterSpacing: 0.3,
    color: AppColors.textWarmBrown,
  );
}
