import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../common_widgets/layout/app_layout.dart';
import '../../viewmodel/vital_reports_state.dart';
import 'vital_chart_painter.dart';

/// Thẻ biểu đồ xu hướng sinh hiệu thoáng đãng:
/// Tập trung vào Chỉ số mới nhất + Phân loại WHO + Biểu đồ xu hướng,
/// đưa các thông số lịch đo/trung bình tháng xuống dải tóm tắt gọn hoặc BottomSheet chi tiết.
class VitalTelemetryChartCard extends StatelessWidget {
  final VitalReportsState state;
  final ValueChanged<VitalTimeframe> onSelectTimeframe;

  const VitalTelemetryChartCard({
    super.key,
    required this.state,
    required this.onSelectTimeframe,
  });

  String get _metricDisplayTitle => switch (state.selectedMetric) {
        VitalMetricType.bloodPressure => 'Huyết Áp Động Mạch',
        VitalMetricType.bloodGlucose => 'Đường Huyết Lúc Đói',
        VitalMetricType.heartRate => 'Nhịp Tim Nghỉ Ngơi',
        VitalMetricType.bmiAndWeight => 'Chỉ Số BMI & Cân Nặng',
      };

  @override
  Widget build(BuildContext context) {
    return CleanCard(
      borderColor: AppColors.reportBorderLight,
      padding: const EdgeInsets.all(AppLayoutTokens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Tiêu đề chỉ số & Bộ chọn Tuần / Tháng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHỈ SỐ XU HƯỚNG',
                      style: AppTypography.caption.copyWith(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.reportTextMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _metricDisplayTitle,
                            style: AppTypography.heading3.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
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
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.reportTextSlate,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.reportPillBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTimeframeBtn(
                      label: 'Tuần',
                      isSelected:
                          state.selectedTimeframe == VitalTimeframe.week,
                      onTap: () => onSelectTimeframe(VitalTimeframe.week),
                    ),
                    _buildTimeframeBtn(
                      label: 'Tháng',
                      isSelected:
                          state.selectedTimeframe == VitalTimeframe.month,
                      onTap: () => onSelectTimeframe(VitalTimeframe.month),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Điểm neo thị giác chính: Giá trị gần nhất + Phân loại + Độ tuân thủ
          InkWell(
            onTap: () => _showTelemetryMetricsSheet(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FF).withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đo gần nhất • ${state.latestTimestamp}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.reportTextSlate,
                          ),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                state.latestValue,
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.7,
                                  color: AppColors.reportTextDark,
                                  height: 1.05,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                state.latestUnit,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.reportTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.reportCream,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.reportTeal,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              state.latestClassification,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.reportCreamDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Tuân thủ đo: ',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.reportTextSlate,
                            ),
                          ),
                          Text(
                            state.compliancePercent,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.reportTeal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3. Chú giải vùng sinh lý gọn gàng
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildLegendItem(
                color: AppColors.reportZoneGreen,
                label: 'Tối ưu (<120/80)',
              ),
              _buildLegendItem(
                color: AppColors.reportZoneYellow,
                label: 'Tiền THA (120–139)',
              ),
              _buildLegendItem(
                color: AppColors.reportZoneRed,
                label: 'Tăng HA (≥140/90)',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4. Khung Biểu đồ trực quan
          Container(
            height: 208,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
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
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: point.isLatest
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: point.isLatest
                                  ? AppColors.reportTeal
                                  : AppColors.reportTextMuted,
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
          const SizedBox(height: 14),

          // 5. Hàng tóm tắt trung bình tháng gọn (chạm để xem lịch đo chi tiết)
          InkWell(
            onTap: () => _showTelemetryMetricsSheet(context),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/ic_report_summary_bp.svg',
                    width: 16,
                    height: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'TB tháng: ${state.monthlyAverageBp} mmHg • Nhịp tim ${state.monthlyAverageHeart} bpm',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.reportTextSlate,
                      ),
                    ),
                  ),
                  const Text(
                    'Chi tiết ›',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.reportTeal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTelemetryMetricsSheet(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          AppLayoutTokens.screenPadding,
          12,
          AppLayoutTokens.screenPadding,
          bottomPadding + 24,
        ),
        decoration: const BoxDecoration(
          color: AppColors.reportBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.reportBorderLight,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            SectionHeader(
              title: 'Thống kê theo dõi sinh hiệu',
              subtitle: _metricDisplayTitle,
              icon: Icons.analytics_outlined,
              iconColor: AppColors.reportTeal,
              trailing: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.reportTextMuted,
                ),
              ),
            ),
            const SizedBox(height: 12),
            CleanCard(
              borderColor: AppColors.reportBorderLight,
              child: Column(
                children: [
                  KeyValueRow(
                    label: 'Lần đo gần nhất',
                    value: '${state.latestValue} ${state.latestUnit}',
                  ),
                  KeyValueRow(
                    label: 'Thời điểm ghi nhận',
                    value: state.latestTimestamp,
                  ),
                  KeyValueRow(
                    label: 'Phân loại lâm sàng',
                    value: state.latestClassification,
                  ),
                  KeyValueRow(
                    label: 'Tần suất theo dõi',
                    value: state.monitoringFrequency,
                  ),
                  KeyValueRow(
                    label: 'Khung giờ đo định kỳ',
                    value: state.monitoringSchedule,
                  ),
                  KeyValueRow(
                    label: 'Độ tuân thủ lịch đo',
                    value: state.compliancePercent,
                  ),
                  KeyValueRow(
                    label: 'Huyết áp trung bình tháng',
                    value: '${state.monthlyAverageBp} mmHg',
                  ),
                  KeyValueRow(
                    label: 'Nhịp tim trung bình tháng',
                    value: '${state.monthlyAverageHeart} bpm',
                  ),
                ],
              ),
            ),
          ],
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? AppColors.reportOliveDark
                : AppColors.reportTextSlate,
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
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.reportTextSlate,
          ),
        ),
      ],
    );
  }
}
