import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/services/user_session_manager.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/safe_avatar_image.dart';

/// Thanh tiêu đề kính mờ cố định phía trên của màn hình Thẻ Cấp Cứu ICE.
class IceHeader extends StatelessWidget {
  final VoidCallback? onProfileTap;
  final bool readOnlyLockMode;
  final VoidCallback? onBackToLock;

  const IceHeader({
    super.key,
    this.onProfileTap,
    this.readOnlyLockMode = false,
    this.onBackToLock,
  });

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
            left: 20,
            right: 20,
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
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!readOnlyLockMode && Navigator.of(context).canPop()) ...[
                      Material(
                        color: AppColors.iceBackground,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.iceCardBorder),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              size: 19,
                              color: AppColors.iceTextNavy,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Image.asset(
                      'assets/images/img_sotayyte_logo.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'SỔ TAY Y TẾ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.55,
                              color: AppColors.iceOlive,
                              height: 1.2,
                            ),
                          ),
                          Text(
                            'Cấp Cứu ICE',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.iceTextNavy,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (readOnlyLockMode)
                InkWell(
                  onTap: onBackToLock ?? () => Navigator.of(context).maybePop(),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 15,
                          color: AppColors.error,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Quay lại khóa',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
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
                        ListenableBuilder(
                          listenable: AppSessionNotifier.instance,
                          builder: (context, _) => ClipOval(
                            child: buildSafeAvatarImage(
                              imageSource: AppSessionNotifier.instance.avatarUrl ?? '',
                              fallbackAsset: 'assets/images/img_profile_avatar.png',
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                            ),
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
