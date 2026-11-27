import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Hệ thống Typography cân đối chuẩn ứng dụng Y tế thương mại (OneCare / Apple Health):
/// Rõ nét, vừa vặn trên màn hình điện thoại, không quá khổ gây rớt dòng hay tràn viền.
class AppTypography {
  static const List<FontFeature> tabularNums = [FontFeature.tabularFigures()];

  static const TextStyle vitalDisplay = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.4,
    fontFeatures: tabularNums,
    color: AppColors.iceTextNavy,
  );

  static const TextStyle heading1 = TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.3,
    color: AppColors.iceTextNavy,
  );

  static const TextStyle headerTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.2,
    color: AppColors.iceTextNavy,
  );

  static const TextStyle ctaLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: Colors.white,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 16.5,
    fontWeight: FontWeight.w700,
    height: 1.28,
    letterSpacing: -0.2,
    color: AppColors.iceTextNavy,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w600,
    height: 1.28,
    letterSpacing: -0.1,
    color: AppColors.iceTextNavy,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.iceTextSlate,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.42,
    color: AppColors.iceTextSlate,
  );

  static const TextStyle labelSemiBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.32,
    color: AppColors.iceTextNavy,
  );

  static const TextStyle labelSmallSemiBold = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    height: 1.28,
    color: AppColors.iceTextNavy,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    height: 1.38,
    color: AppColors.iceTextMuted,
  );

  static const TextStyle badge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.primary,
  );
}
