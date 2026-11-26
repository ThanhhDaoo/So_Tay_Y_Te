import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'app_layout_tokens.dart';
import 'section_header.dart';

/// Khung bao bọc một cụm chức năng (Section), tự động chuẩn hóa khoảng cách
/// giữa tiêu đề nhóm và phần thân, cũng như khoảng thở với Section kế tiếp.
class SectionContainer extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final String? iconAsset;
  final Color? iconColor;
  final Color titleColor;
  final Widget? trailing;
  final Widget child;
  final double headerGap;
  final double bottomSpacing;
  final EdgeInsetsGeometry padding;

  const SectionContainer({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    this.iconAsset,
    this.iconColor,
    this.titleColor = AppColors.iceTextNavy,
    this.trailing,
    required this.child,
    this.headerGap = AppLayoutTokens.sectionHeaderGap,
    this.bottomSpacing = AppLayoutTokens.sectionGap,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding.add(EdgeInsets.only(bottom: bottomSpacing)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null && title!.isNotEmpty) ...[
            SectionHeader(
              title: title!,
              subtitle: subtitle,
              icon: icon,
              iconAsset: iconAsset,
              iconColor: iconColor,
              titleColor: titleColor,
              trailing: trailing,
            ),
            SizedBox(height: headerGap),
          ],
          child,
        ],
      ),
    );
  }
}
