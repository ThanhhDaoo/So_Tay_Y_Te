import 'package:flutter/material.dart';

/// Chuẩn khoảng cách (8pt Grid) và kích thước khung dùng chung toàn ứng dụng Sổ Tay Y Tế.
class AppLayoutTokens {
  AppLayoutTokens._();

  /// Lề ngang cố định và đồng nhất hai bên màn hình (20px).
  static const double screenPadding = 20.0;

  /// Khoảng cách tối thiểu giữa các cụm chức năng / Section (24px).
  static const double sectionGap = 24.0;

  /// Khoảng cách giữa tiêu đề SectionHeader và nội dung bên dưới (12px).
  static const double sectionHeaderGap = 12.0;

  /// Padding tiêu chuẩn bên trong mỗi Card / Container (16px).
  static const double cardPadding = 16.0;

  /// Padding rộng cho thẻ định danh / Hero Card (20px).
  static const double heroCardPadding = 20.0;

  /// Khoảng cách giữa các Card trong cùng một danh sách hoặc lưới Bento (12px).
  static const double cardGap = 12.0;

  /// Khoảng cách giữa các dòng chữ / thành phần bên trong 1 Card (10px).
  static const double itemGap = 10.0;

  /// Khoảng cách chuẩn giữa các ô nhập liệu trong Form (16px).
  static const double formFieldGap = 16.0;

  /// Độ bo góc chuẩn cho Card chính (16px).
  static const double cardRadius = 16.0;

  /// Độ bo góc cho thành phần phụ / chip / ô con (10px).
  static const double innerRadius = 10.0;

  static const EdgeInsets horizontalScreenPadding = EdgeInsets.symmetric(
    horizontal: screenPadding,
  );
}
