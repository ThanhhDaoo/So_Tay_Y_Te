import 'package:flutter/material.dart';

/// Hệ màu Y tế Hiện đại cho Sổ Tay Y Tế (tham chiếu phong cách sáng sạch,
/// nền trắng lạnh tinh khiết & xanh y khoa chuẩn mực, loại bỏ hoàn toàn tông nâu/kem đục).
class AppColors {
  // Brand & Primary Palette — Clinical Sapphire Blue & Soft Tints
  static const Color primary = Color(0xFF1E56A0);
  static const Color primaryLight = Color(0xFF3B73C5);
  static const Color primaryDark = Color(0xFF163E75);
  static const Color primaryPeach = Color(0xFFEEF4FF);

  static const Color secondary = Color(0xFFE0ECFF);
  static const Color accent = Color(0xFF2563EB);

  // Backgrounds & Surfaces — Crisp Cool White & Subtle Ice Gray
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color headerOverlay = Color(0xF2FFFFFF);

  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceCream = Color(0xFFF8FAFC);
  static const Color surfaceWarm = Color(0xFFF1F5F9);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color surfaceOliveSoft = Color(0xFFEEF4FF);
  static const Color surfaceDark = Color(0xFF1E293B);

  // Borders & Dividers — Hairline Cool Gray (#EAECF0)
  static const Color divider = Color(0xFFEAECF0);
  static const Color dotMuted = Color(0xFF98A2B3);
  static const Color checkboxBorder = Color(0xFFD0D5DD);

  // Text Colors — High-Contrast Clinical Slate (#101828 / #475467 / #667085)
  static const Color textPrimaryLight = Color(0xFF101828);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryLight = Color(0xFF475467);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF667085);
  static const Color textHint = Color(0xFF98A2B3);
  static const Color textHintAlt = Color(0xFF98A2B3);
  static const Color textWarmBrown = Color(0xFF1E56A0);
  static const Color textWarmBrownMuted = Color(0xFF475467);
  static const Color textDarkButton = Color(0xFFFFFFFF);
  static const Color textOtpButton = Color(0xFF101828);

  // Status Colors
  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF0E9F6E);
  static const Color warning = Color(0xFFD97706);

  // Core Clinical Surfaces & Semantic Tokens (giữ nguyên tên biến để tương thích 100% toàn dự án)
  static const Color iceBackground = Color(0xFFF8FAFC);
  static const Color iceGlassSurface = Color(0xF5FFFFFF);
  static const Color iceBannerStart = Color(0xFF1E56A0);
  static const Color iceBannerEnd = Color(0xFF3E74C2);
  static const Color icePrimaryCall = Color(0xFF1E56A0);
  static const Color iceOlive = Color(0xFF1E56A0);
  static const Color iceOliveDark = Color(0xFF163E75);
  static const Color iceAccentCream = Color(0xFFEEF4FF);
  static const Color iceBorderCream = Color(0xFFD6E4FF);
  static const Color iceSecondaryCard = Color(0xFFEEF4FF);
  static const Color iceCardBorder = Color(0xFFEAECF0);
  static const Color iceMetricBox = Color(0xFFF8FAFC);
  static const Color iceAllergyBg = Color(0xFFFFFBEB);
  static const Color iceAllergyBorder = Color(0xFFFDE68A);
  static const Color iceCriticalBadge = Color(0xFFB45309);
  static const Color iceDangerBg = Color(0xFFFEF2F2);
  static const Color iceDangerText = Color(0xFFDC2626);
  static const Color iceTextNavy = Color(0xFF101828);
  static const Color iceTextSlate = Color(0xFF475467);
  static const Color iceTextBrownDark = Color(0xFF1E56A0);
  static const Color iceTextMuted = Color(0xFF667085);

  // Life Timeline Palette
  static const Color timelineInputBg = Color(0xFFF2F4F7);
  static const Color timelineChipBg = Color(0xFFEEF4FF);
  static const Color timelineCardBg = Color(0xFFFFFFFF);
  static const Color timelineOlive = Color(0xFF1E56A0);
  static const Color timelineDotMuted = Color(0xFF98A2B3);
  static const Color timelineTextWarm = Color(0xFF667085);
  static const Color timelineBadgeBrown = Color(0xFF1E56A0);
  static const Color timelineDividerBlue = Color(0xFFE0ECFF);

  // Prescriptions & Medication Schedule Palette
  static const Color rxBackground = Color(0xFFF8FAFC);
  static const Color rxBorder = Color(0xFFEAECF0);
  static const Color rxOlive = Color(0xFF1E56A0);
  static const Color rxBadgeCream = Color(0xFFEEF4FF);
  static const Color rxProDarkText = Color(0xFF163E75);
  static const Color rxBlueSoft = Color(0xFFEEF4FF);
  static const Color rxProgressTrack = Color(0xFFD6E4FF);
  static const Color rxAdviceCircle = Color(0xFFEEF4FF);

  // Vital Reports & Clinical Export Palette
  static const Color reportBackground = Color(0xFFF8FAFC);
  static const Color reportTeal = Color(0xFF0E9F6E);
  static const Color reportTealSoft = Color(0xFFECFDF3);
  static const Color reportOlive = Color(0xFF1E56A0);
  static const Color reportOliveDark = Color(0xFF163E75);
  static const Color reportCream = Color(0xFFEEF4FF);
  static const Color reportCreamDark = Color(0xFF1E56A0);
  static const Color reportPillBg = Color(0xFFF2F4F7);
  static const Color reportSegmentBg = Color(0xFFF2F4F7);
  static const Color reportHeroBg = Color(0xFFEEF4FF);
  static const Color reportTextDark = Color(0xFF101828);
  static const Color reportTextMuted = Color(0xFF667085);
  static const Color reportTextSlate = Color(0xFF475467);
  static const Color reportZoneGreen = Color(0xFF12B76A);
  static const Color reportZoneYellow = Color(0xFFF59E0B);
  static const Color reportZoneRed = Color(0xFFDC2626);
  static const Color reportBorderLight = Color(0xFFEAECF0);
  static const Color reportDividerGray = Color(0xFFEAECF0);
  static const Color reportAllergyBannerBg = Color(0xFFFEF2F2);
  static const Color reportAllergyTextRed = Color(0xFFB91C1C);
  static const Color reportNoticeBg = Color(0xFFFFFBEB);
  static const Color reportQrBg = Color(0xFFEEF4FF);

  // Security & Biometric Lock Palette
  static const Color secBackground = Color(0xFFF8FAFC);
  static const Color secOlive = Color(0xFF1E56A0);
  static const Color secOliveMuted = Color(0xFF475467);
  static const Color secCardGradientStart = Color(0xFFEEF4FF);
  static const Color secCardGradientEnd = Color(0xFFE0ECFF);
  static const Color secCardBorder = Color(0xFFEAECF0);
  static const Color secItemBg = Color(0xFFFFFFFF);
  static const Color secStatusBg = Color(0xFFEEF4FF);
  static const Color secPillActive = Color(0xFFEEF4FF);
  static const Color secPillActiveText = Color(0xFF1E56A0);
  static const Color secToggleActive = Color(0xFF1E56A0);
  static const Color secRadioSelectedBg = Color(0xFFEEF4FF);
  static const Color secSqlCipherPillBg = Color(0xFFECFDF3);
  static const Color secDangerBg = Color(0xFFFEF2F2);
  static const Color secDangerIconBg = Color(0xFFFEE2E2);
  static const Color secDangerText = Color(0xFFDC2626);
}
