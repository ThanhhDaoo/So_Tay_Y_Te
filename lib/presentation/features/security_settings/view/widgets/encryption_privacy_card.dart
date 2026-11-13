import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../viewmodel/security_settings_state.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/ic_sec_encryption_cat.svg',
                width: 14,
                height: 18,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Mã Hóa & Quyền Riêng Tư',
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
              // 1. Local Database & SQLCipher
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      'assets/icons/ic_sec_database.svg',
                      width: 18,
                      height: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(
                              'Cơ sở dữ liệu trên thiết bị',
                              style: AppTypography.body.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.secSqlCipherPillBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'SQLCipher 256-bit',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                  color: AppColors.secOlive,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Dữ liệu được lưu ngoại tuyến, mã hóa khóa riêng nội bộ không gửi qua máy chủ trung gian.',
                          style: AppTypography.caption.copyWith(
                            fontSize: 11.5,
                            color: AppColors.secOliveMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: AppColors.secItemBg),
              ),

              // 2. Guest UUID
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chế độ định danh vô danh (Guest UUID)',
                    style: AppTypography.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Định danh ngẫu nhiên, không liên kết danh tính số điện thoại',
                    style: AppTypography.caption.copyWith(
                      fontSize: 11.5,
                      color: AppColors.secOliveMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.secItemBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            state.guestUuid,
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.24,
                              color: AppColors.secOlive,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onCopyUuid,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: SvgPicture.asset(
                              'assets/icons/ic_sec_copy_uuid.svg',
                              width: 16,
                              height: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: AppColors.secItemBg),
              ),

              // 3. Toggle: Privacy screen in switcher
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
                            'assets/icons/ic_sec_blur_multitask.svg',
                            width: 22,
                            height: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ẩn xem trước trong Đa nhiệm',
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
                                'Làm mờ màn hình bảo vệ hồ sơ khi chuyển ứng dụng',
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
                    value: state.isPrivacyScreenInMultitaskEnabled,
                    onChanged: onTogglePrivacyScreen,
                    activeTrackColor: AppColors.secToggleActive,
                    activeThumbColor: Colors.white,
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
