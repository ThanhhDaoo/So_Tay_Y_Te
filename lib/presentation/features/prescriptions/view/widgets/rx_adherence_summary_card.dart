import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../common_widgets/layout/app_layout.dart';

/// Thẻ tóm tắt kế hoạch uống thuốc trong ngày phẳng gọn theo 3-Point Rule
/// (bỏ hộp con nền kem lồng bên trong gây chật chội).
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
    return CleanCard(
      borderColor: AppColors.rxBorder,
      padding: const EdgeInsets.all(AppLayoutTokens.heroCardPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Điểm 1: Vòng tròn tỷ lệ tuân thủ
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: -math.pi / 2,
                  child: SvgPicture.asset(
                    'assets/icons/ic_rx_progress_ring.svg',
                    width: 60,
                    height: 60,
                  ),
                ),
                Text(
                  '$adherencePercent%',
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.rxOlive,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Điểm 2 & 3: Tiêu đề ngày + Số cữ hoàn thành + Cữ tiếp theo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        dayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.iceTextNavy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.rxBadgeCream,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$completedCount/$totalCount cữ',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textWarmBrown,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  planSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.iceTextMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.rxOlive,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        totalCount > 0
                            ? 'Cữ tiếp theo: $nextDoseHighlight'
                            : nextDoseHighlight,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.rxOlive,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
