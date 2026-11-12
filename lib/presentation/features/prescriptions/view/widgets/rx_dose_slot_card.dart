import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../viewmodel/prescriptions_state.dart';

/// Thẻ hiển thị một cữ uống thuốc (Đã uống / Sắp đến giờ / Chưa đến giờ).
class RxDoseSlotCard extends StatelessWidget {
  final MedicationDoseSlot slot;
  final VoidCallback onMarkTaken;
  final VoidCallback onSnooze;

  const RxDoseSlotCard({
    super.key,
    required this.slot,
    required this.onMarkTaken,
    required this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    final isDueSoon = slot.status == DoseSlotStatus.dueSoon;
    final isUpcoming = slot.status == DoseSlotStatus.upcoming;

    final card = Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rxBorder),
        boxShadow: isDueSoon
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Column(
        children: [
          _buildSlotHeader(),
          const SizedBox(height: 10),
          for (int i = 0; i < slot.medications.length; i++) ...[
            _MedicationRow(
              item: slot.medications[i],
              isCompleted: slot.status == DoseSlotStatus.completed,
            ),
            if (i < slot.medications.length - 1) const SizedBox(height: 8),
          ],
          if (isDueSoon) ...[
            const SizedBox(height: 10),
            _buildDueActions(),
          ],
        ],
      ),
    );

    return isUpcoming ? Opacity(opacity: 0.9, child: card) : card;
  }

  Widget _buildSlotHeader() {
    final (circleBg, badgeBg, badgeTextColor, timeColor) = switch (slot.status) {
      DoseSlotStatus.completed => (
        AppColors.rxBadgeCream.withValues(alpha: 0.85),
        AppColors.rxBadgeCream,
        AppColors.textWarmBrown,
        AppColors.iceTextMuted,
      ),
      DoseSlotStatus.dueSoon => (
        AppColors.iceDangerBg,
        AppColors.iceDangerBg,
        AppColors.rxProDarkText,
        AppColors.rxOlive,
      ),
      DoseSlotStatus.upcoming => (
        AppColors.rxBlueSoft,
        AppColors.rxBlueSoft,
        AppColors.iceTextSlate,
        AppColors.iceTextMuted,
      ),
    };

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: circleBg,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            slot.slotIconAsset,
            width: 16,
            height: 15,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                slot.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.iceTextNavy,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                slot.timeLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: slot.status == DoseSlotStatus.dueSoon
                      ? FontWeight.w700
                      : FontWeight.w500,
                  letterSpacing: 0.24,
                  color: timeColor,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (slot.status == DoseSlotStatus.completed) ...[
                SvgPicture.asset(
                  'assets/icons/ic_rx_double_check.svg',
                  width: 12.78,
                  height: 7.02,
                ),
                const SizedBox(width: 4),
              ] else if (slot.status == DoseSlotStatus.dueSoon) ...[
                SvgPicture.asset(
                  'assets/icons/ic_rx_hourglass_red.svg',
                  width: 8.67,
                  height: 10.83,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                slot.statusBadge,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: slot.status == DoseSlotStatus.upcoming
                      ? FontWeight.w500
                      : FontWeight.w700,
                  color: badgeTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDueActions() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: TextButton(
              onPressed: onSnooze,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.rxBlueSoft,
                foregroundColor: AppColors.iceTextNavy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/ic_rx_snooze_alarm.svg',
                    width: 15.98,
                    height: 14.74,
                  ),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'Nhắc lại sau 15p',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.iceTextNavy,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: onMarkTaken,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rxOlive,
                foregroundColor: Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/ic_rx_check_white.svg',
                    width: 12.23,
                    height: 9.02,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Đã uống',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MedicationRow extends StatelessWidget {
  final MedicationItem item;
  final bool isCompleted;

  const _MedicationRow({
    required this.item,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCream,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: SvgPicture.asset(
              item.iconAsset,
              width: 16,
              height: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.iceTextNavy,
                        ),
                      ),
                    ),
                    if (item.quantityBadge != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        item.quantityBadge!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.iceDangerText,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.instruction,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.iceTextSlate,
                  ),
                ),
              ],
            ),
          ),
          if (isCompleted) ...[
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: SvgPicture.asset(
                'assets/icons/ic_rx_check_circle.svg',
                width: 16.67,
                height: 16.67,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

