import 'package:flutter/material.dart';
import '../../../../../core/config/supabase_config.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../common_widgets/layout/app_layout.dart';
import '../../viewmodel/security_settings_state.dart';

class CloudSyncCard extends StatelessWidget {
  final SecuritySettingsState state;
  final VoidCallback onSyncNow;
  final ValueChanged<bool> onToggleAutoSync;

  const CloudSyncCard({
    super.key,
    required this.state,
    required this.onSyncNow,
    required this.onToggleAutoSync,
  });

  @override
  Widget build(BuildContext context) {
    final isConfigured = SupabaseConfig.isConfigured;

    return SectionContainer(
      title: 'Đồng Bộ Đám Mây Supabase',
      icon: Icons.cloud_sync_rounded,
      iconColor: AppColors.primary,
      titleColor: AppColors.textPrimaryLight,
      bottomSpacing: 0,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isConfigured
              ? const Color(0xFFE8F5E9)
              : const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          isConfigured ? 'RLS SECURE' : 'OFFLINE-FIRST',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isConfigured
                ? const Color(0xFF2E7D32)
                : const Color(0xFFE65100),
          ),
        ),
      ),
      child: CleanCard(
        borderColor: AppColors.secCardBorder,
        padding: const EdgeInsets.all(AppLayoutTokens.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.storage_rounded,
                    size: 19,
                    color: Color(0xFF00796B),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cơ Sở Dữ Liệu Đám Mây PostgreSQL',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Lần đồng bộ gần nhất: ${state.cloudSyncTimeLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6D7A77),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tự Động Đồng Bộ 2 Chiều',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tự cập nhật khi có kết nối mạng',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6D7A77),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: state.isAutoCloudSyncEnabled,
                  onChanged: onToggleAutoSync,
                  activeTrackColor: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: state.isSyncingCloud ? null : onSyncNow,
                icon: state.isSyncingCloud
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.sync_rounded, size: 18),
                label: Text(
                  state.isSyncingCloud
                      ? 'Đang Đồng Bộ Đám Mây...'
                      : 'Đồng Bộ Ngay (2 Chiều)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
