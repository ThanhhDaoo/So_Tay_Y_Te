import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../common_widgets/layout/app_layout.dart';

class GuestModeCard extends StatelessWidget {
  final VoidCallback onContinueAsGuest;

  const GuestModeCard({
    super.key,
    required this.onContinueAsGuest,
  });

  @override
  Widget build(BuildContext context) {
    return CleanCard(
      onTap: onContinueAsGuest,
      backgroundColor: AppColors.surfaceCream,
      borderColor: AppColors.divider,
      boxShadow: const [],
      padding: const EdgeInsets.all(AppLayoutTokens.cardPadding),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0x80F6DFC2),
              borderRadius: BorderRadius.circular(AppLayoutTokens.innerRadius),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/ic_offline_bolt.svg',
                width: 16,
                height: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dùng Chế độ Khách (Offline)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSemiBold.copyWith(
                    color: AppColors.textWarmBrown,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Lưu cục bộ trên máy, không cần kết nối mạng.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.textWarmBrown,
          ),
        ],
      ),
    );
  }
}
