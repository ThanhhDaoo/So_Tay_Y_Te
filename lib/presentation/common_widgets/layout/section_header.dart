import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';

/// Tiêu đề gom nhóm thông tin (Section Header) gọn sắc, cân đối.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? iconAsset;
  final double iconSize;
  final Color? iconColor;
  final Color titleColor;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconAsset,
    this.iconSize = 18.0,
    this.iconColor,
    this.titleColor = AppColors.iceTextNavy,
    this.trailing,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    Widget? leadingIcon;
    if (iconAsset != null) {
      leadingIcon = SvgPicture.asset(
        iconAsset!,
        width: iconSize,
        height: iconSize,
        colorFilter: ColorFilter.mode(
          iconColor ?? AppColors.primary,
          BlendMode.srcIn,
        ),
      );
    } else if (icon != null) {
      leadingIcon = Icon(
        icon,
        size: iconSize + 1,
        color: iconColor ?? AppColors.primary,
      );
    }

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (leadingIcon != null) ...[
                      leadingIcon,
                      const SizedBox(width: 7),
                    ],
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: titleColor,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.iceTextMuted,
                      height: 1.32,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
