import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../common_widgets/layout/app_layout.dart';
import '../../viewmodel/profile_state.dart';

/// Thẻ Tiêm chủng tinh gọn: hiển thị tối đa 2 mũi gần nhất ở mặt ngoài,
/// nếu nhiều hơn có thể mở BottomSheet xem toàn bộ lịch sử vắc xin.
class ProfileImmunizationCard extends StatelessWidget {
  const ProfileImmunizationCard({
    super.key,
    required this.immunizations,
  });

  final List<ImmunizationItem> immunizations;

  @override
  Widget build(BuildContext context) {
    final previewItems =
        immunizations.length > 2 ? immunizations.sublist(0, 2) : immunizations;

    return CleanCard(
      onTap: immunizations.length > 2
          ? () => _showAllImmunizationsSheet(context)
          : null,
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
                      'assets/icons/ic_prof_vaccine_syringe.svg',
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
                        'Tiêm chủng gần nhất',
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
              if (immunizations.length > 2)
                InkWell(
                  onTap: () => _showAllImmunizationsSheet(context),
                  child: Text(
                    'Xem cả ${immunizations.length} mũi ›',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.iceOlive,
                    ),
                  ),
                )
              else
                Text(
                  '${immunizations.length} loại vắc xin',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.iceTextMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (immunizations.isEmpty)
            const Text(
              'Chưa có lịch sử tiêm chủng.',
              style: TextStyle(fontSize: 13, color: AppColors.iceTextMuted),
            )
          else
            for (int i = 0; i < previewItems.length; i++) ...[
              _ImmunizationTile(item: previewItems[i]),
              if (i < previewItems.length - 1) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  void _showAllImmunizationsSheet(BuildContext context) {
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
          color: AppColors.backgroundLight,
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
              title: 'Lịch sử tiêm chủng (${immunizations.length})',
              icon: Icons.vaccines_outlined,
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
                itemCount: immunizations.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _ImmunizationTile(item: immunizations[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImmunizationTile extends StatelessWidget {
  const _ImmunizationTile({required this.item});

  final ImmunizationItem item;

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
            colorFilter: ColorFilter.mode(
              item.isCompleted ? AppColors.iceTextBrownDark : AppColors.iceOlive,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.iceTextNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.iceTextMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: item.isCompleted
                  ? AppColors.iceAccentCream
                  : const Color(0xFFEAECF0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.badgeLabel,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: item.isCompleted
                    ? AppColors.iceTextBrownDark
                    : AppColors.iceTextSlate,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
