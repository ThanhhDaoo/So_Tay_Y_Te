import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/safe_avatar_image.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.activeMemberName,
    required this.activeAvatarAsset,
    this.isViewingFamilyMember = false,
    this.primaryMemberName = '',
    this.onProfileTap,
  });

  final String activeMemberName;
  final String activeAvatarAsset;
  final bool isViewingFamilyMember;
  final String primaryMemberName;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 14),
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            border: Border(
              bottom: BorderSide(
                color: AppColors.iceCardBorder,
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
                color: isViewingFamilyMember ? const Color(0xFFFBF4EB) : AppColors.surfaceCream,
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
                        color: isViewingFamilyMember
                            ? const Color(0xFFD6A770)
                            : const Color(0x99E5DFD4),
                      ),
                    ),
                    child: isViewingFamilyMember
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.arrow_back_rounded,
                                size: 14,
                                color: Color(0xFF9C5A14),
                              ),
                              const SizedBox(width: 4),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 100),
                                child: Text(
                                  activeMemberName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF9C5A14),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                '(Về tôi)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF9C5A14),
                                ),
                              ),
                            ],
                          )
                        : Row(
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
                                  child: buildSafeAvatarImage(
                                    imageSource: activeAvatarAsset,
                                    fallbackAsset: 'assets/images/img_profile_avatar.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 120),
                                child: Text(
                                  activeMemberName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelSemiBold.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.iceTextNavy,
                                  ),
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
