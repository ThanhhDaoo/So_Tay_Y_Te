import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../common_widgets/layout/app_layout.dart';
import '../../viewmodel/security_settings_state.dart';

class BackupRestoreCard extends StatelessWidget {
  final SecuritySettingsState state;
  final VoidCallback onExportBackup;
  final VoidCallback onRestoreBackup;

  const BackupRestoreCard({
    super.key,
    required this.state,
    required this.onExportBackup,
    required this.onRestoreBackup,
  });

  @override
  Widget build(BuildContext context) {
    final isExporting =
        state.currentOperation == SecurityOperation.exportingBackup;
    final isRestoring =
        state.currentOperation == SecurityOperation.restoringBackup;

    return SectionContainer(
      title: 'Sao Lưu & Khôi Phục Dữ Liệu',
      iconAsset: 'assets/icons/ic_sec_backup_cat.svg',
      titleColor: AppColors.textPrimaryLight,
      bottomSpacing: 0,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0x8099EFE5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          'FREE & PRO',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.secOlive,
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.reportTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'assets/icons/ic_sec_backup_package.svg',
                    width: 20,
                    height: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tệp gói tin mã hóa độc lập',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sao lưu gần nhất: ${state.lastBackupTime} (${state.lastBackupSize})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secOliveMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed:
                    (isExporting || isRestoring) ? null : onExportBackup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secOlive,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isExporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Xuất Tệp Dự Phòng (.sotayyte)',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed:
                    (isExporting || isRestoring) ? null : onRestoreBackup,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secOlive,
                  side: const BorderSide(color: AppColors.secCardBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isRestoring
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.secOlive,
                          ),
                        ),
                      )
                    : const Text(
                        'Khôi phục từ tệp có sẵn',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
