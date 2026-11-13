import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class VaultFeaturesChecklist extends StatelessWidget {
  const VaultFeaturesChecklist({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECE7DF)),
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
              Expanded(
                child: Text(
                  'Đặc quyền Sổ Tay Y Tế Pro',
                  style: AppTypography.heading3.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.iceTextNavy,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6EFE5),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE8D2B5)),
                ),
                child: Text(
                  '5 TÍNH NĂNG MỞ KHÓA',
                  style: AppTypography.caption.copyWith(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.35,
                    color: const Color(0xFF4E5547),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FeatureItem(
            iconAsset: 'assets/icons/ic_vault_feat_family.svg',
            iconBg: const Color(0xFFF0F1ED),
            title: 'Đa hồ sơ gia đình không giới hạn',
            description:
                'Lập hồ sơ riêng biệt cho con nhỏ, bố mẹ và người cao tuổi.',
          ),
          const SizedBox(height: 14),
          _FeatureItem(
            iconAsset: 'assets/icons/ic_vault_feat_cloud.svg',
            iconBg: const Color(0xFFF0F1ED),
            title: 'Đồng bộ đám mây 2 chiều tự động',
            tagText: 'Zero-loss',
            tagBg: AppColors.iceAccentCream,
            tagColor: const Color(0xFF251A08),
            description:
                'Mã hóa AES-256 đầu cuối đạt chuẩn an toàn ngân hàng.',
          ),
          const SizedBox(height: 14),
          _FeatureItem(
            iconAsset: 'assets/icons/ic_vault_feat_ocr.svg',
            iconBg: const Color(0xFFF0F1ED),
            title: 'AI Medical OCR không giới hạn',
            tagText: '3 GIÂY',
            tagBg: const Color(0xFFF0F1ED),
            tagBorder: const Color(0xFFA5A79B),
            tagColor: const Color(0xFF4E5547),
            description:
                'Quét & trích xuất chính xác đơn thuốc, chỉ số xét nghiệm máu.',
          ),
          const SizedBox(height: 14),
          _FeatureItem(
            iconAsset: 'assets/icons/ic_vault_feat_pdf.svg',
            iconBg: const Color(0xFFF0F1ED),
            title: 'Xuất Bệnh án PDF A4 chuẩn y khoa',
            description:
                'Mẫu tài liệu chuyên môn trình bác sĩ và giám định bảo hiểm.',
          ),
          const SizedBox(height: 14),
          _FeatureItem(
            iconAsset: 'assets/icons/ic_vault_feat_ice.svg',
            iconBg: const Color(0xFFE5EEFF),
            title: 'Widget Thẻ Cấp Cứu ICE ngoài màn hình khóa',
            description:
                'Cung cấp nhóm máu, dị ứng thuốc cho đội cứu thương 24/7.',
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.iconAsset,
    required this.iconBg,
    required this.title,
    required this.description,
    this.tagText,
    this.tagBg,
    this.tagBorder,
    this.tagColor,
  });

  final String iconAsset;
  final Color iconBg;
  final String title;
  final String description;
  final String? tagText;
  final Color? tagBg;
  final Color? tagBorder;
  final Color? tagColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: SvgPicture.asset(
              iconAsset,
              width: 17,
              height: 17,
              colorFilter: const ColorFilter.mode(
                Color(0xFF4E5547),
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelSemiBold.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.iceTextNavy,
                    ),
                  ),
                  if (tagText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: tagBg ?? Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: tagBorder != null
                            ? Border.all(color: tagBorder!)
                            : null,
                      ),
                      child: Text(
                        tagText!,
                        style: AppTypography.caption.copyWith(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: tagColor ?? AppColors.iceTextNavy,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTypography.body.copyWith(
                  fontSize: 12,
                  color: const Color(0xFF3D4947),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
