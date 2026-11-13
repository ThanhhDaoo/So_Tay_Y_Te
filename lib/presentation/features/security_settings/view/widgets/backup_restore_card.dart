import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
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
    final isExporting = state.currentOperation == SecurityOperation.exportingBackup;
    final isRestoring = state.currentOperation == SecurityOperation.restoringBackup;

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
                    SvgPicture.asset(
                      'assets/icons/ic_sec_backup_cat.svg',
                      width: 17,
                      height: 14,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Sao Lưu & Khôi Phục Dữ Liệu',
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
                  color: const Color(0x8099EFE5),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  'FREE & PRO',
                  style: AppTypography.caption.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.44,
                    color: AppColors.secOlive,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Main Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.secCardBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Safe local backup banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.secItemBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.reportTeal.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        'assets/icons/ic_sec_backup_package.svg',
                        width: 24,
                        height: 19,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tệp gói tin mã hóa độc lập',
                            style: AppTypography.body.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tập tin (.sotayyte) gồm toàn bộ hồ sơ bệnh án, lịch sử đơn thuốc và ảnh gốc.',
                            style: AppTypography.caption.copyWith(
                              fontSize: 11.5,
                              color: AppColors.secOliveMuted,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Export button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: (isExporting || isRestoring) ? null : onExportBackup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secOlive,
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: isExporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/ic_sec_export_backup.svg',
                              width: 14,
                              height: 14,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Xuất Tệp Dự Phòng (.sotayyte)',
                                style: AppTypography.labelSemiBold.copyWith(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 8),

              // Restore button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: (isExporting || isRestoring) ? null : onRestoreBackup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secRadioSelectedBg,
                    foregroundColor: AppColors.secOlive,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: isRestoring
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.secOlive),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/ic_sec_restore_backup.svg',
                              width: 14,
                              height: 17,
                              colorFilter: const ColorFilter.mode(
                                AppColors.secOlive,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Khôi phục từ tệp có sẵn',
                                style: AppTypography.labelSemiBold.copyWith(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secOlive,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Last backup info
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/ic_sec_backup_clock_info.svg',
                    width: 14,
                    height: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Lần sao lưu gần nhất: ${state.lastBackupTime} (${state.lastBackupSize})',
                      style: AppTypography.caption.copyWith(
                        fontSize: 11.5,
                        color: AppColors.secOliveMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

