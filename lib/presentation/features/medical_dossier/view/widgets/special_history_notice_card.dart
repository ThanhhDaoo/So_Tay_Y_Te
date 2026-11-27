import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../common_widgets/senior_40plus/senior_ui_kit.dart';

/// Khung Lưu ý đặc biệt về tiền sử bệnh đồng bộ ngôn ngữ thiết kế với ProfileAllergyWarningCard:
/// Nền trắng sạch, dải chỉ thị lâm sàng 4px màu đỏ đất (#8C4736) bên trái, tinh tế & dễ đọc.
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
      parts.add(
        'Dị ứng cần báo bác sĩ trước khi kê đơn: ${allergies.join(", ")}.',
      );
    }
    if (chronicConditions.isNotEmpty) {
      parts.add('Bệnh nền đang điều trị: ${chronicConditions.join(", ")}.');
    }
    if (parts.isEmpty) {
      return 'Chưa có lưu ý đặc biệt nào. Bấm nút bên dưới để lưu thông tin dị ứng thuốc, phẫu thuật cũ hoặc lời dặn quan trọng khi đi khám.';
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
        backgroundColor: AppColors.iceBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Lưu Ý Đặc Biệt Về Tiền Sử Bệnh',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.iceTextNavy,
          ),
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          autofocus: true,
          style: const TextStyle(fontSize: 16.5, height: 1.45),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText:
                'VD: Dị ứng kháng sinh Penicillin, từng đặt stent mạch vành năm 2023, đang dùng thuốc chống đông máu...',
            hintStyle: const TextStyle(fontSize: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: AppColors.iceCardBorder),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Hủy',
              style: TextStyle(fontSize: 16, color: AppColors.iceTextSlate),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.icePrimaryCall,
              foregroundColor: Colors.white,
              minimumSize: const Size(112, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            onPressed: () {
              final next = ctrl.text.trim();
              Navigator.pop(ctx);
              onSaveNote(next);
            },
            child: const Text(
              'Lưu lưu ý',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.iceAllergyBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.iceTextNavy.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: AppColors.iceCriticalBadge, width: 4.5),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/ic_prof_allergy_alert.svg',
                    width: 17,
                    height: 17,
                    colorFilter: const ColorFilter.mode(
                      AppColors.iceCriticalBadge,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Expanded(
                    child: Text(
                      'LƯU Ý ĐẶC BIỆT KHI KHÁM BỆNH',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.35,
                        color: AppColors.iceCriticalBadge,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.iceAllergyBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _effectiveDisplayNote(),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w400,
                    color: AppColors.iceTextNavy,
                    height: 1.42,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SeniorActionButton(
                label: customNote.trim().isEmpty
                    ? 'Ghi chú lưu ý đặc biệt'
                    : 'Chỉnh sửa lưu ý đặc biệt',
                icon: Icons.edit_outlined,
                variant: SeniorButtonVariant.amberHighlight,
                onPressed: () => _openEditDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
