import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common_widgets/custom_button.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nâng cấp bản Pro')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.workspace_premium, size: 80, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              'Mở khóa toàn bộ tính năng Pro',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildFeatureRow(Icons.cloud_sync, 'Đồng bộ hóa đám mây không giới hạn'),
            _buildFeatureRow(Icons.picture_as_pdf, 'Xuất hồ sơ sức khỏe dạng PDF chuẩn y khoa'),
            _buildFeatureRow(Icons.family_restroom, 'Quản lý hồ sơ nhiều thành viên gia đình'),
            _buildFeatureRow(Icons.security, 'Mã hóa cấp cao bảo vệ dữ liệu y tế'),
            const Spacer(),
            CustomButton(
              text: 'Đăng ký ngay - 59.000đ / tháng',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Xử lý thanh toán thành công!')),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}
