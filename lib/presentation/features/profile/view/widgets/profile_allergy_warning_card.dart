import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../common_widgets/layout/app_layout.dart';
import '../../viewmodel/profile_state.dart';

/// Thẻ cảnh báo dị ứng tuân thủ 3-Point Rule:
/// Mặt ngoài hiển thị gọn Tên dị nguyên + Mức độ + tóm tắt 1 dòng;
/// Chạm vào mở BottomSheet xem chi tiết nhóm thuốc bao gồm và phản ứng lâm sàng.
class ProfileAllergyWarningCard extends StatelessWidget {
  const ProfileAllergyWarningCard({
    super.key,
    required this.allergies,
  });

  final List<AllergyItem> allergies;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppLayoutTokens.cardRadius),
        border: Border.all(color: AppColors.iceCardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.iceTextNavy.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppLayoutTokens.cardRadius - 1),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(
                color: AppColors.iceDangerText,
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.all(AppLayoutTokens.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/ic_prof_allergy_alert.svg',
                          width: 17,
                          height: 17,
                          colorFilter: const ColorFilter.mode(
                            AppColors.iceDangerText,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'Tiền sử Dị ứng',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.iceTextNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${allergies.length} dị nguyên',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.iceDangerText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (allergies.isEmpty)
                const Text(
                  'Chưa ghi nhận dị ứng thuốc hoặc thức ăn.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.iceTextMuted,
                  ),
                )
              else
                for (int i = 0; i < allergies.length; i++) ...[
                  _AllergyCompactRow(
                    item: allergies[i],
                    onTap: () => _showAllergyDetailSheet(context, allergies[i]),
                  ),
                  if (i < allergies.length - 1) const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAllergyDetailSheet(BuildContext context, AllergyItem item) {
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
              title: item.title,
              subtitle: 'Cảnh báo dị ứng trước điều trị',
              icon: Icons.warning_amber_rounded,
              iconColor: AppColors.iceDangerText,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: item.isHighRisk
                      ? AppColors.iceDangerText
                      : AppColors.iceAccentCream,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.severityLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: item.isHighRisk
                        ? Colors.white
                        : AppColors.iceTextBrownDark,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            CleanCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.includes != null && item.includes!.isNotEmpty) ...[
                    const Text(
                      'NHÓM DỊ NGUYÊN BAO GỒM',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: AppColors.iceTextMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.includes!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.iceTextNavy,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  const Text(
                    'PHẢN ỨNG GHI NHẬN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: AppColors.iceTextMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.reaction,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: item.isHighRisk
                          ? AppColors.iceDangerText
                          : AppColors.iceTextSlate,
                      height: 1.4,
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
}

class _AllergyCompactRow extends StatelessWidget {
  const _AllergyCompactRow({
    required this.item,
    required this.onTap,
  });

  final AllergyItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = item.isHighRisk
        ? AppColors.iceDangerBg.withValues(alpha: 0.35)
        : AppColors.surfaceCream;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              SvgPicture.asset(
                item.iconAsset,
                width: 16,
                height: 16,
                colorFilter: ColorFilter.mode(
                  item.isHighRisk
                      ? AppColors.iceDangerText
                      : AppColors.iceTextBrownDark,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: item.isHighRisk
                            ? AppColors.iceDangerText
                            : AppColors.iceTextNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.reaction,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.iceTextSlate,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.isHighRisk
                      ? AppColors.iceDangerText
                      : AppColors.iceAccentCream,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.severityLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: item.isHighRisk
                        ? AppColors.surfaceLight
                        : AppColors.iceTextBrownDark,
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
