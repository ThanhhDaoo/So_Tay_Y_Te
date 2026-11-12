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
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.iceAllergyBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.iceAllergyBorder),
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
            decoration: const BoxDecoration(
              color: AppColors.iceOlive,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              'assets/icons/ic_warning_triangle.svg',
              width: 22,
              height: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'CẢNH BÁO NGUY HIỂM',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textWarmBrown,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.iceCriticalBadge,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        warning.severityBadge,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  warning.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.iceOliveDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  warning.description,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: AppColors.iceOlive,
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
