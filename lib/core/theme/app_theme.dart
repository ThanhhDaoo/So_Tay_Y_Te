import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.iceOlive,
        brightness: Brightness.light,
        primary: AppColors.iceOlive,
        surface: AppColors.iceBackground,
      ),
      scaffoldBackgroundColor: AppColors.iceBackground,
      // Sử dụng trực tiếp font gốc của HĐH (SF Pro trên iOS / Roboto trên Android)
      // để hiển thị dấu tiếng Việt thanh thoát, sắc nét tuyệt đối chuẩn Apple Health.
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.iceBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.iceOlive,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
    );
  }
}
