import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/safe_avatar_image.dart';
import '../../../../common_widgets/layout/app_layout.dart';
import '../../viewmodel/profile_state.dart';

/// Thẻ định danh bệnh nhân gọn thoáng theo bố cục ngang (Horizontal Identity Card):
/// Giữ 3 điểm cốt lõi ở mặt ngoài (Vai trò, Họ tên + xác thực, Mã hồ sơ & Ngày sinh),
/// ẩn chi tiết hành chính phụ (BHYT, Khu vực, ICE) vào dòng mở nhanh BottomSheet.
class ProfilePatientHeroCard extends StatelessWidget {
  const ProfilePatientHeroCard({
    super.key,
    required this.profile,
    this.isPrimary = true,
    this.onEditTap,
    this.onDeleteTap,
    this.onPickAvatar,
  });

  final MemberMedicalProfile profile;
  final bool isPrimary;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onPickAvatar;

  @override
  Widget build(BuildContext context) {
    final cleanRegion = (profile.region.isNotEmpty &&
            !profile.region.contains('@') &&
            profile.region != 'Chưa cập nhật')
        ? profile.region
        : 'Chưa cập nhật';
    final hasIceContact =
        profile.contact.isNotEmpty && !profile.contact.contains('@');

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.iceBackground,
            AppColors.iceAccentCream,
          ],
        ),
        borderRadius: BorderRadius.circular(AppLayoutTokens.cardRadius),
        border: Border.all(
          color: AppColors.iceAccentCream.withValues(alpha: 0.75),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppLayoutTokens.cardRadius),
        child: Stack(
          children: [
            Positioned(
              right: -12,
              bottom: -14,
              child: Opacity(
                opacity: 0.07,
                child: SvgPicture.asset(
                  'assets/icons/ic_prof_shield_watermark.svg',
                  width: 92,
                  height: 92,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppLayoutTokens.heroCardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hàng trên: Badge vai trò + Nút Sửa / Xóa
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: isPrimary
                                ? AppColors.iceOlive.withValues(alpha: 0.14)
                                : const Color(0xFFE28743)
                                    .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isPrimary
                                ? 'HỒ SƠ GỐC'
                                : 'THÀNH VIÊN • ${profile.relationship.toUpperCase()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                              color: isPrimary
                                  ? AppColors.iceOlive
                                  : const Color(0xFFC05621),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onEditTap != null)
                            InkWell(
                              onTap: onEditTap,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.iceOlive
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 13.5,
                                      color: AppColors.iceOlive,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Sửa',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.iceOlive,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (!isPrimary && onDeleteTap != null) ...[
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: onDeleteTap,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  size: 15,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Trọng tâm định danh ngang: Ảnh 72px + Họ tên & 2 chỉ dấu cốt lõi
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: SizedBox(
                              width: 72,
                              height: 72,
                              child: buildSafeAvatarImage(
                                imageSource: profile.heroImageAsset,
                                fallbackAsset:
                                    'assets/images/img_profile_hero_portrait.png',
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                              ),
                            ),
                          ),
                          if (onPickAvatar != null)
                            Positioned(
                              bottom: -4,
                              right: -4,
                              child: Material(
                                color: AppColors.iceOlive,
                                shape: const CircleBorder(),
                                elevation: 2,
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: onPickAvatar,
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Icon(
                                      Icons.camera_alt,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    profile.fullName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.heading2.copyWith(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                      color: AppColors.iceTextNavy,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                SvgPicture.asset(
                                  'assets/icons/ic_prof_verified_user.svg',
                                  width: 16,
                                  height: 16,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Mã hồ sơ: ${profile.recordCode}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.iceTextSlate,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Ngày sinh: ${profile.dob}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.iceTextBrownDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Thanh mở nhanh chi tiết hành chính phụ (Progressive Disclosure)
                  Material(
                    color: AppColors.surfaceLight.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => _showAdministrativeDetailsSheet(
                        context,
                        cleanRegion: cleanRegion,
                        hasIceContact: hasIceContact,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${profile.bhytStatus} • $cleanRegion',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.iceTextBrownDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Chi tiết',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.iceOlive,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: AppColors.iceOlive,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdministrativeDetailsSheet(
    BuildContext context, {
    required String cleanRegion,
    required bool hasIceContact,
  }) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          AppLayoutTokens.screenPadding,
          12,
          AppLayoutTokens.screenPadding,
          bottomPadding + 24,
        ),
        decoration: const BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.iceCardBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SectionHeader(
              title: 'Thông tin hành chính & BHYT',
              subtitle: profile.fullName,
              icon: Icons.badge_outlined,
              trailing: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.iceTextMuted,
                ),
              ),
            ),
            const SizedBox(height: 12),
            CleanCard(
              child: Column(
                children: [
                  KeyValueRow(label: 'Mã hồ sơ', value: profile.recordCode),
                  KeyValueRow(
                    label: 'Vai trò hồ sơ',
                    value: isPrimary ? 'Hồ sơ gốc' : profile.relationship,
                  ),
                  KeyValueRow(label: 'Ngày sinh', value: profile.dob),
                  KeyValueRow(label: 'Giới tính', value: profile.gender),
                  KeyValueRow(label: 'Trạng thái BHYT', value: profile.bhytStatus),
                  KeyValueRow(label: 'Khu vực sinh sống', value: cleanRegion),
                  KeyValueRow(
                    label: 'Liên hệ khẩn cấp (ICE)',
                    value: hasIceContact ? profile.contact : 'Chưa cập nhật',
                  ),
                ],
              ),
            ),
            if (onEditTap != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.iceOlive,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    onEditTap!();
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text(
                    'Chỉnh sửa thông tin hồ sơ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
