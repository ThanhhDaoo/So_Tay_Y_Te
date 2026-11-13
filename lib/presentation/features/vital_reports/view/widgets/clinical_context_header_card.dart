import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../viewmodel/vital_reports_state.dart';

class ClinicalContextHeaderCard extends StatelessWidget {
  final VitalMetricType selectedMetric;
  final ValueChanged<VitalMetricType> onSelectMetric;

  const ClinicalContextHeaderCard({
    super.key,
    required this.selectedMetric,
    required this.onSelectMetric,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0x73E8D2B5),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        'assets/icons/ic_report_shield_heart.svg',
                        width: 22,
                        height: 20,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 2,
                            children: [
                              Text(
                                'HỒ SƠ PHÂN TÍCH',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.55,
                                  color: AppColors.reportTeal,
                                ),
                              ),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: AppColors.reportOlive,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(
                                'WHO Clinical Grade',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.reportTextMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Báo Cáo Sinh Hiệu Lâm Sàng',
                            style: AppTypography.heading3.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.reportTextDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.reportCream,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/ic_report_a4_badge.svg',
                      width: 18,
                      height: 18,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Chuẩn A4',
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.reportCreamDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Metric Segment Tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.reportSegmentBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildSegmentTab(
                  type: VitalMetricType.bloodPressure,
                  label: 'Huyết áp',
                  iconPath: 'assets/icons/ic_report_seg_bp.svg',
                ),
                const SizedBox(width: 4),
                _buildSegmentTab(
                  type: VitalMetricType.bloodGlucose,
                  label: 'Đường huyết',
                  iconPath: 'assets/icons/ic_report_seg_glucose.svg',
                ),
                const SizedBox(width: 4),
                _buildSegmentTab(
                  type: VitalMetricType.heartRate,
                  label: 'Nhịp tim',
                  iconPath: 'assets/icons/ic_report_seg_heart.svg',
                ),
                const SizedBox(width: 4),
                _buildSegmentTab(
                  type: VitalMetricType.bmiAndWeight,
                  label: 'BMI & Cân',
                  iconPath: 'assets/icons/ic_report_seg_bmi.svg',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentTab({
    required VitalMetricType type,
    required String label,
    required String iconPath,
  }) {
    final isSelected = selectedMetric == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelectMetric(type),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.reportOlive : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x15000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                iconPath,
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(
                  isSelected ? Colors.white : const Color(0xFF73786D),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF73786D),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
