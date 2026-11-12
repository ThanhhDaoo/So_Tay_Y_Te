import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../viewmodel/profile_state.dart';

class ProfileImmunizationCard extends StatelessWidget {
  const ProfileImmunizationCard({
    super.key,
    required this.immunizations,
  });

  final List<ImmunizationItem> immunizations;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.iceCardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/ic_prof_vaccine_syringe.svg',
                    width: 17,
                    height: 17,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF5C6254),
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tiêm chủng gần nhất',
                    style: AppTypography.heading3.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.iceTextNavy,
                    ),
                  ),
                ],
              ),
              Text(
                '${immunizations.length} loại vắc xin',
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.iceTextMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < immunizations.length; i++) ...[
            _ImmunizationTile(item: immunizations[i]),
            if (i < immunizations.length - 1) const SizedBox(height: 8),
          ],
        ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCream,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: item.isCompleted
                  ? AppColors.iceAccentCream.withValues(alpha: 0.65)
                  : const Color(0xFFE5EEFF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: SvgPicture.asset(
                item.iconAsset,
                width: 16,
                height: 16,
                colorFilter: ColorFilter.mode(
                  item.isCompleted
                      ? AppColors.iceTextBrownDark
                      : const Color(0xFF5C6254),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTypography.labelSemiBold.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.iceTextNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: AppTypography.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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
                  : const Color(0xFFDDD9D0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.badgeLabel,
              style: AppTypography.caption.copyWith(
                fontSize: 10,
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
