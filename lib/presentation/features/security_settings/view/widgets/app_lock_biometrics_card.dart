import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../viewmodel/security_settings_state.dart';

class AppLockBiometricsCard extends StatelessWidget {
  final SecuritySettingsState state;
  final ValueChanged<bool> onToggleBiometrics;
  final VoidCallback onChangePin;
  final ValueChanged<AutoLockTimeout> onSelectTimeout;

  const AppLockBiometricsCard({
    super.key,
    required this.state,
    required this.onToggleBiometrics,
    required this.onChangePin,
    required this.onSelectTimeout,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/ic_sec_app_lock_cat.svg',
                width: 16,
                height: 17,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Khóa Ứng Dụng & Sinh Trắc Học',
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
              // 1. Toggle Face ID / Vân tay
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.secItemBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: SvgPicture.asset(
                            'assets/icons/ic_sec_face_id.svg',
                            width: 20,
                            height: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Khóa bằng Face ID / Vân tay',
                                style: AppTypography.body.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimaryLight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Yêu cầu nhận diện mỗi khi mở ứng dụng',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 11.5,
                                  color: AppColors.secOliveMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch.adaptive(
                    value: state.isBiometricLockEnabled,
                    onChanged: onToggleBiometrics,
                    activeTrackColor: AppColors.secToggleActive,
                    activeThumbColor: Colors.white,
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: AppColors.secItemBg),
              ),

              // 2. PIN Code Row
              GestureDetector(
                onTap: onChangePin,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.secItemBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: SvgPicture.asset(
                              'assets/icons/ic_sec_pin_code.svg',
                              width: 20,
                              height: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mã PIN bảo mật 6 chữ số',
                                  style: AppTypography.body.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimaryLight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Mã dự phòng khẩn cấp khi cảm biến lỗi',
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 11.5,
                                    color: AppColors.secOliveMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.maskedPin,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
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
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: AppColors.secItemBg),
              ),

              // 3. Radio Selection: Auto-lock timer
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/ic_sec_auto_lock_timer.svg',
                        width: 14,
                        height: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tự động khóa ứng dụng',
                        style: AppTypography.body.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRadioOptionCard(
                          label: 'TỨC THÌ',
                          description: 'Ngay khi thoát ứng dụng',
                          isSelected: state.autoLockTimeout == AutoLockTimeout.immediate,
                          onTap: () => onSelectTimeout(AutoLockTimeout.immediate),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildRadioOptionCard(
                          label: 'SAU 1 PHÚT',
                          description: 'Tiện dụng khi tra cứu',
                          isSelected: state.autoLockTimeout == AutoLockTimeout.oneMinute,
                          onTap: () => onSelectTimeout(AutoLockTimeout.oneMinute),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRadioOptionCard({
    required String label,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secRadioSelectedBg : AppColors.secItemBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.secOlive.withValues(alpha: 0.3) : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.44,
                    color: isSelected ? AppColors.secOlive : AppColors.secOliveMuted,
                  ),
                ),
                SvgPicture.asset(
                  isSelected
                      ? 'assets/icons/ic_sec_radio_checked.svg'
                      : 'assets/icons/ic_sec_radio_unchecked.svg',
                  width: 15,
                  height: 15,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: AppTypography.caption.copyWith(
                fontSize: 11.5,
                color: AppColors.secOliveMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
