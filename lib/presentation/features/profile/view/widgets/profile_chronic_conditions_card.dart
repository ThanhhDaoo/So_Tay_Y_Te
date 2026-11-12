import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../viewmodel/profile_state.dart';

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
                    'assets/icons/ic_prof_chronic_history.svg',
                    width: 17,
                    height: 17,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF5C6254),
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Bệnh nền & Phẫu thuật',
                    style: AppTypography.heading3.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.iceTextNavy,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onDetailTap,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Chi tiết',
                        style: AppTypography.labelSemiBold.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF5C6254),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SvgPicture.asset(
                        'assets/icons/ic_prof_arrow_right.svg',
                        width: 11,
                        height: 11,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF5C6254),
                          BlendMode.srcIn,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < conditions.length; i++) ...[
            _ConditionRow(item: conditions[i]),
            if (i < conditions.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ConditionRow extends StatelessWidget {
  const _ConditionRow({required this.item});

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
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.iceCardBorder.withValues(alpha: 0.60),
              ),
            ),
            child: Center(
              child: SvgPicture.asset(
                item.iconAsset,
                width: 15,
                height: 15,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF5C6254),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.title,
              style: AppTypography.labelSemiBold.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.iceTextNavy,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.statusText,
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.iceTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}
