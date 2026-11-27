import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Hệ thống Typography chuẩn Y tế số hiện đại (SF Pro trên iOS / Roboto trên Android):
/// Sắc nét, thanh thoát, phân cấp rõ giữa tiêu đề đậm vừa (w600-w700) và nhãn xám dịu (#667085).
class AppTypography {
  static const List<FontFeature> tabularNums = [FontFeature.tabularFigures()];

  static const TextStyle vitalDisplay = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.6,
    fontFeatures: tabularNums,
    color: AppColors.iceTextNavy,
  );

  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.4,
    color: AppColors.iceTextNavy,
  );

  static const TextStyle headerTitle = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.25,
    color: AppColors.iceTextNavy,
  );

  static const TextStyle ctaLarge = TextStyle(
    fontSize: 16.5,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.1,
    color: Colors.white,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 18.5,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.25,
    color: AppColors.iceTextNavy,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.15,
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
    color: AppColors.iceTextNavy,
  );

  static const TextStyle labelSmallSemiBold = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.iceTextNavy,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.iceTextMuted,
  );

  static const TextStyle badge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.primary,
  );
}
