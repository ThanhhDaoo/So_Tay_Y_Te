import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Hệ thống Typography chuẩn Apple Health / MedVault:
/// Dùng font hệ thống gốc (SF Pro trên iOS, Roboto trên Android) để dấu tiếng Việt
/// thanh thoát, tỷ lệ khoảng cách chữ (letterSpacing) và chiều cao dòng cân đối chuyên nghiệp.
class AppTypography {
  static const List<FontFeature> tabularNums = [FontFeature.tabularFigures()];

  static const TextStyle vitalDisplay = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1.12,
    letterSpacing: -0.8,
    fontFeatures: tabularNums,
    color: AppColors.iceTextNavy,
  );

  static const TextStyle heading1 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.5,
    color: AppColors.iceTextNavy,
  );

  static const TextStyle headerTitle = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.3,
    color: AppColors.iceTextNavy,
  );

  static const TextStyle ctaLarge = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.1,
    color: AppColors.primaryPeach,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.3,
    color: AppColors.iceTextNavy,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 17.5,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.2,
    color: AppColors.iceTextNavy,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16.5,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.iceTextSlate,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.iceTextSlate,
  );

  static const TextStyle labelSemiBold = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: -0.05,
    color: AppColors.iceTextNavy,
  );

  static const TextStyle labelSmallSemiBold = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.2,
    color: AppColors.iceTextNavy,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.iceTextMuted,
  );

  static const TextStyle badge = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: 0.5,
    color: AppColors.textWarmBrown,
  );
}
