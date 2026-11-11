import 'package:flutter/material.dart';
import '../../../../core/utils/date_formatter.dart';

class RecordDetailScreen extends StatelessWidget {
  final String recordId;

  const RecordDetailScreen({super.key, required this.recordId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đợt khám'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Xuất PDF',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đang tạo báo cáo y tế định dạng PDF...')),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mã hồ sơ: $recordId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text('Thời gian: ${DateFormatter.formatWithTime(DateTime.now())}'),
            const Divider(height: 32),
            const Text('Chẩn đoán & Ghi chú:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Người bệnh có các triệu chứng nhẹ, chỉ định dùng thuốc trong 5 ngày và tái khám nếu cần.'),
          ],
        ),
      ),
    );
  }
}
