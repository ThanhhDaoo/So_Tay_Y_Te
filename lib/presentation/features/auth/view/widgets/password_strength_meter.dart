import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../viewmodel/register_state.dart';

class PasswordStrengthMeter extends StatelessWidget {
  final PasswordStrength strength;

  const PasswordStrengthMeter({
    super.key,
    required this.strength,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceCream,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(3, (index) {
              final isActive = index < strength.level;
              return Expanded(
                child: Container(
                  height: 5,
                  margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.divider,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/ic_check_circle.svg',
                width: 11.67,
                height: 11.67,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Khuyên dùng mức “Mạnh” để bảo vệ hồ sơ bệnh án.',
                  style: AppTypography.caption,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
