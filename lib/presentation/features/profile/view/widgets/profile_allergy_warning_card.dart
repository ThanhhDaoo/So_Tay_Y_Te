import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../viewmodel/profile_state.dart';

class ProfileAllergyWarningCard extends StatelessWidget {
  const ProfileAllergyWarningCard({
    super.key,
    required this.allergies,
  });

  final List<AllergyItem> allergies;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.iceCardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(
                color: AppColors.iceDangerText,
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.iceDangerBg.withValues(alpha: 0.70),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/icons/ic_prof_allergy_alert.svg',
                              width: 17,
                              height: 17,
                              colorFilter: const ColorFilter.mode(
                                AppColors.iceDangerText,
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
                                'Tiền sử Dị ứng nghiêm ngặt',
                                style: AppTypography.labelSemiBold.copyWith(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.iceTextNavy,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'Cảnh báo đỏ trước điều trị',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.iceDangerText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${allergies.length} dị nguyên',
                    style: AppTypography.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.iceTextMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              for (int i = 0; i < allergies.length; i++) ...[
                _AllergyTile(item: allergies[i]),
                if (i < allergies.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AllergyTile extends StatelessWidget {
  const _AllergyTile({required this.item});

  final AllergyItem item;

  @override
  Widget build(BuildContext context) {
    final bgColor = item.isHighRisk
        ? AppColors.iceDangerBg.withValues(alpha: 0.40)
        : AppColors.surfaceCream;
    final borderColor = item.isHighRisk
        ? AppColors.iceDangerBg
        : AppColors.iceAccentCream.withValues(alpha: 0.40);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: item.isHighRisk
                  ? AppColors.iceDangerBg
                  : AppColors.iceAccentCream.withValues(alpha: 0.60),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: SvgPicture.asset(
                item.iconAsset,
                width: 15,
                height: 15,
                colorFilter: ColorFilter.mode(
                  item.isHighRisk
                      ? AppColors.iceDangerText
                      : AppColors.iceTextBrownDark,
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: AppTypography.labelSemiBold.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: item.isHighRisk
                              ? AppColors.iceDangerText
                              : AppColors.iceTextNavy,
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
                        color: item.isHighRisk
                            ? AppColors.iceDangerText
                            : AppColors.iceAccentCream,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.severityLabel,
                        style: AppTypography.caption.copyWith(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: item.isHighRisk
                              ? AppColors.surfaceLight
                              : AppColors.iceTextBrownDark,
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.includes != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.includes!,
                    style: AppTypography.body.copyWith(
                      fontSize: 12,
                      color: AppColors.iceTextSlate,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  item.reaction,
                  style: AppTypography.body.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: item.isHighRisk
                        ? const Color(0xFF93000A)
                        : AppColors.iceTextSlate,
                    height: 1.35,
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
