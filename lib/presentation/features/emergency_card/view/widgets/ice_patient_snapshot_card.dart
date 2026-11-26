import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/safe_avatar_image.dart';
import '../../../../common_widgets/layout/app_layout.dart';
import '../../viewmodel/emergency_card_state.dart';

/// Thẻ định danh bệnh nhân cấp cứu tuân thủ 3-Point Rule:
/// 1. Ảnh & Họ tên bệnh nhân + Tuổi/Giới
/// 2. Nhóm máu & Yếu tố Rh nổi bật lớn
/// 3. Dòng tóm tắt thể trạng 1 dòng (chạm để mở chi tiết Chiều cao, Cân nặng, Hiến tạng).
class IcePatientSnapshotCard extends StatelessWidget {
  final PatientSnapshotInfo patient;

  const IcePatientSnapshotCard({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return CleanCard(
      onTap: () => _showPatientBiometricsSheet(context),
      padding: const EdgeInsets.all(AppLayoutTokens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipOval(
                    child: buildSafeAvatarImage(
                      imageSource: patient.avatarAsset,
                      fallbackAsset: 'assets/images/img_patient_avatar.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.iceOlive,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        'assets/icons/ic_patient_verified.svg',
                        width: 10.5,
                        height: 10.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.fullName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.iceTextNavy,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      patient.demographics,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.iceTextSlate,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                constraints: const BoxConstraints(minWidth: 78),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.iceAccentCream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.iceBorderCream),
                ),
                child: Column(
                  children: [
                    const Text(
                      'NHÓM MÁU',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textWarmBrown,
                      ),
                    ),
                    Text(
                      patient.bloodType,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: AppColors.iceTextBrownDark,
                        height: 1.15,
                      ),
                    ),
                    Text(
                      patient.rhFactor,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.iceOlive,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.iceMetricBox,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Cao ${patient.height} • Nặng ${patient.weight} • Hiến tạng: ${patient.organDonorStatus}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.iceTextSlate,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.iceOlive,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPatientBiometricsSheet(BuildContext context) {
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
          color: AppColors.iceBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.iceCardBorder,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            SectionHeader(
              title: patient.fullName,
              subtitle: 'Thông số sinh trắc & Hiến tạng cấp cứu',
              icon: Icons.person_outline_rounded,
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
                  KeyValueRow(label: 'Nhân khẩu học', value: patient.demographics),
                  KeyValueRow(
                    label: 'Nhóm máu',
                    value: '${patient.bloodType} (${patient.rhFactor})',
                    valueColor: AppColors.iceDangerText,
                  ),
                  KeyValueRow(label: 'Chiều cao', value: patient.height),
                  KeyValueRow(label: 'Cân nặng', value: patient.weight),
                  KeyValueRow(
                    label: 'Đăng ký hiến tạng',
                    value: patient.organDonorStatus,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
