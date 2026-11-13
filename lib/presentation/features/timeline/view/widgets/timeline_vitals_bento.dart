import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';

/// Lưới Bento 2x2 hiển thị các chỉ số sinh hiệu mới nhất.
class TimelineVitalsBento extends StatelessWidget {
  const TimelineVitalsBento({
    super.key,
    this.onViewReports,
  });

  final VoidCallback? onViewReports;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/ic_vitals_pulse.svg',
                    width: 15,
                    height: 13.5,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Sinh hiệu mới nhất',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.iceTextNavy,
                    ),
                  ),
                ],
              ),
              if (onViewReports != null)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onViewReports,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.iceAccentCream,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Xem báo cáo',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.timelineOlive,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right,
                            size: 13,
                            color: AppColors.timelineOlive,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                const Text(
                  'Hôm nay, 08:30',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.44,
                    color: AppColors.iceTextMuted,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _VitalsCard(
                height: 122,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Huyết áp',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.iceTextSlate,
                          ),
                        ),
                        SvgPicture.asset(
                          'assets/icons/ic_blood_pressure.svg',
                          width: 15,
                          height: 13.5,
                        ),
                      ],
                    ),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '118/78',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.7,
                            color: AppColors.iceTextNavy,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'mmHg',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.44,
                            color: AppColors.iceTextMuted,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.timelineOlive,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Expanded(
                          child: Text(
                            'Tối ưu · Bình thường',
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.timelineOlive,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _VitalsCard(
                height: 122,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nhịp tim',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.iceTextSlate,
                          ),
                        ),
                        SvgPicture.asset(
                          'assets/icons/ic_heart_rate.svg',
                          width: 15,
                          height: 13.76,
                        ),
                      ],
                    ),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '74',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.7,
                            color: AppColors.iceTextNavy,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'bpm',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.44,
                            color: AppColors.iceTextMuted,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            'Nhịp xoang đều',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.timelineTextWarm,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        SvgPicture.asset(
                          'assets/icons/ic_ecg_mini_wave.svg',
                          width: 40,
                          height: 12,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _VitalsCard(
                height: 106,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            'SpO2 (Oxy máu)',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.iceTextSlate,
                            ),
                          ),
                        ),
                        SvgPicture.asset(
                          'assets/icons/ic_spo2_lungs.svg',
                          width: 15,
                          height: 12.75,
                        ),
                      ],
                    ),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '99',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.7,
                            color: AppColors.iceTextNavy,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.44,
                            color: AppColors.iceTextMuted,
                          ),
                        ),
                      ],
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: const LinearProgressIndicator(
                        value: 0.99,
                        minHeight: 6,
                        backgroundColor: AppColors.timelineChipBg,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.timelineOlive,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _VitalsCard(
                height: 106,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            'Đường huyết đói',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.iceTextSlate,
                            ),
                          ),
                        ),
                        SvgPicture.asset(
                          'assets/icons/ic_blood_glucose.svg',
                          width: 12,
                          height: 15,
                        ),
                      ],
                    ),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '92',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.7,
                            color: AppColors.iceTextNavy,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'mg/dL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.44,
                            color: AppColors.iceTextMuted,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'FPG Ổn định',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.44,
                        color: AppColors.timelineTextWarm,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VitalsCard extends StatelessWidget {
  final double height;
  final Widget child;

  const _VitalsCard({
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.iceCardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.iceTextNavy.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

