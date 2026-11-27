import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../common_widgets/layout/app_layout.dart';
import '../../viewmodel/prescriptions_state.dart';

/// Thẻ hiển thị một cữ uống thuốc:
/// - Cữ "Đã uống" tự thu gọn 1 dòng thoáng mắt (chạm để mở xem danh sách thuốc).
/// - Cữ "Sắp đến giờ" làm nổi bật rõ danh sách thuốc và 2 nút thao tác chính.
class RxDoseSlotCard extends StatefulWidget {
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
  State<RxDoseSlotCard> createState() => _RxDoseSlotCardState();
}

class _RxDoseSlotCardState extends State<RxDoseSlotCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.slot.status != DoseSlotStatus.completed;
  }

  @override
  void didUpdateWidget(covariant RxDoseSlotCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slot.status != widget.slot.status) {
      _isExpanded = widget.slot.status != DoseSlotStatus.completed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final slot = widget.slot;
    final isDueSoon = slot.status == DoseSlotStatus.dueSoon;
    final isCompleted = slot.status == DoseSlotStatus.completed;
    final isUpcoming = slot.status == DoseSlotStatus.upcoming;

    final card = CleanCard(
      onTap: isCompleted
          ? () => setState(() => _isExpanded = !_isExpanded)
          : null,
      borderColor: isDueSoon ? AppColors.rxOlive : AppColors.rxBorder,
      padding: const EdgeInsets.all(AppLayoutTokens.cardPadding),
      boxShadow: isDueSoon
          ? [
              BoxShadow(
                color: AppColors.rxOlive.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSlotHeader(slot, isCompleted: isCompleted),
          if (_isExpanded) ...[
            const SizedBox(height: 12),
            for (int i = 0; i < slot.medications.length; i++) ...[
              _MedicationCleanRow(
                item: slot.medications[i],
                isCompleted: isCompleted,
              ),
              if (i < slot.medications.length - 1) const SizedBox(height: 10),
            ],
            if (isDueSoon) ...[
              const SizedBox(height: 14),
              _buildDueActions(),
            ],
          ],
        ],
      ),
    );

    return isUpcoming ? Opacity(opacity: 0.92, child: card) : card;
  }

  Widget _buildSlotHeader(
    MedicationDoseSlot slot, {
    required bool isCompleted,
  }) {
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
          width: 34,
          height: 34,
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
        const SizedBox(width: 10),
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
                    slot.title,
                    style: const TextStyle(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.iceTextNavy,
                    ),
                  ),
                  Text(
                    slot.timeLabel,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: timeColor,
                    ),
                  ),
                ],
              ),
              if (isCompleted && !_isExpanded) ...[
                const SizedBox(height: 2),
                Text(
                  '${slot.medications.length} loại thuốc • Chạm để xem',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.iceTextMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
                    width: 12,
                    height: 7,
                  ),
                  const SizedBox(width: 4),
                ] else if (slot.status == DoseSlotStatus.dueSoon) ...[
                  SvgPicture.asset(
                    'assets/icons/ic_rx_hourglass_red.svg',
                    width: 8.5,
                    height: 11,
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    slot.statusBadge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: slot.status == DoseSlotStatus.upcoming
                          ? FontWeight.w500
                          : FontWeight.w700,
                      color: badgeTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isCompleted) ...[
          const SizedBox(width: 4),
          Icon(
            _isExpanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: AppColors.iceTextMuted,
          ),
        ],
      ],
    );
  }

  Widget _buildDueActions() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: TextButton(
              onPressed: widget.onSnooze,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.rxBlueSoft,
                foregroundColor: AppColors.iceTextNavy,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/ic_rx_snooze_alarm.svg',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'Nhắc lại 15p',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.iceTextNavy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: widget.onMarkTaken,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rxOlive,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/ic_rx_check_white.svg',
                    width: 16,
                    height: 14,
                  ),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'Đã uống',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
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

class _MedicationCleanRow extends StatelessWidget {
  final MedicationItem item;
  final bool isCompleted;

  const _MedicationCleanRow({
    required this.item,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.iceTextNavy,
                        ),
                      ),
                    ),
                    if (item.quantityBadge != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        item.quantityBadge!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.iceDangerText,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.instruction,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    color: AppColors.iceTextSlate,
                    height: 1.35,
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
                width: 16,
                height: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
