import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class VaultBrandHero extends StatelessWidget {
  const VaultBrandHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF6EFE5),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE8D2B5)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/icons/ic_vault_hipaa_lock.svg',
                width: 11,
                height: 14,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF4E5547),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'CHUẨN AN TOÀN Y KHOA HIPAA',
                style: AppTypography.caption.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.55,
                  color: const Color(0xFF4E5547),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: 6 * math.pi / 180,
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: const Color(0xFF008378).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF4E5547),
                        Color(0xFF717669),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x594E5547),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/ic_vault_shield_crest.svg',
                      width: 22,
                      height: 27,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Nâng Cấp Sổ Tay Y Tế Pro',
          textAlign: TextAlign.center,
          style: AppTypography.heading1.copyWith(
            fontSize: 23,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppColors.iceTextNavy,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Bảo vệ trọn vẹn sức khỏe cả gia đình với công nghệ đồng bộ mã hóa y tế chuyên sâu.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              fontSize: 13.5,
              height: 1.45,
              color: const Color(0xFF3D4947),
            ),
          ),
        ),
      ],
    );
  }
}
