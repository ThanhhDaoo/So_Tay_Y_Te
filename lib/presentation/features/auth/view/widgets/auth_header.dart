import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class AuthHeader extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onProfileTap;

  const AuthHeader({
    super.key,
    this.onBack,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final canPop = Navigator.canPop(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.only(top: topPadding),
          decoration: const BoxDecoration(
            color: AppColors.headerOverlay,
            boxShadow: [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: SizedBox(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (canPop) ...[
                        InkWell(
                          onTap: onBack ?? () => Navigator.maybePop(context),
                          borderRadius: BorderRadius.circular(9999),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/icons/ic_arrow_back.svg',
                                width: 16,
                                height: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/icons/ic_logo_book.svg',
                            width: 14.92,
                            height: 14.93,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sổ Tay Y Tế',
                        style: AppTypography.headerTitle,
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: onProfileTap,
                    borderRadius: BorderRadius.circular(9999),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/icons/ic_user_circle.svg',
                          width: 12,
                          height: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
