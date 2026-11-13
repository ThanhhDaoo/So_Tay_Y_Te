import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.activeMemberName,
    required this.activeAvatarAsset,
    this.onProfileTap,
  });

  final String activeMemberName;
  final String activeAvatarAsset;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 14),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight.withValues(alpha: 0.90),
            border: const Border(
              bottom: BorderSide(
                color: Color(0x80E5DFD4),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/img_sotayyte_logo.png',
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SỔ TAY Y TẾ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.55,
                          color: AppColors.iceOlive,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        'Hồ Sơ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.iceTextNavy,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Material(
                color: AppColors.surfaceCream,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onProfileTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0x99E5DFD4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.iceAccentCream,
                            border: Border.all(
                              color: AppColors.surfaceLight,
                              width: 1,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              activeAvatarAsset,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          activeMemberName,
                          style: AppTypography.labelSemiBold.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.iceTextNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
