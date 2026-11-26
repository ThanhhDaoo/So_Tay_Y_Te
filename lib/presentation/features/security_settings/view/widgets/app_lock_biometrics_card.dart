import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../common_widgets/layout/app_layout.dart';
import '../../viewmodel/security_settings_state.dart';

/// Cụm Khóa Ứng Dụng & Sinh Trắc Học thoáng đãng:
/// Bỏ các đường Divider rườm rà, dùng khoảng thở 16px và thanh chọn thời gian khóa gọn gàng.
class AppLockBiometricsCard extends StatelessWidget {
  final SecuritySettingsState state;
  final ValueChanged<bool> onToggleBiometrics;
  final VoidCallback onChangePin;
  final ValueChanged<AutoLockTimeout> onSelectTimeout;
  final VoidCallback? onLockNow;

  const AppLockBiometricsCard({
    super.key,
    required this.state,
    required this.onToggleBiometrics,
    required this.onChangePin,
    required this.onSelectTimeout,
    this.onLockNow,
  });

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: 'Khóa Ứng Dụng & Sinh Trắc Học',
      iconAsset: 'assets/icons/ic_sec_app_lock_cat.svg',
      titleColor: AppColors.textPrimaryLight,
      bottomSpacing: 0,
      trailing: onLockNow != null
          ? InkWell(
              onTap: onLockNow,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: AppColors.secOlive,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Khóa ngay',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secOlive,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      child: CleanCard(
        borderColor: AppColors.secCardBorder,
        padding: const EdgeInsets.all(AppLayoutTokens.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Toggle Face ID / Vân tay
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.secItemBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'assets/icons/ic_sec_face_id.svg',
                    width: 19,
                    height: 19,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Khóa bằng Face ID / Vân tay',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Xác thực nhanh khi mở ứng dụng',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secOliveMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: state.isBiometricLockEnabled,
                  onChanged: onToggleBiometrics,
                  activeTrackColor: AppColors.secToggleActive,
                  activeThumbColor: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 2. PIN Code Row
            InkWell(
              onTap: onChangePin,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.secItemBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        'assets/icons/ic_sec_pin_code.svg',
                        width: 19,
                        height: 15,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mã PIN bảo mật 6 chữ số',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Dự phòng khi không dùng sinh trắc học',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secOliveMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      state.maskedPin,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: AppColors.secOliveMuted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    SvgPicture.asset(
                      'assets/icons/ic_sec_chevron_right.svg',
                      width: 8,
                      height: 12,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 3. Auto-lock timer gọn ngang
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    'Tự động khóa ứng dụng',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.secItemBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTimeoutSegment(
                        label: 'TỨC THÌ',
                        isSelected: state.autoLockTimeout ==
                            AutoLockTimeout.immediate,
                        onTap: () =>
                            onSelectTimeout(AutoLockTimeout.immediate),
                      ),
                      const SizedBox(width: 4),
                      _buildTimeoutSegment(
                        label: 'SAU 1 PHÚT',
                        isSelected: state.autoLockTimeout ==
                            AutoLockTimeout.oneMinute,
                        onTap: () =>
                            onSelectTimeout(AutoLockTimeout.oneMinute),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeoutSegment({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceLight : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(
                  color: AppColors.secOlive.withValues(alpha: 0.25),
                )
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppColors.secOlive : AppColors.secOliveMuted,
          ),
        ),
      ),
    );
  }
}
