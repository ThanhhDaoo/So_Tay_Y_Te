import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../domain/entities/daily_vital_log.dart';
import '../../../../common_widgets/senior_40plus/senior_ui_kit.dart';

/// Khối Huyết áp hằng ngày (Ưu tiên số 1) theo thẩm mỹ phẳng thoáng Apple Health:
/// So sánh cạnh nhau "Hôm qua" vs "Hôm nay" bằng đường chia mảnh tinh tế (không lồng nhiều hộp viền dày),
/// chữ số 30px tabular sắc nét kèm 2 nút lớn đồng bộ tông Olive & Kem Cát.
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

  Color _statusDotColor(BloodPressureLevel? level) {
    if (level == null) return AppColors.dotMuted;
    switch (level) {
      case BloodPressureLevel.normal:
        return AppColors.reportTeal;
      case BloodPressureLevel.elevated:
        return const Color(0xFFB86B11);
      case BloodPressureLevel.highStage1:
      case BloodPressureLevel.highStage2:
        return AppColors.iceDangerText;
      case BloodPressureLevel.low:
        return const Color(0xFF3A6EA5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final yesterday = comparison.yesterday;
    final today = comparison.today;

    return SeniorSectionBlock(
      title: 'Huyết áp hằng ngày',
      subtitle: 'So sánh trực quan chỉ số hôm qua và hôm nay',
      iconAsset: 'assets/icons/ic_blood_pressure.svg',
      iconColor: AppColors.iceOlive,
      child: SeniorCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bảng so sánh 2 cột phẳng, phân tách bằng đường kẻ dọc 1px thanh lịch
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _BpCleanMetricColumn(
                      kicker: 'HÔM QUA',
                      log: yesterday,
                      emptyHint: 'Chưa ghi nhận',
                      dotColor: _statusDotColor(yesterday?.statusLevel),
                      isToday: false,
                    ),
                  ),
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    color: AppColors.divider,
                  ),
                  Expanded(
                    child: _BpCleanMetricColumn(
                      kicker: 'HÔM NAY',
                      log: today,
                      emptyHint: 'Chưa đo hôm nay',
                      dotColor: _statusDotColor(today?.statusLevel),
                      isToday: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Dải nhận xét y tế nền kem dịu nhẹ, không viền thô
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.iceMetricBox,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                comparison.comparisonSummaryVi,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.iceTextSlate,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2 nút thao tác lớn >= 52px đồng bộ bảng màu MedVault
            SeniorActionButton(
              label: 'Cập nhật huyết áp',
              icon: Icons.edit_outlined,
              variant: SeniorButtonVariant.primary,
              onPressed: onUpdateManual,
            ),
            const SizedBox(height: 10),
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
  final String kicker;
  final DailyVitalLog? log;
  final String emptyHint;
  final Color dotColor;
  final bool isToday;

  const _BpCleanMetricColumn({
    required this.kicker,
    required this.log,
    required this.emptyHint,
    required this.dotColor,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          kicker,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: isToday ? AppColors.reportTeal : AppColors.iceTextMuted,
          ),
        ),
        const SizedBox(height: 8),
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
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.9,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: isToday
                        ? AppColors.iceTextNavy
                        : AppColors.iceTextSlate,
                    height: 1.1,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'mmHg',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.iceTextMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (log!.heartRate != null && log!.heartRate! > 0)
            Text(
              'Nhịp tim: ${log!.heartRate} l/phút',
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                fontFeatures: [FontFeature.tabularFigures()],
                color: AppColors.iceTextSlate,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  log!.statusLabelVi,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: dotColor,
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          const Text(
            '-- / --',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: AppColors.dotMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            emptyHint,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: AppColors.iceTextMuted,
            ),
          ),
        ],
      ],
    );
  }
}
