import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';

/// Banner thông báo chế độ cấp cứu khẩn cấp ICE ở đầu nội dung.
class IceEmergencyBanner extends StatelessWidget {
  const IceEmergencyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.iceBannerStart, AppColors.iceBannerEnd],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.iceAccentCream.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.iceBannerStart.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: AppColors.iceAccentCream,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'CHẾ ĐỘ CẤP CỨU',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.55,
                        color: AppColors.iceAccentCream,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'THẺ Y TẾ KHẨN CẤP (ICE)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.45,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.iceAccentCream.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.iceAccentCream.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/icons/ic_ice_bolt.svg',
                  width: 10.67,
                  height: 13.33,
                ),
                const SizedBox(width: 5),
                const Text(
                  'TRUY CẬP NHANH',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.iceAccentCream,
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
