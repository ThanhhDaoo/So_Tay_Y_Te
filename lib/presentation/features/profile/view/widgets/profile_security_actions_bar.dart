import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class ProfileSecurityActionsBar extends StatelessWidget {
  const ProfileSecurityActionsBar({
    super.key,
    required this.isEditLocked,
    required this.onToggleLock,
    required this.onExportPdf,
    required this.onShareEmergency,
  });

  final bool isEditLocked;
  final VoidCallback onToggleLock;
  final VoidCallback onExportPdf;
  final VoidCallback onShareEmergency;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceCream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.iceCardBorder.withValues(alpha: 0.80),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/ic_prof_hipaa_lock.svg',
                    width: 15,
                    height: 15,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF5C6254),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mã hóa chuẩn HIPAA / GDPR',
                      style: AppTypography.labelSemiBold.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.iceTextNavy,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      isEditLocked
                          ? 'Hồ sơ đang được khóa chỉnh sửa'
                          : 'Đang mở khóa chỉnh sửa tạm thời',
                      style: AppTypography.caption.copyWith(
                        fontSize: 10.5,
                        color: AppColors.iceTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: isEditLocked
                    ? AppColors.surfaceLight
                    : AppColors.iceAccentCream,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: onToggleLock,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.iceCardBorder),
                    ),
                    child: Text(
                      isEditLocked ? 'Khóa sửa' : 'Đã mở khóa',
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isEditLocked
                            ? const Color(0xFF5C6254)
                            : AppColors.iceTextBrownDark,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Xuất tóm tắt (PDF)',
                iconAsset: 'assets/icons/ic_prof_export_pdf.svg',
                backgroundColor: const Color(0xFF5C6254),
                foregroundColor: AppColors.surfaceLight,
                onTap: onExportPdf,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                label: 'Chia sẻ cấp cứu',
                iconAsset: 'assets/icons/ic_prof_share_qr.svg',
                backgroundColor: AppColors.iceAccentCream,
                foregroundColor: AppColors.iceTextBrownDark,
                onTap: onShareEmergency,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.iconAsset,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final String label;
  final String iconAsset;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                iconAsset,
                width: 16,
                height: 16,
                colorFilter: ColorFilter.mode(
                  foregroundColor,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSemiBold.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: foregroundColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
