import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class MedicalHistorySheet extends StatelessWidget {
  final String patientName;

  const MedicalHistorySheet({super.key, required this.patientName});

  static void show(BuildContext context, {required String patientName}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MedicalHistorySheet(patientName: patientName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history_edu, color: AppColors.iceOlive, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Bệnh Sử Chi Tiết: $patientName',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.iceTextNavy),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.iceTextMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.iceCardBorder),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomPadding),
              children: [
                _buildTimelineItem(
                  year: '2024',
                  title: 'Viêm dạ dày - tá tràng mạn HP (+)',
                  desc: 'Điều trị ngoại trú phác đồ 14 ngày tại BV Vinmec Central Park. Đã thuyên giảm triệu chứng.',
                  isCurrent: true,
                ),
                _buildTimelineItem(
                  year: '2022',
                  title: 'Dị ứng thuốc Kháng sinh Penicillin (Cấp độ II)',
                  desc: 'Xuất hiện mề đay, phù Quinke nhẹ sau 30 phút tiêm. Đã xử trí bằng Dimedrol và ghi vào sổ cảnh báo ICE.',
                  isAlert: true,
                ),
                _buildTimelineItem(
                  year: '2020',
                  title: 'Phẫu thuật nội soi ruột thừa',
                  desc: 'Thực hiện tại Bệnh viện Đại học Y Dược TP.HCM. Phục hồi hoàn toàn, vết mổ lành tốt không sẹo phì đại.',
                ),
                _buildTimelineItem(
                  year: '2019',
                  title: 'Cận thị khúc xạ 2 mắt (-2.50 Diop)',
                  desc: 'Khám mắt định kỳ tại Bệnh viện Mắt TP.HCM, đeo kính gọng chỉnh quang.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String year,
    required String title,
    required String desc,
    bool isCurrent = false,
    bool isAlert = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isAlert ? const Color(0xFFFDE8E8) : (isCurrent ? AppColors.iceAccentCream : AppColors.surfaceWarm),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isAlert ? const Color(0xFFF98080) : AppColors.iceCardBorder,
              ),
            ),
            child: Text(
              year,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isAlert ? const Color(0xFF9B1C1C) : AppColors.iceTextNavy,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.iceCardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isAlert ? const Color(0xFF9B1C1C) : AppColors.iceTextNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 12, color: AppColors.iceTextSlate, height: 1.35),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
