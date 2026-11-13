import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_typography.dart';

class TrustAssurancesRow extends StatelessWidget {
  const TrustAssurancesRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/ic_vault_doctor_seal.svg',
              width: 16,
              height: 16,
              colorFilter: const ColorFilter.mode(
                Color(0xFF4E5547),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Bảo chứng bác sĩ',
              style: AppTypography.caption.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3D4947),
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/ic_vault_realtime_backup.svg',
              width: 13,
              height: 13,
              colorFilter: const ColorFilter.mode(
                Color(0xFF4E5547),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Sao lưu theo thời gian thực',
              style: AppTypography.caption.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3D4947),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
