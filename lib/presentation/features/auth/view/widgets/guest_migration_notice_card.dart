import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class GuestMigrationNoticeCard extends StatelessWidget {
  const GuestMigrationNoticeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x66F3DCBF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: AppColors.primaryPeach,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/ic_laptop_check.svg',
                width: 15,
                height: 12.27,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tự động đồng bộ dữ liệu Chế độ Khách',
                  style: AppTypography.labelSmallSemiBold.copyWith(
                    color: AppColors.textWarmBrown,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hồ sơ lưu ngoại tuyến trên máy sẽ được gộp an toàn vào tài khoản mới.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
