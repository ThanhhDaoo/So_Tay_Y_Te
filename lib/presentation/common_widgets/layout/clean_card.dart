import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'app_layout_tokens.dart';

/// Thẻ giao diện chuẩn y tế thoáng đãng: padding tối thiểu 16px, viền mảnh tinh tế,
/// hỗ trợ chạm toàn thẻ mà không cần lồng nhiều hộp con gây rối mắt.
class CleanCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color backgroundColor;
  final Color? borderColor;
  final bool showBorder;
  final double borderRadius;
  final VoidCallback? onTap;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;

  const CleanCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppLayoutTokens.cardPadding),
    this.margin,
    this.backgroundColor = AppColors.surfaceLight,
    this.borderColor,
    this.showBorder = true,
    this.borderRadius = AppLayoutTokens.cardRadius,
    this.onTap,
    this.boxShadow,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final effectiveShadows = boxShadow ??
        [
          BoxShadow(
            color: AppColors.iceTextNavy.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ];

    final decoration = BoxDecoration(
      color: gradient == null ? backgroundColor : null,
      gradient: gradient,
      borderRadius: radius,
      border: showBorder
          ? Border.all(
              color: borderColor ?? AppColors.iceCardBorder,
              width: 1,
            )
          : null,
      boxShadow: effectiveShadows,
    );

    Widget content = Padding(
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: content,
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: margin,
      decoration: decoration,
      child: content,
    );
  }
}
