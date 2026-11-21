import 'package:flutter/material.dart';
import '../../../../../core/config/supabase_config.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_sync_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Đồng Bộ Đám Mây Supabase',
                        style: AppTypography.heading3.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isConfigured ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isConfigured ? const Color(0xFF81C784) : const Color(0xFFFFB74D),
                  ),
                ),
                child: Text(
                  isConfigured ? 'RLS SECURE' : 'OFFLINE-FIRST',
                  style: AppTypography.caption.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isConfigured ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Main Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEAE5DB)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Server info row
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.storage_rounded,
                      size: 20,
                      color: Color(0xFF00796B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cơ Sở Dữ Liệu Đám Mây PostgreSQL',
                          style: AppTypography.labelSemiBold.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Lần đồng bộ gần nhất: ${state.cloudSyncTimeLabel}',
                          style: AppTypography.caption.copyWith(
                            fontSize: 12,
                            color: const Color(0xFF6D7A77),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Color(0xFFF0ECE4)),
              ),

              // Auto sync switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tự Động Đồng Bộ 2 Chiều',
                          style: AppTypography.labelSemiBold.copyWith(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tự cập nhật bệnh án & toa thuốc khi có mạng',
                          style: AppTypography.caption.copyWith(
                            fontSize: 11.5,
                            color: const Color(0xFF6D7A77),
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
              const SizedBox(height: 12),

              // Sync Now Button
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
                    state.isSyncingCloud ? 'Đang Đồng Bộ Đám Mây...' : 'Đồng Bộ Ngay (2 Chiều)',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withAlpha(150),
                    disabledForegroundColor: Colors.white70,
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
      ],
    );
  }
}
