import 'package:flutter/material.dart';

class AppColors {
  // Brand & Primary Palette (Figma Tokens)
  static const Color primary = Color(0xFF595E51);
  static const Color primaryLight = Color(0xFF717669);
  static const Color primaryDark = Color(0xFF30312E);
  static const Color primaryPeach = Color(0xFFF6DFC2);

  static const Color secondary = Color(0xFFF3DCBF);
  static const Color accent = Color(0xFF6C5C45);

  // Backgrounds & Surfaces
  static const Color backgroundLight = Color(0xFFFBF9F4);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color headerOverlay = Color(0xCCFBF9F4);

  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceCream = Color(0xFFF5F3EE);
  static const Color surfaceWarm = Color(0xFFF0EEE9);
  static const Color surfaceMuted = Color(0xFFEAE8E3);
  static const Color surfaceOliveSoft = Color(0xFFE0E4D4);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Borders & Dividers
  static const Color divider = Color(0xFFE4E2DD);
  static const Color dotMuted = Color(0xFFC6C7BE);
  static const Color checkboxBorder = Color(0xFF767676);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF1B1C19);
  static const Color textPrimaryDark = Color(0xFFEEEEEE);
  static const Color textSecondaryLight = Color(0xFF454841);
  static const Color textSecondaryDark = Color(0xFF9E9E9E);
  static const Color textMuted = Color(0xFF5B5D53);
  static const Color textHint = Color(0xFF767870);
  static const Color textHintAlt = Color(0xFF9CA3AF);
  static const Color textWarmBrown = Color(0xFF6C5C45);
  static const Color textWarmBrownMuted = Color(0xFF706049);
  static const Color textDarkButton = Color(0xFFF2F1EC);
  static const Color textOtpButton = Color(0xFF251A08);

  // Status Colors
  static const Color error = Color(0xFFBA1A1A);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFFFA000);

  // Emergency Card (ICE) Palette (Figma node 1:4)
  static const Color iceBackground = Color(0xFFFAF8F5);
  static const Color iceGlassSurface = Color(0xCCF8F9FF);
  static const Color iceBannerStart = Color(0xFF4A5043);
  static const Color iceBannerEnd = Color(0xFF3B4135);
  static const Color icePrimaryCall = Color(0xFF3D4336);
  static const Color iceOlive = Color(0xFF545B4D);
  static const Color iceOliveDark = Color(0xFF2F332A);
  static const Color iceAccentCream = Color(0xFFE8D2B5);
  static const Color iceBorderCream = Color(0xFFD8C2A3);
  static const Color iceSecondaryCard = Color(0xFFF1ECE3);
  static const Color iceCardBorder = Color(0xFFE5DFD4);
  static const Color iceMetricBox = Color(0xFFF7F4EE);
  static const Color iceAllergyBg = Color(0xFFF7EFE4);
  static const Color iceAllergyBorder = Color(0xFFE0CEB7);
  static const Color iceCriticalBadge = Color(0xFF8C4736);
  static const Color iceDangerBg = Color(0xFFFFDAD6);
  static const Color iceDangerText = Color(0xFFBB0112);
  static const Color iceTextNavy = Color(0xFF0B1C30);
  static const Color iceTextSlate = Color(0xFF3D4947);
  static const Color iceTextBrownDark = Color(0xFF433624);
  static const Color iceTextMuted = Color(0xFF6D7A77);

  // Life Timeline Palette (Figma node 1:522)
  static const Color timelineInputBg = Color(0xFFF4F1EA);
  static const Color timelineChipBg = Color(0xFFEDE8DF);
  static const Color timelineCardBg = Color(0xFFF9F7F2);
  static const Color timelineOlive = Color(0xFF5B6153);
  static const Color timelineDotMuted = Color(0xFFA5A79B);
  static const Color timelineTextWarm = Color(0xFF6E6857);
  static const Color timelineBadgeBrown = Color(0xFF4A3F2C);
  static const Color timelineDividerBlue = Color(0xFFE5EEFF);

  // Prescriptions & Medication Schedule Palette (Figma node 1:254)
  static const Color rxBackground = Color(0xFFF9F7F2);
  static const Color rxBorder = Color(0xFFDFD7C8);
  static const Color rxOlive = Color(0xFF5C6254);
  static const Color rxBadgeCream = Color(0xFFF2E9DE);
  static const Color rxProDarkText = Color(0xFF410002);
  static const Color rxBlueSoft = Color(0xFFDCE9FF);
  static const Color rxProgressTrack = Color(0xFFD3E4FE);
  static const Color rxAdviceCircle = Color(0xFFE3E5DC);

  // Vital Reports & Clinical Export Palette (Figma node 1:1666)
  static const Color reportBackground = Color(0xFFF8F9FF);
  static const Color reportTeal = Color(0xFF00685F);
  static const Color reportTealSoft = Color(0x1A00685F);
  static const Color reportOlive = Color(0xFF545B4D);
  static const Color reportOliveDark = Color(0xFF515849);
  static const Color reportCream = Color(0xFFE8D2B5);
  static const Color reportCreamDark = Color(0xFF53442F);
  static const Color reportPillBg = Color(0xFFEFE7DA);
  static const Color reportSegmentBg = Color(0xFFF5F3EE);
  static const Color reportHeroBg = Color(0xB3EFF4FF);
  static const Color reportTextDark = Color(0xFF0B1C30);
  static const Color reportTextMuted = Color(0xFF6D7A77);
  static const Color reportTextSlate = Color(0xFF3D4947);
  static const Color reportZoneGreen = Color(0xCC10B981);
  static const Color reportZoneYellow = Color(0xFFFBBF24);
  static const Color reportZoneRed = Color(0xFFBB0112);
  static const Color reportBorderLight = Color(0xFFECE7DF);
  static const Color reportDividerGray = Color(0xFFBCC9C6);
  static const Color reportAllergyBannerBg = Color(0xFFFFDAD6);
  static const Color reportAllergyTextRed = Color(0xFF93000A);
  static const Color reportNoticeBg = Color(0xFFF7EFE4);
  static const Color reportQrBg = Color(0xFFDCE9FF);

  // Security & Biometric Lock Palette (Figma node 1:1997)
  static const Color secBackground = Color(0xFFFBF9F4);
  static const Color secOlive = Color(0xFF52594B);
  static const Color secOliveMuted = Color(0xFF3D4947);
  static const Color secCardGradientStart = Color(0xFFF5EDE2);
  static const Color secCardGradientEnd = Color(0xFFEBE5DA);
  static const Color secCardBorder = Color(0xFFECE7DF);
  static const Color secItemBg = Color(0xFFF7F5EF);
  static const Color secStatusBg = Color(0xFFF5ECE0);
  static const Color secPillActive = Color(0xFFE8D2B5);
  static const Color secPillActiveText = Color(0xFF433624);
  static const Color secToggleActive = Color(0xFF00685F);
  static const Color secRadioSelectedBg = Color(0xFFF0EDE5);
  static const Color secSqlCipherPillBg = Color(0x6699EFE5);
  static const Color secDangerBg = Color(0x4DFFDAD6);
  static const Color secDangerIconBg = Color(0xFFFFDAD6);
  static const Color secDangerText = Color(0xFFBB0112);
}
