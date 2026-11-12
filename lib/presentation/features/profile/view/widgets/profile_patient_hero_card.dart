import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../viewmodel/profile_state.dart';

class ProfilePatientHeroCard extends StatelessWidget {
  const ProfilePatientHeroCard({
    super.key,
    required this.profile,
  });

  final MemberMedicalProfile profile;

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
                      child: Image.asset(
                        profile.heroImageAsset,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
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
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
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
                          text: 'Khu vực: ${profile.region}',
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
