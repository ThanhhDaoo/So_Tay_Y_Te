import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class SecurityStorageBanner extends StatelessWidget {
  const SecurityStorageBanner({
    super.key,
    required this.usedStorageMb,
    required this.savedStorageMb,
    required this.totalStorageGb,
    required this.docCount,
  });

  final int usedStorageMb;
  final int savedStorageMb;
  final String totalStorageGb;
  final int docCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAE5DB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
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
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/ic_doc_e2ee_shield.svg',
                    width: 14,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF00685F),
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Kho Tài Liệu Mã Hóa E2EE',
                    style: AppTypography.heading3.copyWith(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.iceTextNavy,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5EEFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/ic_doc_aes_key.svg',
                      width: 10,
                      height: 12,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF00685F),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '256-bit AES',
                      style: AppTypography.caption.copyWith(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.44,
                        color: const Color(0xFF00685F),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Bộ nhớ thiết bị đã dùng:',
                style: AppTypography.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF3D4947),
                ),
              ),
              Text(
                '$usedStorageMb MB',
                style: AppTypography.labelSemiBold.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF00685F),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.iceAccentCream,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Tiết kiệm $savedStorageMb MB nhờ WebP',
                  style: AppTypography.caption.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.35,
                    color: const Color(0xFF53442F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 7,
              width: double.infinity,
              color: const Color(0xFFE5EEFF),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.28,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF00685F),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đã lưu $docCount chứng từ y khoa',
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3D4947),
                ),
              ),
              Text(
                'Khả dụng: $totalStorageGb',
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6D7A77),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

