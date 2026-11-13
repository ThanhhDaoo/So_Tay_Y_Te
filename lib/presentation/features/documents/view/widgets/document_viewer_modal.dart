import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class DocumentViewerModal extends StatelessWidget {
  final String title;
  final String category;
  final String date;
  final String hospital;
  final String imageAsset;
  final List<Map<String, String>> keyFindings;

  const DocumentViewerModal({
    super.key,
    required this.title,
    required this.category,
    required this.date,
    required this.hospital,
    required this.imageAsset,
    required this.keyFindings,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String category,
    required String date,
    required String hospital,
    required String imageAsset,
    required List<Map<String, String>> keyFindings,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DocumentViewerModal(
        title: title,
        category: category,
        date: date,
        hospital: hospital,
        imageAsset: imageAsset,
        keyFindings: keyFindings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.iceOlive.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.iceOliveDark),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.iceTextNavy),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.iceTextMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.iceCardBorder),

          // Body
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomPadding),
              children: [
                // Zoomable image frame
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 240,
                    width: double.infinity,
                    color: Colors.black,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        InteractiveViewer(
                          minScale: 1.0,
                          maxScale: 3.5,
                          child: Image.asset(
                            imageAsset,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(Icons.image_not_supported, size: 48, color: Colors.white54),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.pinch, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text('Thu phóng 2 ngón', style: TextStyle(fontSize: 10, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // File metadata
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.iceCardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Bệnh viện / Cơ sở', style: TextStyle(fontSize: 11, color: AppColors.iceTextMuted)),
                            Text(hospital, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.iceTextNavy)),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 30, color: AppColors.iceCardBorder),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ngày thực hiện', style: TextStyle(fontSize: 11, color: AppColors.iceTextMuted)),
                          Text(date, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.iceTextNavy)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Key OCR Highlights
                const Text(
                  'Dữ Liệu Trích Xuất AI OCR',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.iceTextNavy),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.iceCardBorder),
                  ),
                  child: Column(
                    children: keyFindings.map((finding) {
                      final label = finding['label'] ?? '';
                      final value = finding['value'] ?? '';
                      final status = finding['status'] ?? 'Bình thường';
                      final isAlert = status != 'Bình thường';

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppColors.iceCardBorder.withValues(alpha: 0.5))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(label, style: const TextStyle(fontSize: 13, color: AppColors.iceTextNavy)),
                            Row(
                              children: [
                                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.iceTextNavy)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isAlert ? const Color(0xFFFDE8E8) : const Color(0xFFDEF7EC),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isAlert ? const Color(0xFF9B1C1C) : const Color(0xFF03543F),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đang tải tệp PDF gốc độ phân giải cao...'),
                              backgroundColor: AppColors.iceOlive,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.file_download_outlined, size: 18),
                        label: const Text('Tải Tệp Gốc'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.iceOliveDark,
                          side: const BorderSide(color: AppColors.iceOlive),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã mã hóa E2EE và tạo liên kết gửi bác sĩ'),
                              backgroundColor: AppColors.iceOlive,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Gửi Bác Sĩ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.iceOlive,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
