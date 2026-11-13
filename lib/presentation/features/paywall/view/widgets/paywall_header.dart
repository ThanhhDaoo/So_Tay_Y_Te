import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class PaywallHeader extends StatelessWidget {
  const PaywallHeader({
    super.key,
    this.onBack,
    this.onProfileTap,
  });

  final VoidCallback? onBack;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 12),
          decoration: BoxDecoration(
            color: const Color(0xD9FBF9F4),
            border: const Border(
              bottom: BorderSide(
                color: Color(0xFFECE7DF),
                width: 1,
              ),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onBack ?? () => Navigator.of(context).maybePop(),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: SvgPicture.asset(
                          'assets/icons/ic_vault_back_arrow.svg',
                          width: 16,
                          height: 16,
                          colorFilter: const ColorFilter.mode(
                            AppColors.iceTextNavy,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Gói Vault Pro',
                    style: AppTypography.headerTitle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.36,
                      color: AppColors.iceTextNavy,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onProfileTap,
                borderRadius: BorderRadius.circular(999),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/img_profile_avatar.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
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
