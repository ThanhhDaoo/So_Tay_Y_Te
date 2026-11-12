import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../viewmodel/profile_state.dart';

class ProfileVitalsBentoGrid extends StatelessWidget {
  const ProfileVitalsBentoGrid({
    super.key,
    required this.profile,
  });

  final MemberMedicalProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/ic_prof_biometrics.svg',
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF5C6254),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Thể chất nền',
                  style: AppTypography.heading3.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.iceTextNavy,
                  ),
                ),
              ],
            ),
            Text(
              'Cập nhật: ${profile.vitalsUpdatedAt}',
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.iceTextMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _BloodTypeTile(
                bloodType: profile.bloodType,
                note: profile.bloodNote,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BmiTile(
                bmiValue: profile.bmiValue,
                statusLabel: profile.bmiStatusLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MeasurementTile(
                label: 'Chiều cao',
                value: profile.heightText,
                iconAsset: 'assets/icons/ic_prof_height.svg',
              ),
            ),
            const SizedBox(width: 10),
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
    return Container(
      padding: const EdgeInsets.all(14),
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
              Text(
                'Nhóm máu',
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.iceTextMuted,
                ),
              ),
              SvgPicture.asset(
                'assets/icons/ic_prof_blood_drop.svg',
                width: 15,
                height: 15,
                colorFilter: const ColorFilter.mode(
                  AppColors.iceDangerText,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            bloodType,
            style: AppTypography.heading2.copyWith(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: AppColors.iceDangerText,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              fontSize: 10.5,
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
    return Container(
      padding: const EdgeInsets.all(14),
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
              Text(
                'Chỉ số BMI',
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.iceTextMuted,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.iceAccentCream,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: AppTypography.caption.copyWith(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.iceTextBrownDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                bmiValue,
                style: AppTypography.heading2.copyWith(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF5C6254),
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'kg/m²',
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.iceTextMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5D8CB),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: 2,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5C6254),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.iceAccentCream,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.iceTextMuted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: AppTypography.heading3.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.iceTextNavy,
                ),
              ),
            ],
          ),
          SvgPicture.asset(
            iconAsset,
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
              Color(0xFF5C6254),
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }
}
