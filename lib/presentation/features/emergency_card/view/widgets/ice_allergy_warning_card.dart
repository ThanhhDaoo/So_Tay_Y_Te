import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../common_widgets/layout/app_layout.dart';
import '../../viewmodel/emergency_card_state.dart';

/// Thẻ cảnh báo dị ứng thuốc nguy hiểm trên màn ICE:
/// Hiển thị nổi bật tên dị nguyên & mức độ, rút gọn mô tả dài còn 2 dòng và cho phép chạm xem toàn bộ.
class IceAllergyWarningCard extends StatelessWidget {
  final DrugAllergyWarning warning;

  const IceAllergyWarningCard({super.key, required this.warning});

  @override
  Widget build(BuildContext context) {
    final isSevere = warning.isSevere;

    return CleanCard(
      onTap: warning.description.trim().isNotEmpty
          ? () => _showFullAllergySheet(context)
          : null,
      backgroundColor: isSevere ? AppColors.iceAllergyBg : AppColors.surfaceLight,
      borderColor:
          isSevere ? AppColors.iceAllergyBorder : AppColors.iceCardBorder,
      padding: const EdgeInsets.all(AppLayoutTokens.cardPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSevere
                  ? AppColors.iceOlive
                  : AppColors.iceOlive.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isSevere
                ? SvgPicture.asset(
                    'assets/icons/ic_warning_triangle.svg',
                    width: 20,
                    height: 18,
                  )
                : const Icon(
                    Icons.shield_outlined,
                    color: AppColors.iceOlive,
                    size: 20,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        isSevere ? 'CẢNH BÁO DỊ ỨNG' : 'THÔNG TIN DỊ ỨNG',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: isSevere
                              ? AppColors.textWarmBrown
                              : AppColors.iceOlive,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: isSevere
                            ? AppColors.iceCriticalBadge
                            : AppColors.iceOlive.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        warning.severityBadge,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSevere ? Colors.white : AppColors.iceOlive,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  warning.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isSevere
                        ? AppColors.iceOliveDark
                        : AppColors.iceTextNavy,
                  ),
                ),
                if (warning.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    warning.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color:
                          isSevere ? AppColors.iceOlive : AppColors.iceTextSlate,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullAllergySheet(BuildContext context) {
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
              title: warning.title,
              subtitle: warning.severityBadge,
              icon: Icons.warning_amber_rounded,
              iconColor: AppColors.iceCriticalBadge,
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
              child: Text(
                warning.description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.iceTextNavy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
