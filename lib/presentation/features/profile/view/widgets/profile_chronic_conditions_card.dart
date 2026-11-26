import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../common_widgets/layout/app_layout.dart';
import '../../viewmodel/profile_state.dart';

/// Thẻ Bệnh nền & Phẫu thuật tinh gọn: hiển thị tối đa 3 mục tiêu biểu,
/// chạm "Chi tiết" mở toàn bộ bệnh sử trong MedicalHistorySheet.
class ProfileChronicConditionsCard extends StatelessWidget {
  const ProfileChronicConditionsCard({
    super.key,
    required this.conditions,
    this.onDetailTap,
  });

  final List<ChronicConditionItem> conditions;
  final VoidCallback? onDetailTap;

  @override
  Widget build(BuildContext context) {
    final previewItems =
        conditions.length > 3 ? conditions.sublist(0, 3) : conditions;

    return CleanCard(
      onTap: onDetailTap,
      padding: const EdgeInsets.all(AppLayoutTokens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/ic_prof_chronic_history.svg',
                      width: 17,
                      height: 17,
                      colorFilter: const ColorFilter.mode(
                        AppColors.iceOlive,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'Bệnh nền & Phẫu thuật',
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
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    conditions.length > 3
                        ? 'Xem tất cả (${conditions.length})'
                        : 'Chi tiết',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.iceOlive,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SvgPicture.asset(
                    'assets/icons/ic_prof_arrow_right.svg',
                    width: 10,
                    height: 10,
                    colorFilter: const ColorFilter.mode(
                      AppColors.iceOlive,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (conditions.isEmpty)
            const Text(
              'Chưa có ghi nhận bệnh nền mãn tính.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.iceTextMuted,
              ),
            )
          else
            for (int i = 0; i < previewItems.length; i++) ...[
              _ConditionCleanRow(item: previewItems[i]),
              if (i < previewItems.length - 1) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _ConditionCleanRow extends StatelessWidget {
  const _ConditionCleanRow({required this.item});

  final ChronicConditionItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCream,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            item.iconAsset,
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(
              AppColors.iceOlive,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.iceTextNavy,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.statusText,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.iceTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}
