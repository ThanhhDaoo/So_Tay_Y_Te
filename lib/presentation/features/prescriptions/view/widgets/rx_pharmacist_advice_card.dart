import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';

/// Khối ghi chú lời dặn dược sĩ ở cuối màn hình đơn thuốc.
class RxPharmacistAdviceCard extends StatelessWidget {
  final String advice;

  const RxPharmacistAdviceCard({super.key, required this.advice});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rxBorder.withValues(alpha: 0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.rxAdviceCircle,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              'assets/icons/ic_rx_pharmacist_bag.svg',
              width: 16.67,
              height: 16.67,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lời dặn dược sĩ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.44,
                    color: AppColors.rxOlive,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  advice,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.45,
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

