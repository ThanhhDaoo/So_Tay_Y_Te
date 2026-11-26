import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../common_widgets/layout/app_layout.dart';
import '../../viewmodel/security_settings_state.dart';

/// Cụm Mã Hóa & Quyền Riêng Tư thoáng gọn (bỏ Divider thừa và rút gọn mô tả kỹ thuật).
class EncryptionPrivacyCard extends StatelessWidget {
  final SecuritySettingsState state;
  final VoidCallback onCopyUuid;
  final ValueChanged<bool> onTogglePrivacyScreen;

  const EncryptionPrivacyCard({
    super.key,
    required this.state,
    required this.onCopyUuid,
    required this.onTogglePrivacyScreen,
  });

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: 'Mã Hóa & Quyền Riêng Tư',
      iconAsset: 'assets/icons/ic_sec_encryption_cat.svg',
      titleColor: AppColors.textPrimaryLight,
      bottomSpacing: 0,
      child: CleanCard(
        borderColor: AppColors.secCardBorder,
        padding: const EdgeInsets.all(AppLayoutTokens.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Local Database & SQLCipher
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
                    'assets/icons/ic_sec_database.svg',
                    width: 18,
                    height: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cơ sở dữ liệu trên thiết bị',
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
                        'Lưu trữ ngoại tuyến khóa riêng nội bộ',
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secSqlCipherPillBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'SQLCipher 256-bit',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secOlive,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 2. Privacy screen in switcher
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
                    'assets/icons/ic_sec_blur_multitask.svg',
                    width: 20,
                    height: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ẩn xem trước trong Đa nhiệm',
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
                        'Làm mờ màn hình khi chuyển ứng dụng',
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
                  value: state.isPrivacyScreenInMultitaskEnabled,
                  onChanged: onTogglePrivacyScreen,
                  activeTrackColor: AppColors.secToggleActive,
                  activeThumbColor: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 3. Guest UUID gọn 1 chạm sao chép
            const Text(
              'Chế độ định danh vô danh (Guest UUID)',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.secOliveMuted,
              ),
            ),
            const SizedBox(height: 6),
            Material(
              color: AppColors.secItemBg,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: onCopyUuid,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          state.guestUuid,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secOlive,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SvgPicture.asset(
                        'assets/icons/ic_sec_copy_uuid.svg',
                        width: 15,
                        height: 17,
                      ),
                    ],
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
