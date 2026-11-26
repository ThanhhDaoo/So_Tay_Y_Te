import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../common_widgets/layout/app_layout.dart';
import '../../viewmodel/profile_state.dart';

/// Lưới Bento 2x2 hiển thị chỉ số thể chất nền theo chuẩn 3-Point Rule & 8pt Grid.
class ProfileVitalsBentoGrid extends StatelessWidget {
  const ProfileVitalsBentoGrid({
    super.key,
    required this.profile,
  });

  final MemberMedicalProfile profile;

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: 'Thể chất nền',
      iconAsset: 'assets/icons/ic_prof_biometrics.svg',
      iconColor: AppColors.iceOlive,
      bottomSpacing: 0,
      trailing: Text(
        'Cập nhật: ${profile.vitalsUpdatedAt}',
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: AppColors.iceTextMuted,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _BloodTypeTile(
                  bloodType: profile.bloodType,
                  note: profile.bloodNote,
                ),
              ),
              const SizedBox(width: AppLayoutTokens.cardGap),
              Expanded(
                child: _BmiTile(
                  bmiValue: profile.bmiValue,
                  statusLabel: profile.bmiStatusLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppLayoutTokens.cardGap),
          Row(
            children: [
              Expanded(
                child: _MeasurementTile(
                  label: 'Chiều cao',
                  value: profile.heightText,
                  iconAsset: 'assets/icons/ic_prof_height.svg',
                ),
              ),
              const SizedBox(width: AppLayoutTokens.cardGap),
              Expanded(
                child: _MeasurementTile(
                  label: 'Cân nặng',
                  value: profile.weightText,
                  iconAsset: 'assets/icons/ic_prof_weight.svg',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BloodTypeTile extends StatelessWidget {
  const _BloodTypeTile({
    required this.bloodType,
    required this.note,
  });

  final String bloodType;
  final String note;

  @override
  Widget build(BuildContext context) {
    return CleanCard(
      padding: const EdgeInsets.all(AppLayoutTokens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nhóm máu',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.iceTextMuted,
                ),
              ),
              SvgPicture.asset(
                'assets/icons/ic_prof_blood_drop.svg',
                width: 14,
                height: 14,
                colorFilter: const ColorFilter.mode(
                  AppColors.iceDangerText,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            bloodType,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.iceDangerText,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.iceTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _BmiTile extends StatelessWidget {
  const _BmiTile({
    required this.bmiValue,
    required this.statusLabel,
  });

  final String bmiValue;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return CleanCard(
      padding: const EdgeInsets.all(AppLayoutTokens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chỉ số BMI',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.iceTextMuted,
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  bmiValue,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.iceTextNavy,
                    height: 1.1,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'kg/m²',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.iceTextMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
            decoration: BoxDecoration(
              color: AppColors.iceAccentCream,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.iceTextBrownDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasurementTile extends StatelessWidget {
  const _MeasurementTile({
    required this.label,
    required this.value,
    required this.iconAsset,
  });

  final String label;
  final String value;
  final String iconAsset;

  @override
  Widget build(BuildContext context) {
    return CleanCard(
      padding: const EdgeInsets.all(AppLayoutTokens.cardPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.iceTextMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.iceTextNavy,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SvgPicture.asset(
            iconAsset,
            width: 18,
            height: 18,
            colorFilter: const ColorFilter.mode(
              AppColors.iceOlive,
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }
}
