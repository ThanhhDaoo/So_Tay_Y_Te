import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../viewmodel/emergency_card_state.dart';

/// Thẻ cảnh báo dị ứng thuốc nguy hiểm.
class IceAllergyWarningCard extends StatelessWidget {
  final DrugAllergyWarning warning;

  const IceAllergyWarningCard({super.key, required this.warning});

  @override
  Widget build(BuildContext context) {
    final isSevere = warning.isSevere;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: isSevere ? AppColors.iceAllergyBg : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSevere ? AppColors.iceAllergyBorder : AppColors.iceCardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.iceTextNavy.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSevere
                  ? AppColors.iceOlive
                  : AppColors.iceOlive.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isSevere
                ? SvgPicture.asset(
                    'assets/icons/ic_warning_triangle.svg',
                    width: 22,
                    height: 19,
                  )
                : const Icon(
                    Icons.shield_outlined,
                    color: AppColors.iceOlive,
                    size: 22,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isSevere ? 'CẢNH BÁO NGUY HIỂM' : 'THÔNG TIN DỊ ỨNG',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSevere
                            ? AppColors.textWarmBrown
                            : AppColors.iceOlive,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSevere
                            ? AppColors.iceCriticalBadge
                            : AppColors.iceOlive.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        warning.severityBadge,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSevere ? Colors.white : AppColors.iceOlive,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  warning.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isSevere
                        ? AppColors.iceOliveDark
                        : AppColors.iceTextNavy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  warning.description,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: isSevere ? AppColors.iceOlive : AppColors.iceTextSlate,
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
