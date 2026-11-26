import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../common_widgets/layout/app_layout.dart';

/// Thẻ điều hướng Kho Tài Liệu Y Tế theo chuẩn 3-Point Rule:
/// (1) Icon thư mục, (2) Tiêu đề + tóm tắt 1 dòng, (3) Hành động Mở kho.
class ProfileDocumentsCard extends StatelessWidget {
  const ProfileDocumentsCard({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CleanCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppLayoutTokens.cardPadding),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.iceOlive,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.folder_shared_rounded,
                size: 22,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kho Tài Liệu Y Tế',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.iceTextNavy,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Xét nghiệm, X-Quang & đơn thuốc số hóa OCR',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.iceTextSlate,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surfaceWarm,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Mở kho',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.iceOlive,
                  ),
                ),
                SizedBox(width: 3),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.iceOlive,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
