import 'package:flutter/material.dart';
import '../../../../../core/config/firebase_config.dart';
import '../../../../../core/config/supabase_config.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class CloudBackendStatusBadge extends StatelessWidget {
  const CloudBackendStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final hasSupabase = SupabaseConfig.isConfigured;
    final hasFirebase = FirebaseConfig.isConfigured;

    return GestureDetector(
      onTap: () => _showBackendInfoDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secCardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: (hasSupabase || hasFirebase) ? AppColors.success : AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              hasSupabase
                  ? 'Supabase Cloud'
                  : hasFirebase
                      ? 'Firebase Auth'
                      : 'Local-First + Cloud Ready',
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.info_outline, size: 12, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showBackendInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.cloud_sync_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                'Kiến Trúc Đám Mây',
                style: AppTypography.heading2.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildServiceRow(
                icon: Icons.storage_rounded,
                name: 'Supabase PostgreSQL',
                status: SupabaseConfig.isConfigured ? 'Đang kết nối Cloud' : 'Chế độ Local-First (SQLite)',
                isOnline: SupabaseConfig.isConfigured,
                description: 'Lưu trữ CSDL bệnh án, toa thuốc và các tệp đính kèm.',
              ),
              const Divider(height: 20),
              _buildServiceRow(
                icon: Icons.verified_user_rounded,
                name: 'Firebase Auth Engine',
                status: FirebaseConfig.isConfigured ? 'Firebase Production' : 'Firebase Sandbox (Mã test 123456)',
                isOnline: true,
                description: 'Xử lý xác thực SMS OTP, Apple ID & Google Sign-In.',
              ),
              const Divider(height: 20),
              _buildServiceRow(
                icon: Icons.shield_rounded,
                name: 'Local-First SQLite Vault',
                status: 'Bảo mật 100% thiết bị',
                isOnline: true,
                description: 'Mã hóa SHA-256 + Salt, truy cập tức thì khi mất mạng.',
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đã hiểu', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildServiceRow({
    required IconData icon,
    required String name,
    required String status,
    required bool isOnline,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: isOnline ? AppColors.primary : AppColors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(name, style: AppTypography.labelSemiBold),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isOnline ? AppColors.success : AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              Text(
                status,
                style: AppTypography.caption.copyWith(
                  color: isOnline ? AppColors.primary : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(description, style: AppTypography.caption.copyWith(fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}
