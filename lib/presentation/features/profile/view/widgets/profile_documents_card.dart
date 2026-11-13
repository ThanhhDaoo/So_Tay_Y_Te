import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';

/// Thẻ nổi bật truy cập Kho Tài Liệu Y Tế & Kết Quả Xét Nghiệm từ màn hình Hồ Sơ.
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF4FAF9),
            Color(0xFFE8F5F3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00685F).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1200685F),
            blurRadius: 10,
            offset: Offset(0, 3),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Icon + Title + Badges + Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon container
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF00897B),
                            Color(0xFF00685F),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x3300685F),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.folder_shared_rounded,
                          size: 26,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title & Badges
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Kho Tài Liệu & Kết Quả XN',
                                  style: AppTypography.heading3.copyWith(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF004D40),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00685F),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  '12 TÀI LIỆU',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2F1),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: const Color(0xFF80CBC4),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      size: 10,
                                      color: Color(0xFF00685F),
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'AI OCR',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF00685F),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Primary Action Button "Mở Kho >"
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00685F),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x2600685F),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Mở kho',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 11,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  'Lưu trữ hồ sơ xét nghiệm máu, phim X-Quang, MRI và đơn thuốc quét số hóa tự động.',
                  style: AppTypography.caption.copyWith(
                    fontSize: 12,
                    color: const Color(0xFF2E5E58),
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 10),

                // Content preview pills
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _FeatureTag(
                      icon: Icons.bloodtype_outlined,
                      label: 'Xét nghiệm máu',
                    ),
                    _FeatureTag(
                      icon: Icons.monitor_heart_outlined,
                      label: 'Phim X-Quang / MRI',
                    ),
                    _FeatureTag(
                      icon: Icons.receipt_long_outlined,
                      label: 'Đơn thuốc OCR',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureTag({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFB2DFDB),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: const Color(0xFF00685F),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF004D40),
            ),
          ),
        ],
      ),
    );
  }
}
