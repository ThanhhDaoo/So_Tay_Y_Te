import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../common_widgets/layout/app_layout.dart';
import '../../viewmodel/emergency_card_state.dart';

/// Thẻ bệnh nền mãn tính cốt lõi trên màn ICE:
/// Giữ mặt ngoài gọn 2 dòng tiêu biểu (Tên bệnh + Nhãn mức độ),
/// đẩy ghi chú điều trị dài sang BottomSheet khi chạm.
class IceChronicConditionsCard extends StatelessWidget {
  final List<ChronicConditionItem> conditions;

  const IceChronicConditionsCard({super.key, required this.conditions});

  @override
  Widget build(BuildContext context) {
    final previewItems =
        conditions.length > 2 ? conditions.sublist(0, 2) : conditions;

    return CleanCard(
      onTap: conditions.isNotEmpty
          ? () => _showConditionsDetailSheet(context)
          : null,
      padding: const EdgeInsets.all(AppLayoutTokens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/ic_heart_pulse.svg',
                width: 16,
                height: 15,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'BỆNH NỀN MÃN TÍNH',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.iceTextNavy,
                  ),
                ),
              ),
              Text(
                conditions.isEmpty
                    ? '0 ghi nhận'
                    : '${conditions.length} ghi nhận ›',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.iceOlive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (conditions.isEmpty)
            const Text(
              'Chưa có ghi nhận bệnh nền mãn tính.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.iceTextMuted,
              ),
            )
          else
            for (int i = 0; i < previewItems.length; i++) ...[
              _CompactConditionRow(item: previewItems[i]),
              if (i < previewItems.length - 1) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  void _showConditionsDetailSheet(BuildContext context) {
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
          color: AppColors.iceBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.iceCardBorder,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            SectionHeader(
              title: 'Chi tiết Bệnh nền mãn tính',
              icon: Icons.monitor_heart_outlined,
              trailing: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.iceTextMuted,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: conditions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, idx) {
                  final item = conditions[idx];
                  return CleanCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.iceTextNavy,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.badgeLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: item.isCriticalBadge
                                    ? AppColors.iceDangerText
                                    : AppColors.iceOlive,
                              ),
                            ),
                          ],
                        ),
                        if (item.note.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            item.note,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: AppColors.iceTextSlate,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactConditionRow extends StatelessWidget {
  final ChronicConditionItem item;

  const _CompactConditionRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final badgeBg = item.isCriticalBadge
        ? AppColors.iceDangerBg
        : AppColors.iceSecondaryCard;
    final badgeText =
        item.isCriticalBadge ? AppColors.iceDangerText : AppColors.iceOlive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.iceMetricBox,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            item.iconAsset,
            width: 17,
            height: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.iceTextNavy,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(6),
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
    );
  }
}
