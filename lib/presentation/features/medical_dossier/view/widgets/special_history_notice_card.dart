import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../common_widgets/senior_40plus/senior_ui_kit.dart';

/// Khung Lưu ý đặc biệt về tiền sử bệnh (Nổi bật, tương phản cao, chữ to 17px - 19px)
/// đặt ngay trong phần Tiền sử bệnh án của Trang Hồ sơ & Bệnh án.
class SpecialHistoryNoticeCard extends StatelessWidget {
  final String customNote;
  final List<String> allergies;
  final List<String> chronicConditions;
  final ValueChanged<String> onSaveNote;

  const SpecialHistoryNoticeCard({
    super.key,
    required this.customNote,
    required this.allergies,
    required this.chronicConditions,
    required this.onSaveNote,
  });

  String _effectiveDisplayNote() {
    if (customNote.trim().isNotEmpty) {
      return customNote.trim();
    }
    final parts = <String>[];
    if (allergies.isNotEmpty) {
      parts.add('Dị ứng cần báo bác sĩ trước khi kê đơn: ${allergies.join(", ")}.');
    }
    if (chronicConditions.isNotEmpty) {
      parts.add('Bệnh nền đang điều trị: ${chronicConditions.join(", ")}.');
    }
    if (parts.isEmpty) {
      return 'Chưa có lưu ý đặc biệt nào. Hãy bấm nút "Ghi chú lưu ý" bên dưới để lưu thông tin dị ứng thuốc, phẫu thuật cũ hoặc lời dặn quan trọng khi đi khám.';
    }
    return parts.join('\n');
  }

  Future<void> _openEditDialog(BuildContext context) async {
    final ctrl = TextEditingController(
      text: customNote.trim().isNotEmpty ? customNote.trim() : '',
    );
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: SeniorTokens.warningAmberBorder,
              size: 30,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Lưu Ý Đặc Biệt Về Tiền Sử Bệnh',
                style: TextStyle(fontSize: 19.5, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          autofocus: true,
          style: const TextStyle(fontSize: 17, height: 1.4),
          decoration: InputDecoration(
            hintText:
                'VD: Dị ứng kháng sinh Penicillin, từng đặt stent mạch vành năm 2023, đang dùng thuốc chống đông máu...',
            hintStyle: const TextStyle(fontSize: 15.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(fontSize: 17)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB86B11),
              foregroundColor: Colors.white,
              minimumSize: const Size(120, 50),
            ),
            onPressed: () {
              final next = ctrl.text.trim();
              Navigator.pop(ctx);
              onSaveNote(next);
            },
            child: const Text(
              'Lưu lưu ý',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SeniorTokens.warningAmberBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: SeniorTokens.warningAmberBorder,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: SeniorTokens.warningAmberBorder.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: SeniorTokens.warningAmberBorder.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.report_problem_rounded,
                  size: 30,
                  color: SeniorTokens.warningAmberText,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'LƯU Ý ĐẶC BIỆT KHI KHÁM BỆNH',
                  style: TextStyle(
                    fontSize: 18.5,
                    fontWeight: FontWeight.w900,
                    color: SeniorTokens.warningAmberText,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: SeniorTokens.warningAmberBorder.withValues(alpha: 0.45),
              ),
            ),
            child: Text(
              _effectiveDisplayNote(),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.iceTextNavy,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SeniorActionButton(
            label: customNote.trim().isEmpty
                ? 'Ghi chú lưu ý đặc biệt'
                : 'Chỉnh sửa lưu ý đặc biệt',
            icon: Icons.edit_note_rounded,
            variant: SeniorButtonVariant.amberHighlight,
            onPressed: () => _openEditDialog(context),
          ),
        ],
      ),
    );
  }
}
