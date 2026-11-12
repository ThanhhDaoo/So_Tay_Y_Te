import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../viewmodel/emergency_card_state.dart';

/// Thẻ hiển thị danh sách bệnh nền mãn tính cốt lõi.
class IceChronicConditionsCard extends StatelessWidget {
  final List<ChronicConditionItem> conditions;

  const IceChronicConditionsCard({super.key, required this.conditions});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.iceCardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.iceTextNavy.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/ic_heart_pulse.svg',
                width: 16.67,
                height: 15,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'BỆNH NỀN MÃN TÍNH CỐT LÕI',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.iceTextNavy,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.iceOlive.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${conditions.length} GHI NHẬN',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.iceOlive,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < conditions.length; i++) ...[
            _ConditionRow(item: conditions[i]),
            if (i < conditions.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ConditionRow extends StatelessWidget {
  final ChronicConditionItem item;

  const _ConditionRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final badgeBg = item.isCriticalBadge
        ? AppColors.iceDangerBg
        : AppColors.iceSecondaryCard;
    final badgeText = item.isCriticalBadge
        ? AppColors.iceDangerText
        : AppColors.iceOlive;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.iceMetricBox,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: SvgPicture.asset(
              item.iconAsset,
              width: 19,
              height: 17,
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
                        item.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.iceTextNavy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                        border: item.isCriticalBadge
                            ? null
                            : Border.all(color: AppColors.iceCardBorder),
                      ),
                      child: Text(
                        item.badgeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: badgeText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.note,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.iceTextSlate,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
