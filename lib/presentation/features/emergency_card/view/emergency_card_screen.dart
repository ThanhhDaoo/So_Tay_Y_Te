import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class EmergencyCardScreen extends StatelessWidget {
  const EmergencyCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thẻ cấp cứu y tế'),
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.red.shade50,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: AppColors.error, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.emergency, color: AppColors.error, size: 32),
                      SizedBox(width: 8),
                      Text('THẺ Y TẾ KHẨN CẤP', style: TextStyle(color: AppColors.error, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Divider(height: 24),
                  Text('Họ và tên: Nguyễn Văn A', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Nhóm máu: O+ (Rh+)', style: TextStyle(fontSize: 15, color: AppColors.error, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Dị ứng: Penicillin, Dị ứng hải sản nặng'),
                  SizedBox(height: 8),
                  Text('Bệnh lý mạn tính: Tiểu đường Type 2'),
                  SizedBox(height: 8),
                  Text('Liên hệ khẩn cấp: 0901 234 567 (Người thân)', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Thẻ này hiển thị các thông tin sinh tồn thiết yếu cho nhân viên y tế trong trường hợp khẩn cấp.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
