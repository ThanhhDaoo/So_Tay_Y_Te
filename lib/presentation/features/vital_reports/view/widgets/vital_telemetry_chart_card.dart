import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../viewmodel/vital_reports_state.dart';
import 'vital_chart_painter.dart';

class VitalTelemetryChartCard extends StatelessWidget {
  final VitalReportsState state;
  final ValueChanged<VitalTimeframe> onSelectTimeframe;

  const VitalTelemetryChartCard({
    super.key,
    required this.state,
    required this.onSelectTimeframe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Chart Header & Timeline selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHỈ SỐ XU HƯỚNG',
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.55,
                        color: AppColors.reportTextMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Huyết Áp Động Mạch',
                            style: AppTypography.heading3.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.reportTextDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${state.latestUnit})',
                          style: AppTypography.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.reportTextSlate,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.reportPillBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTimeframeBtn(
                      label: 'Tuần',
                      isSelected: state.selectedTimeframe == VitalTimeframe.week,
                      onTap: () => onSelectTimeframe(VitalTimeframe.week),
                    ),
                    _buildTimeframeBtn(
                      label: 'Tháng',
                      isSelected: state.selectedTimeframe == VitalTimeframe.month,
                      onTap: () => onSelectTimeframe(VitalTimeframe.month),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Latest Measure Hero Display
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Latest measure
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/ic_report_measure_clock.svg',
                            width: 16,
                            height: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Lần đo gần nhất (${state.latestTimestamp})',
                              style: AppTypography.caption.copyWith(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.reportTextSlate,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              state.latestValue,
                              style: AppTypography.heading1.copyWith(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.7,
                                color: AppColors.reportTextDark,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              state.latestUnit,
                              style: AppTypography.caption.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.reportTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.reportCream,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.reportTeal,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(
                              state.latestClassification,
                              style: AppTypography.caption.copyWith(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.reportCreamDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: AppColors.reportDividerGray.withValues(alpha: 0.3),
                ),
                // Right Column: Monitoring Frequency
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tần suất theo dõi',
                        style: AppTypography.caption.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.reportTextSlate,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/ic_report_frequency_cal.svg',
                            width: 16,
                            height: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              state.monitoringFrequency,
                              style: AppTypography.body.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.reportTextDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.monitoringSchedule,
                        style: AppTypography.caption.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.reportTextMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 2,
                        children: [
                          Text(
                            'Độ tuân thủ: ',
                            style: AppTypography.caption.copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.reportTextSlate,
                            ),
                          ),
                          Text(
                            state.compliancePercent,
                            style: AppTypography.caption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.reportTeal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Zone Legend Indicator
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _buildLegendItem(
                color: const Color(0xCC10B981),
                label: 'Tối ưu (<120/80)',
              ),
              _buildLegendItem(
                color: const Color(0xFFFBBF24),
                label: 'Tiền THA (120-139)',
              ),
              _buildLegendItem(
                color: const Color(0xFFBB0112),
                label: 'Tăng HA (≥140/90)',
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 4. SVG Chart Visual Container
          Container(
            height: 216,
            width: double.infinity,
            padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.reportBorderLight),
            ),
            child: Column(
              children: [
                Expanded(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: VitalChartPainter(points: state.chartPoints),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 78, top: 4),
                  child: Row(
                    children: state.chartPoints.map((point) {
                      return Expanded(
                        child: Center(
                          child: Text(
                            point.dayLabel,
                            style: AppTypography.caption.copyWith(
                              fontSize: 9.5,
                              fontWeight: point.isLatest ? FontWeight.w700 : FontWeight.w500,
                              color: point.isLatest ? AppColors.reportTeal : AppColors.reportTextMuted,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 5. Telemetry Summary Badges
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.reportSegmentBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.reportTeal.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          'assets/icons/ic_report_summary_bp.svg',
                          width: 18,
                          height: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HA TRUNG BÌNH THÁNG',
                              style: AppTypography.caption.copyWith(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.reportTextMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4,
                              children: [
                                Text(
                                  state.monthlyAverageBp,
                                  style: AppTypography.body.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.reportTextDark,
                                  ),
                                ),
                                Text(
                                  'mmHg',
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.reportTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.reportSegmentBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.reportZoneRed.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          'assets/icons/ic_report_summary_heart.svg',
                          width: 18,
                          height: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NHỊP TIM TRUNG BÌNH',
                              style: AppTypography.caption.copyWith(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.reportTextMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4,
                              children: [
                                Text(
                                  state.monthlyAverageHeart,
                                  style: AppTypography.body.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.reportTextDark,
                                  ),
                                ),
                                Text(
                                  'bpm',
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.reportTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeBtn({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.reportOliveDark : AppColors.reportTextSlate,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.reportTextSlate,
            ),
          ),
        ),
      ],
    );
  }
}
