import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Dòng hiển thị cặp Nhãn – Giá trị cân đối 2 cột, chống tràn viền & ép chữ xuống nhiều dòng.
class KeyValueRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;
  final IconData? leadingIcon;
  final Color labelColor;
  final Color valueColor;
  final FontWeight valueWeight;
  final EdgeInsetsGeometry padding;
  final int maxLines;

  const KeyValueRow({
    super.key,
    required this.label,
    this.value,
    this.valueWidget,
    this.leadingIcon,
    this.labelColor = AppColors.iceTextMuted,
    this.valueColor = AppColors.iceTextNavy,
    this.valueWeight = FontWeight.w600,
    this.padding = const EdgeInsets.symmetric(vertical: 5),
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leadingIcon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                leadingIcon,
                size: 14,
                color: labelColor,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            flex: 5,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: labelColor,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Align(
              alignment: Alignment.centerRight,
              child: valueWidget ??
                  Text(
                    value ?? '--',
                    textAlign: TextAlign.right,
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: valueWeight,
                      color: valueColor,
                      height: 1.35,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
