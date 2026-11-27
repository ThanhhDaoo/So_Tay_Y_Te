import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../domain/entities/daily_vital_log.dart';
import '../../../../common_widgets/senior_40plus/senior_ui_kit.dart';

/// Khối 2 trên Trang chủ (Ưu tiên số 1):
/// Thẻ lớn so sánh cạnh nhau "Huyết áp hôm qua" vs "Cập nhật hôm nay" (cỡ 26px - 30px),
/// kèm 2 nút lớn: "Cập nhật huyết áp" và "Chụp ảnh máy đo (Scan)".
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

  (Color, Color) _levelColors(BloodPressureLevel? level) {
    if (level == null) {
      return (AppColors.surfaceCream, AppColors.iceTextSlate);
    }
    switch (level) {
      case BloodPressureLevel.normal:
        return (SeniorTokens.callActionGreenSoft, SeniorTokens.callActionGreen);
      case BloodPressureLevel.elevated:
        return (SeniorTokens.warningAmberBg, SeniorTokens.warningAmberText);
      case BloodPressureLevel.highStage1:
      case BloodPressureLevel.highStage2:
        return (SeniorTokens.highBpRedBg, SeniorTokens.highBpRedText);
      case BloodPressureLevel.low:
        return (const Color(0xFFE3F2FD), const Color(0xFF0D47A1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final yesterday = comparison.yesterday;
    final today = comparison.today;

    return SeniorSectionBlock(
      title: 'Huyết áp hằng ngày',
      subtitle: 'Theo dõi đều đặn mỗi sáng giúp phòng ngừa tai biến',
      icon: Icons.monitor_heart_rounded,
      iconColor: const Color(0xFFC62828),
      iconBgColor: const Color(0xFFFFEBEE),
      child: SeniorCard(
        padding: const EdgeInsets.all(20),
        borderColor: AppColors.iceBorderCream,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hai cột so sánh cạnh nhau: Hôm qua vs Hôm nay
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _BpDayColumn(
                      dayTitle: 'HÔM QUA',
                      log: yesterday,
                      emptyHint: 'Chưa ghi nhận',
                      isHighlighted: false,
                      colors: _levelColors(yesterday?.statusLevel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BpDayColumn(
                      dayTitle: 'HÔM NAY',
                      log: today,
                      emptyHint: 'Chưa đo hôm nay',
                      isHighlighted: true,
                      colors: _levelColors(today?.statusLevel),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Dòng nhận xét so sánh tiếng Việt to rõ
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceCream,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.health_and_safety_rounded,
                    size: 26,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      comparison.comparisonSummaryVi,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.iceTextNavy,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2 nút hành động lớn >= 54px
            SeniorActionButton(
              label: 'Cập nhật huyết áp',
              icon: Icons.edit_note_rounded,
              variant: SeniorButtonVariant.primary,
              onPressed: onUpdateManual,
            ),
            const SizedBox(height: 12),
            SeniorActionButton(
              label: 'Chụp ảnh máy đo (Scan)',
              icon: Icons.camera_alt_rounded,
              variant: SeniorButtonVariant.amberHighlight,
              onPressed: onScanMachine,
            ),
          ],
        ),
      ),
    );
  }
}

class _BpDayColumn extends StatelessWidget {
  final String dayTitle;
  final DailyVitalLog? log;
  final String emptyHint;
  final bool isHighlighted;
  final (Color, Color) colors;

  const _BpDayColumn({
    required this.dayTitle,
    required this.log,
    required this.emptyHint,
    required this.isHighlighted,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final (badgeBg, badgeFg) = colors;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.primaryPeach.withValues(alpha: 0.32)
            : AppColors.surfaceCream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted ? AppColors.accent : AppColors.iceCardBorder,
          width: isHighlighted ? 1.6 : 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isHighlighted ? Icons.today_rounded : Icons.history_rounded,
                size: 20,
                color: isHighlighted ? AppColors.accent : AppColors.iceTextSlate,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  dayTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color:
                        isHighlighted ? AppColors.accent : AppColors.iceTextSlate,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (log != null) ...[
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                log!.formattedBp,
                style: const TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w900,
                  color: AppColors.iceTextNavy,
                  height: 1.1,
                ),
              ),
            ),
            const Text(
              'mmHg',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.iceTextSlate,
              ),
            ),
            const SizedBox(height: 6),
            if (log!.heartRate != null && log!.heartRate! > 0)
              Row(
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    size: 18,
                    color: Color(0xFFC62828),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Mạch: ${log!.heartRate} l/p',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.iceTextNavy,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                log!.statusLabelVi,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: badgeFg,
                ),
              ),
            ),
          ] else ...[
            const Text(
              '-- / --',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              emptyHint,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: AppColors.iceTextSlate,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
