import 'package:flutter/material.dart';

/// Chuẩn khoảng cách cân đối cho màn hình di động (375pt - 430pt), tránh bó hẹp nội dung 2 cột.
class AppLayoutTokens {
  AppLayoutTokens._();

  /// Lề ngang chuẩn di động (16px) giúp thẻ rộng rãi, không bị xuống hàng sớm.
  static const double screenPadding = 16.0;

  /// Khoảng cách giữa các cụm chức năng / Section (22px).
  static const double sectionGap = 22.0;

  /// Khoảng cách giữa tiêu đề SectionHeader và nội dung bên dưới (12px).
  static const double sectionHeaderGap = 12.0;

  /// Padding tiêu chuẩn bên trong mỗi Card (16px).
  static const double cardPadding = 16.0;

  /// Padding cho thẻ định danh / Hero Card (16px).
  static const double heroCardPadding = 16.0;

  /// Khoảng cách giữa các Card trong danh sách hoặc lưới 2 cột (12px).
  static const double cardGap = 12.0;

  /// Khoảng cách giữa các dòng bên trong 1 Card (10px).
  static const double itemGap = 10.0;

  /// Chiều cao nút chuẩn dễ bấm (>= 52px).
  static const double minButtonHeight = 52.0;

  /// Kích thước icon trực quan (24px).
  static const double seniorIconSize = 24.0;

  /// Khoảng cách chuẩn giữa các ô nhập liệu trong Form (14px).
  static const double formFieldGap = 14.0;

  /// Độ bo góc chuẩn cho Card chính (14px).
  static const double cardRadius = 14.0;

  /// Độ bo góc cho thành phần phụ / chip / ô con (10px).
  static const double innerRadius = 10.0;

  static const EdgeInsets horizontalScreenPadding = EdgeInsets.symmetric(
    horizontal: screenPadding,
  );
}
