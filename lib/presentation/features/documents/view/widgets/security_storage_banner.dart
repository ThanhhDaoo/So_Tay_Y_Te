import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../common_widgets/layout/app_layout.dart';

/// Thanh trạng thái lưu trữ mã hóa E2EE mảnh gọn theo 3-Point Rule:
/// Mặt ngoài hiển thị gọn Tên kho + Số chứng từ & Dung lượng,
/// chạm mở BottomSheet xem chi tiết mức tiết kiệm WebP và thanh tiến độ bộ nhớ.
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
    return CleanCard(
      onTap: () => _showStorageDetailSheet(context),
      backgroundColor: const Color(0xFFF9F7F2),
      borderColor: const Color(0xFFEAE5DB),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/ic_doc_e2ee_shield.svg',
            width: 15,
            height: 18,
            colorFilter: const ColorFilter.mode(
              Color(0xFF00685F),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Kho E2EE • $docCount chứng từ ($usedStorageMb MB)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.iceTextNavy,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE5EEFF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              '256-bit AES',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF00685F),
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: AppColors.iceTextMuted,
          ),
        ],
      ),
    );
  }

  void _showStorageDetailSheet(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          AppLayoutTokens.screenPadding,
          12,
          AppLayoutTokens.screenPadding,
          bottomPadding + 24,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.iceCardBorder,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            SectionHeader(
              title: 'Kho Tài Liệu Mã Hóa E2EE',
              subtitle: 'Chuẩn bảo mật 256-bit AES cục bộ',
              icon: Icons.enhanced_encryption_outlined,
              iconColor: const Color(0xFF00685F),
              trailing: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.iceTextMuted,
                ),
              ),
            ),
            const SizedBox(height: 14),
            CleanCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KeyValueRow(
                    label: 'Tổng chứng từ y khoa',
                    value: '$docCount tài liệu',
                  ),
                  KeyValueRow(
                    label: 'Dung lượng đang dùng',
                    value: '$usedStorageMb MB',
                    valueColor: const Color(0xFF00685F),
                  ),
                  KeyValueRow(
                    label: 'Dung lượng nén tiết kiệm (WebP)',
                    value: '$savedStorageMb MB',
                  ),
                  KeyValueRow(
                    label: 'Bộ nhớ khả dụng',
                    value: totalStorageGb,
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: 0.28,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFE5EEFF),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF00685F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
