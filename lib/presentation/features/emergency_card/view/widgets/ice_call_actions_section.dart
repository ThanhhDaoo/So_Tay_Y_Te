import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../viewmodel/emergency_card_state.dart';

/// Cụm 3 nút gọi khẩn cấp: Người thân (ICE), Bác sĩ điều trị, và Tổng đài 115.
class IceCallActionsSection extends StatelessWidget {
  final EmergencyContactInfo primaryContact;
  final EmergencyContactInfo doctorContact;
  final EmergencyContactInfo hotline115;
  final VoidCallback onCallPrimary;
  final VoidCallback onCallDoctor;
  final VoidCallback onCall115;

  const IceCallActionsSection({
    super.key,
    required this.primaryContact,
    required this.doctorContact,
    required this.hotline115,
    required this.onCallPrimary,
    required this.onCallDoctor,
    required this.onCall115,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PrimaryIceCallButton(
          contact: primaryContact,
          onTap: onCallPrimary,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SecondaryCallCard(
                label: doctorContact.label,
                title: doctorContact.name,
                backgroundColor: AppColors.iceSecondaryCard,
                borderColor: AppColors.iceCardBorder,
                iconBgColor: AppColors.iceOlive.withValues(alpha: 0.12),
                iconAsset: 'assets/icons/ic_doctor_bag.svg',
                iconWidth: 15,
                iconHeight: 15,
                labelColor: AppColors.iceOlive,
                titleColor: AppColors.iceTextNavy,
                onTap: onCallDoctor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SecondaryCallCard(
                label: hotline115.label,
                title: hotline115.name,
                backgroundColor: AppColors.iceAccentCream,
                borderColor: AppColors.iceBorderCream,
                iconBgColor: AppColors.iceOlive,
                iconAsset: 'assets/icons/ic_siren_115.svg',
                iconWidth: 16.5,
                iconHeight: 12.75,
                labelColor: AppColors.textWarmBrown,
                titleColor: AppColors.iceTextBrownDark,
                onTap: onCall115,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PrimaryIceCallButton extends StatelessWidget {
  final EmergencyContactInfo contact;
  final VoidCallback onTap;

  const _PrimaryIceCallButton({
    required this.contact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.icePrimaryCall,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.iceOlive),
            boxShadow: [
              BoxShadow(
                color: AppColors.icePrimaryCall.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.iceAccentCream.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/icons/ic_ice_phone_call.svg',
                  width: 18,
                  height: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.iceAccentCream,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${contact.name} • ${contact.phone}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SvgPicture.asset(
                'assets/icons/ic_ice_arrow_right.svg',
                width: 13.33,
                height: 13.33,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryCallCard extends StatelessWidget {
  final String label;
  final String title;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconBgColor;
  final String iconAsset;
  final double iconWidth;
  final double iconHeight;
  final Color labelColor;
  final Color titleColor;
  final VoidCallback onTap;

  const _SecondaryCallCard({
    required this.label,
    required this.title,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconBgColor,
    required this.iconAsset,
    required this.iconWidth,
    required this.iconHeight,
    required this.labelColor,
    required this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  iconAsset,
                  width: iconWidth,
                  height: iconHeight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
