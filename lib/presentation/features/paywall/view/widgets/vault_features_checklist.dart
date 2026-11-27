import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../common_widgets/layout/app_layout.dart';

class VaultFeaturesChecklist extends StatelessWidget {
  const VaultFeaturesChecklist({super.key});

  @override
  Widget build(BuildContext context) {
    return CleanCard(
      backgroundColor: Colors.white,
      borderColor: const Color(0xFFEAECF0),
      padding: const EdgeInsets.all(AppLayoutTokens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                'Đặc quyền Sổ Tay Y Tế Pro',
                style: AppTypography.heading3.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.iceTextNavy,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '5 TÍNH NĂNG MỞ KHÓA',
                  style: AppTypography.caption.copyWith(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.35,
                    color: const Color(0xFF1E56A0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _FeatureItem(
            iconAsset: 'assets/icons/ic_vault_feat_family.svg',
            iconBg: Color(0xFFF1F5F9),
            title: 'Đa hồ sơ gia đình không giới hạn',
            description: 'Lập hồ sơ riêng cho con nhỏ, bố mẹ & ông bà.',
          ),
          const SizedBox(height: AppLayoutTokens.cardGap),
          const _FeatureItem(
            iconAsset: 'assets/icons/ic_vault_feat_cloud.svg',
            iconBg: Color(0xFFF1F5F9),
            title: 'Đồng bộ đám mây 2 chiều tự động',
            description: 'Mã hóa AES-256 đầu cuối, an toàn khi đổi máy.',
          ),
          const SizedBox(height: AppLayoutTokens.cardGap),
          const _FeatureItem(
            iconAsset: 'assets/icons/ic_vault_feat_ocr.svg',
            iconBg: Color(0xFFF1F5F9),
            title: 'AI Medical OCR không giới hạn',
            description: 'Quét tự động đơn thuốc & xét nghiệm trong 3 giây.',
          ),
          const SizedBox(height: AppLayoutTokens.cardGap),
          const _FeatureItem(
            iconAsset: 'assets/icons/ic_vault_feat_pdf.svg',
            iconBg: Color(0xFFF1F5F9),
            title: 'Xuất Bệnh án PDF A4 chuẩn y khoa',
            description: 'Bản tóm tắt lâm sàng trình bác sĩ & bảo hiểm.',
          ),
          const SizedBox(height: AppLayoutTokens.cardGap),
          const _FeatureItem(
            iconAsset: 'assets/icons/ic_vault_feat_ice.svg',
            iconBg: Color(0xFFE5EEFF),
            title: 'Thẻ Cấp Cứu ICE ngoài màn hình khóa',
            description: 'Hiển thị nhóm máu & dị ứng thuốc khẩn cấp 24/7.',
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
  });

  final String iconAsset;
  final Color iconBg;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(AppLayoutTokens.innerRadius),
          ),
          child: Center(
            child: SvgPicture.asset(
              iconAsset,
              width: 17,
              height: 17,
              colorFilter: const ColorFilter.mode(
                Color(0xFF1E56A0),
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
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSemiBold.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.iceTextNavy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body.copyWith(
                  fontSize: 12,
                  color: const Color(0xFF475467),
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
