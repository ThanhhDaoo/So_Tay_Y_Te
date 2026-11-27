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
        Center(
          child: SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: 6 * math.pi / 180,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E9F6E).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1E56A0),
                        Color(0xFF667085),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x261E56A0),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/ic_vault_shield_crest.svg',
                      width: 20,
                      height: 24,
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
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF4FF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFDCE8FF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/icons/ic_vault_hipaa_lock.svg',
                width: 10,
                height: 13,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF1E56A0),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'CHUẨN AN TOÀN Y KHOA HIPAA',
                style: AppTypography.caption.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: const Color(0xFF1E56A0),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Nâng Cấp Sổ Tay Y Tế Pro',
          textAlign: TextAlign.center,
          style: AppTypography.heading1.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppColors.iceTextNavy,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Đồng bộ đám mây mã hóa đầu cuối & quản lý trọn vẹn sức khỏe cả gia đình.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              fontSize: 13.5,
              height: 1.4,
              color: const Color(0xFF475467),
            ),
          ),
        ),
      ],
    );
  }
}
