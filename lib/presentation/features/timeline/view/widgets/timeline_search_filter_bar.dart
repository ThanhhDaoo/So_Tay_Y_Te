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
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.iceCardBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.iceTextNavy.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              SvgPicture.asset(
                'assets/icons/ic_search.svg',
                width: 16,
                height: 16,
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
                    hintText: 'Tìm bệnh án, bác sĩ, bệnh viện...',
                    hintStyle: TextStyle(
                      fontSize: 13.5,
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
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 34,
                  height: 34,
                  margin: const EdgeInsets.only(right: 7),
                  decoration: BoxDecoration(
                    color: AppColors.timelineInputBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'assets/icons/ic_filter_tune.svg',
                    width: 14,
                    height: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = filters[index];
              final isSelected = item.id == selectedFilterId;
              final bgColor = isSelected
                  ? AppColors.timelineOlive
                  : AppColors.surfaceLight;
              final textColor = isSelected
                  ? Colors.white
                  : (item.isDangerText
                        ? AppColors.iceDangerText
                        : (item.dotColor != null
                              ? AppColors.timelineTextWarm
                              : AppColors.iceTextSlate));

              return GestureDetector(
                onTap: () => onSelectFilter(item.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? 15 : 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(999),
                    border: isSelected
                        ? null
                        : Border.all(color: AppColors.iceCardBorder, width: 1),
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
                        const SizedBox(width: 6),
                      ],
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
