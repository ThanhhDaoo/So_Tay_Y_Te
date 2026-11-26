import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../common_widgets/layout/app_layout.dart';

/// Lưới Bento 2x2 hiển thị các chỉ số sinh hiệu mới nhất theo Quy tắc 3 điểm dữ liệu:
/// (1) Nhãn chỉ số, (2) Giá trị chính + đơn vị, (3) Trạng thái ngắn gọn 1 dòng.
class TimelineVitalsBento extends StatelessWidget {
  const TimelineVitalsBento({
    super.key,
    this.onViewReports,
    this.bloodPressure,
    this.heartRate,
    this.spo2,
    this.bloodSugar,
  });

  final VoidCallback? onViewReports;
  final String? bloodPressure;
  final String? heartRate;
  final String? spo2;
  final String? bloodSugar;

  @override
  Widget build(BuildContext context) {
    final hasBp = bloodPressure != null && bloodPressure!.trim().isNotEmpty;
    final bpText = hasBp ? bloodPressure! : '--/--';
    final bpNote = hasBp ? 'Đo gần nhất' : 'Chưa ghi nhận';

    final hasHr = heartRate != null && heartRate!.trim().isNotEmpty;
    final hrText = hasHr ? heartRate! : '--';
    final hrNote = hasHr ? 'Nhịp tim nghỉ' : 'Chưa ghi nhận';

    final hasSpo2 = spo2 != null && spo2!.trim().isNotEmpty;
    final spo2Text = hasSpo2 ? spo2! : '--';
    final spo2Note = hasSpo2 ? 'Oxy máu ổn định' : 'Chưa ghi nhận';

    final hasBs = bloodSugar != null && bloodSugar!.trim().isNotEmpty;
    final bsText = hasBs ? bloodSugar! : '--';
    final bsNote = hasBs ? 'Đường huyết đói' : 'Chưa ghi nhận';

    return SectionContainer(
      title: 'Sinh hiệu mới nhất',
      iconAsset: 'assets/icons/ic_vitals_pulse.svg',
      bottomSpacing: 0,
      trailing: onViewReports != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onViewReports,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
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
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.timelineOlive,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right,
                        size: 14,
                        color: AppColors.timelineOlive,
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _VitalMetricTile(
                  label: 'Huyết áp',
                  iconAsset: 'assets/icons/ic_blood_pressure.svg',
                  value: bpText,
                  unit: 'mmHg',
                  statusText: bpNote,
                  isRecorded: hasBp,
                  onTap: onViewReports,
                ),
              ),
              const SizedBox(width: AppLayoutTokens.cardGap),
              Expanded(
                child: _VitalMetricTile(
                  label: 'Nhịp tim',
                  iconAsset: 'assets/icons/ic_heart_rate.svg',
                  value: hrText,
                  unit: 'bpm',
                  statusText: hrNote,
                  isRecorded: hasHr,
                  onTap: onViewReports,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppLayoutTokens.cardGap),
          Row(
            children: [
              Expanded(
                child: _VitalMetricTile(
                  label: 'SpO2',
                  iconAsset: 'assets/icons/ic_spo2_lungs.svg',
                  value: spo2Text,
                  unit: '%',
                  statusText: spo2Note,
                  isRecorded: hasSpo2,
                  onTap: onViewReports,
                ),
              ),
              const SizedBox(width: AppLayoutTokens.cardGap),
              Expanded(
                child: _VitalMetricTile(
                  label: 'Đường huyết',
                  iconAsset: 'assets/icons/ic_blood_glucose.svg',
                  value: bsText,
                  unit: 'mg/dL',
                  statusText: bsNote,
                  isRecorded: hasBs,
                  onTap: onViewReports,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VitalMetricTile extends StatelessWidget {
  final String label;
  final String iconAsset;
  final String value;
  final String unit;
  final String statusText;
  final bool isRecorded;
  final VoidCallback? onTap;

  const _VitalMetricTile({
    required this.label,
    required this.iconAsset,
    required this.value,
    required this.unit,
    required this.statusText,
    required this.isRecorded,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CleanCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppLayoutTokens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Điểm 1: Nhãn chỉ số + Icon nhẹ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.iceTextMuted,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SvgPicture.asset(
                iconAsset,
                width: 14,
                height: 14,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Điểm 2: Giá trị chính (Visual Anchor) + Đơn vị
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    color: isRecorded
                        ? AppColors.iceTextNavy
                        : AppColors.iceTextMuted,
                    height: 1.1,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.iceTextMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Điểm 3: Trạng thái ngắn gọn 1 dòng
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isRecorded
                      ? AppColors.timelineOlive
                      : AppColors.iceCardBorder,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  statusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isRecorded ? FontWeight.w600 : FontWeight.w400,
                    color: isRecorded
                        ? AppColors.timelineOlive
                        : AppColors.iceTextMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
