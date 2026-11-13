import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class DocumentViewerTipBadge extends StatelessWidget {
  const DocumentViewerTipBadge({
    super.key,
    required this.onDismiss,
  });

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE9FF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/ic_doc_zoom_info.svg',
            width: 17,
            height: 17,
            colorFilter: const ColorFilter.mode(
              Color(0xFF00685F),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTypography.body.copyWith(
                  fontSize: 12,
                  color: AppColors.iceTextNavy,
                  height: 1.35,
                ),
                children: const [
                  TextSpan(text: 'Trình xem hỗ trợ '),
                  TextSpan(
                    text: 'Pinch-to-zoom vô cực',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF00685F),
                    ),
                  ),
                  TextSpan(text: ' & '),
                  TextSpan(
                    text: 'PDF đa trang',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF00685F),
                    ),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: onDismiss,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: SvgPicture.asset(
                'assets/icons/ic_doc_close.svg',
                width: 14,
                height: 14,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF3D4947),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

