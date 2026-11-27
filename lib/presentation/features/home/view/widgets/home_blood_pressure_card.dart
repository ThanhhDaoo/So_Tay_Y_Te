import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../domain/entities/daily_vital_log.dart';
import '../../../../common_widgets/senior_40plus/senior_ui_kit.dart';

/// Khối Huyết áp hằng ngày (Ưu tiên số 1) cân đối 2 cột "Hôm qua" vs "Hôm nay", không tràn chữ.
class HomeBloodPressureCard extends StatelessWidget {
  final YesterdayTodayBpComparison comparison;
  final VoidCallback onUpdateManual;
  final VoidCallback onScanMachine;

  const HomeBloodPressureCard({
    super.key,
    required this.comparison,
    required this.onUpdateManual,
    required this.onScanMachine,
  });

  (Color fg, Color bg) _statusBadgeColors(BloodPressureLevel? level) {
    if (level == null) {
      return (AppColors.iceTextMuted, AppColors.timelineInputBg);
    }
    switch (level) {
      case BloodPressureLevel.normal:
        return (AppColors.reportTeal, AppColors.reportTealSoft);
      case BloodPressureLevel.elevated:
        return (const Color(0xFFB45309), const Color(0xFFFFFBEB));
      case BloodPressureLevel.highStage1:
      case BloodPressureLevel.highStage2:
        return (AppColors.iceDangerText, AppColors.iceDangerBg);
      case BloodPressureLevel.low:
        return (AppColors.primary, AppColors.iceAccentCream);
    }
  }

  @override
  Widget build(BuildContext context) {
    final yesterday = comparison.yesterday;
    final today = comparison.today;

    return SeniorSectionBlock(
      title: 'Huyết áp hằng ngày',
      subtitle: 'So sánh chỉ số hôm qua và cập nhật hôm nay',
      iconAsset: 'assets/icons/ic_blood_pressure.svg',
      iconColor: AppColors.primary,
      child: SeniorCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _BpCleanMetricColumn(
                      titleLabel: 'Hôm qua',
                      log: yesterday,
                      emptyHint: 'Chưa ghi nhận',
                      badgeColors: _statusBadgeColors(yesterday?.statusLevel),
                      isToday: false,
                    ),
                  ),
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    color: AppColors.divider,
                  ),
                  Expanded(
                    child: _BpCleanMetricColumn(
                      titleLabel: 'Hôm nay',
                      log: today,
                      emptyHint: 'Chưa đo hôm nay',
                      badgeColors: _statusBadgeColors(today?.statusLevel),
                      isToday: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.iceBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.iceCardBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1.5),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      comparison.comparisonSummaryVi,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        color: AppColors.iceTextSlate,
                        height: 1.38,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            SeniorActionButton(
              label: 'Cập nhật huyết áp',
              icon: Icons.edit_outlined,
              variant: SeniorButtonVariant.primary,
              onPressed: onUpdateManual,
            ),
            const SizedBox(height: 8),
            SeniorActionButton(
              label: 'Chụp ảnh máy đo (Scan)',
              icon: Icons.document_scanner_outlined,
              variant: SeniorButtonVariant.amberHighlight,
              onPressed: onScanMachine,
            ),
          ],
        ),
      ),
    );
  }
}

class _BpCleanMetricColumn extends StatelessWidget {
  final String titleLabel;
  final DailyVitalLog? log;
  final String emptyHint;
  final (Color fg, Color bg) badgeColors;
  final bool isToday;

  const _BpCleanMetricColumn({
    required this.titleLabel,
    required this.log,
    required this.emptyHint,
    required this.badgeColors,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = badgeColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                titleLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                  color: isToday ? AppColors.primary : AppColors.iceTextMuted,
                ),
              ),
            ),
            if (isToday) ...[
              const SizedBox(width: 5),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        if (log != null) ...[
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  log!.formattedBp,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: isToday
                        ? AppColors.iceTextNavy
                        : AppColors.iceTextSlate,
                    height: 1.12,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'mmHg',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.iceTextMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (log!.heartRate != null && log!.heartRate! > 0)
            Text(
              'Nhịp tim: ${log!.heartRate} l/p',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                fontFeatures: [FontFeature.tabularFigures()],
                color: AppColors.iceTextMuted,
              ),
            ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              log!.statusLabelVi,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ] else ...[
          const Text(
            '-- / --',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.dotMuted,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
            decoration: BoxDecoration(
              color: AppColors.timelineInputBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              emptyHint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.iceTextMuted,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
