import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../viewmodel/documents_state.dart';

class DocumentFilterChips extends StatelessWidget {
  const DocumentFilterChips({
    super.key,
    required this.selectedCategory,
    required this.onSelectCategory,
    this.onFilterTap,
  });

  final DocumentCategory selectedCategory;
  final ValueChanged<DocumentCategory> onSelectCategory;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PHÂN LOẠI TÀI LIỆU',
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.55,
                color: const Color(0xFF3D4947),
              ),
            ),
            InkWell(
              onTap: onFilterTap,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/ic_doc_filter.svg',
                      width: 12,
                      height: 12,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF00685F),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Bộ lọc',
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.44,
                        color: const Color(0xFF00685F),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: DocumentCategory.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = DocumentCategory.values[index];
              final isSelected = cat == selectedCategory;

              return Material(
                color: isSelected ? AppColors.iceAccentCream : Colors.white,
                borderRadius: BorderRadius.circular(999),
                elevation: 1,
                shadowColor: const Color(0x0D000000),
                child: InkWell(
                  onTap: () => onSelectCategory(cat),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.iceAccentCream
                            : const Color(0xFFEAE5DB),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cat == DocumentCategory.all
                              ? '${cat.label} (${cat.count})'
                              : cat.label,
                          style: AppTypography.body.copyWith(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFF251A08)
                                : AppColors.iceTextNavy,
                          ),
                        ),
                        if (cat != DocumentCategory.all) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCE9FF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${cat.count}',
                              style: AppTypography.caption.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF3D4947),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

