import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../viewmodel/timeline_state.dart';

/// Thanh tìm kiếm bệnh án và dải chip lọc nhanh theo danh mục.
class TimelineSearchFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterTap;
  final List<TimelineFilterCategory> filters;
  final String selectedFilterId;
  final ValueChanged<String> onSelectFilter;

  const TimelineSearchFilterBar({
    super.key,
    required this.controller,
    required this.onSearchChanged,
    required this.onFilterTap,
    required this.filters,
    required this.selectedFilterId,
    required this.onSelectFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.timelineInputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.iceCardBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              SvgPicture.asset(
                'assets/icons/ic_search.svg',
                width: 15,
                height: 15,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onSearchChanged,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.iceTextNavy,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Tìm theo bệnh, triệu chứng, bác sĩ...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.iceTextMuted,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onFilterTap,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: AppColors.timelineChipBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'assets/icons/ic_filter_tune.svg',
                    width: 13.5,
                    height: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 30,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = filters[index];
              final isSelected = item.id == selectedFilterId;
              final bgColor = isSelected
                  ? AppColors.timelineOlive
                  : AppColors.timelineCardBg;
              final textColor = isSelected
                  ? Colors.white
                  : (item.isDangerText
                        ? AppColors.iceDangerText
                        : (item.dotColor != null
                              ? AppColors.timelineTextWarm
                              : AppColors.iceTextSlate));

              return GestureDetector(
                onTap: () => onSelectFilter(item.id),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? 14 : 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(999),
                    border: isSelected
                        ? null
                        : Border.all(color: AppColors.iceCardBorder, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isSelected && item.dotColor != null) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: item.dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.44,
                          color: textColor,
                        ),
                      ),
                    ],
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

