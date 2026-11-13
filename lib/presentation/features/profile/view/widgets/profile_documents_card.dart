import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

/// Thẻ truy cập nhanh kho tài liệu xét nghiệm & bệnh án từ màn hình Profile.
class ProfileDocumentsCard extends StatelessWidget {
  const ProfileDocumentsCard({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F3EC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.folder_shared_outlined,
                      size: 22,
                      color: AppColors.iceOlive,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Tài liệu & Kết quả xét nghiệm',
                            style: AppTypography.heading3.copyWith(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.iceTextNavy,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8EFE3),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              '12 TỆP',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.iceOlive,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Quản lý kết quả máu, X-Quang, MRI và OCR tóm tắt tự động.',
                        style: AppTypography.caption.copyWith(
                          fontSize: 11.5,
                          color: AppColors.iceTextSlate,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: AppColors.iceTextMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
