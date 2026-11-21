import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/safe_avatar_image.dart';
import '../../viewmodel/profile_state.dart';

class ProfilePatientHeroCard extends StatelessWidget {
  const ProfilePatientHeroCard({
    super.key,
    required this.profile,
    this.isPrimary = true,
    this.onEditTap,
    this.onDeleteTap,
    this.onPickAvatar,
  });

  final MemberMedicalProfile profile;
  final bool isPrimary;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onPickAvatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.iceBackground,
            AppColors.iceAccentCream,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.iceAccentCream.withValues(alpha: 0.70),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned(
              right: -12,
              bottom: -14,
              child: Opacity(
                opacity: 0.08,
                child: SvgPicture.asset(
                  'assets/icons/ic_prof_shield_watermark.svg',
                  width: 96,
                  height: 96,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          buildSafeAvatarImage(
                            imageSource: profile.heroImageAsset,
                            fallbackAsset: 'assets/images/img_profile_hero_portrait.png',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          ),
                          if (onPickAvatar != null)
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: Material(
                                color: AppColors.iceOlive,
                                shape: const CircleBorder(),
                                elevation: 3,
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: onPickAvatar,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          profile.fullName,
                          style: AppTypography.heading2.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.35,
                            color: AppColors.iceTextNavy,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: SvgPicture.asset(
                          'assets/icons/ic_prof_verified_user.svg',
                          width: 18,
                          height: 18,
                        ),
                      ),
                      if (onEditTap != null) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onEditTap,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.iceOlive.withValues(alpha: 0.4)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_outlined, size: 14, color: AppColors.iceOlive),
                                SizedBox(width: 4),
                                Text(
                                  'Sửa',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.iceOlive,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (!isPrimary && onDeleteTap != null) ...[
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: onDeleteTap,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete_outline, size: 14, color: Colors.red),
                                SizedBox(width: 2),
                                Text(
                                  'Xóa',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isPrimary
                              ? AppColors.iceOlive.withValues(alpha: 0.15)
                              : const Color(0xFFE28743).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isPrimary
                              ? 'HỒ SƠ GỐC'
                              : 'THÀNH VIÊN: ${profile.relationship.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: isPrimary
                                ? AppColors.iceOlive
                                : const Color(0xFFC05621),
                          ),
                        ),
                      ),
                      Text(
                        'Mã hồ sơ: ${profile.recordCode}',
                        style: AppTypography.body.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.iceTextSlate,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          profile.bhytStatus,
                          style: AppTypography.caption.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF5C6254),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AppColors.iceTextBrownDark.withValues(
                            alpha: 0.12,
                          ),
                        ),
                      ),
                    ),
                    child: Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      children: [
                        _MetaItem(
                          iconAsset: 'assets/icons/ic_prof_cake_dob.svg',
                          text: 'Sinh ngày: ${profile.dob}',
                        ),
                        _MetaItem(
                          iconAsset: 'assets/icons/ic_prof_location.svg',
                          text: 'Khu vực: ${(profile.region.isNotEmpty && !profile.region.contains('@') && profile.region != 'Chưa cập nhật') ? profile.region : 'Chưa cập nhật'}',
                        ),
                        if (profile.contact.isNotEmpty)
                          _MetaItem(
                            iconAsset: 'assets/icons/ic_prof_verified_user.svg',
                            text: 'Liên hệ: ${profile.contact}',
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.iconAsset,
    required this.text,
  });

  final String iconAsset;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          iconAsset,
          width: 13,
          height: 13,
          colorFilter: const ColorFilter.mode(
            AppColors.iceTextBrownDark,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: AppTypography.body.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.iceTextBrownDark,
          ),
        ),
      ],
    );
  }
}
