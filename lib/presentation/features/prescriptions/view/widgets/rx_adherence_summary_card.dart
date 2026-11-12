import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';

/// Thẻ tóm tắt kế hoạch uống thuốc trong ngày và tỷ lệ tuân thủ.
class RxAdherenceSummaryCard extends StatelessWidget {
  final String dayTitle;
  final String planSubtitle;
  final int completedCount;
  final int totalCount;
  final int adherencePercent;
  final String nextDoseHighlight;

  const RxAdherenceSummaryCard({
    super.key,
    required this.dayTitle,
    required this.planSubtitle,
    required this.completedCount,
    required this.totalCount,
    required this.adherencePercent,
    required this.nextDoseHighlight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rxBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.rxBadgeCream,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/icons/ic_rx_capsule.svg',
                  width: 13.5,
                  height: 13.5,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.iceTextNavy,
                      ),
                    ),
                    Text(
                      planSubtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.iceTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.rxBadgeCream,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$completedCount/$totalCount Cữ hoàn thành',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textWarmBrown,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceCream,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.rotate(
                        angle: -math.pi / 2,
                        child: SvgPicture.asset(
                          'assets/icons/ic_rx_progress_ring.svg',
                          width: 56,
                          height: 56,
                        ),
                      ),
                      Text(
                        '$adherencePercent%',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.rxOlive,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              'Đúng giờ & chuẩn cữ',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: AppColors.iceTextNavy,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          SvgPicture.asset(
                            'assets/icons/ic_rx_verified_badge.svg',
                            width: 16.5,
                            height: 15.75,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.iceTextSlate,
                          ),
                          children: [
                            const TextSpan(text: 'Tuyệt vời! Còn 1 cữ lúc '),
                            TextSpan(
                              text: nextDoseHighlight,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.rxOlive,
                              ),
                            ),
                            const TextSpan(text: ' và 1 cữ đêm.'),
                          ],
                        ),
                      ),
                    ],
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

