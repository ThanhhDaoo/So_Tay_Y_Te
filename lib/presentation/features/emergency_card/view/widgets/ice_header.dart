import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';

/// Thanh tiêu đề kính mờ cố định phía trên của màn hình Thẻ Cấp Cứu ICE.
class IceHeader extends StatelessWidget {
  final VoidCallback? onProfileTap;

  const IceHeader({super.key, this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.only(
            top: topPadding + 10,
            bottom: 10,
            left: 16,
            right: 16,
          ),
          decoration: BoxDecoration(
            color: AppColors.iceGlassSurface,
            border: Border(
              bottom: BorderSide(
                color: AppColors.iceCardBorder.withValues(alpha: 0.7),
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
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  const Column(
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
                        'Cap Cuu Ice',
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
              InkWell(
                onTap: onProfileTap,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.iceMetricBox,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.iceCardBorder.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipOval(
                        child: Image.asset(
                          'assets/images/img_profile_avatar.png',
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: SvgPicture.asset(
                          'assets/icons/ic_chevron_down.svg',
                          width: 9,
                          height: 5.55,
                        ),
                      ),
                    ],
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
