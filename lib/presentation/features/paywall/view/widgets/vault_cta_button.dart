import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_typography.dart';

class VaultCtaButton extends StatelessWidget {
  const VaultCtaButton({
    super.key,
    required this.onStartTrial,
    this.isProcessing = false,
  });

  final VoidCallback onStartTrial;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: const Color(0xFF4E5547),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: isProcessing ? null : onStartTrial,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 48,
              width: double.infinity,
              alignment: Alignment.center,
              child: isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/ic_vault_cta_lock.svg',
                          width: 14,
                          height: 17,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Dùng thử 7 ngày miễn phí - Bắt đầu ngay',
                          style: AppTypography.labelSemiBold.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hủy bất cứ lúc nào trong App Store. Không trừ phí trong 7 ngày dùng thử.',
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(
            fontSize: 11,
            color: const Color(0xFF3D4947),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
