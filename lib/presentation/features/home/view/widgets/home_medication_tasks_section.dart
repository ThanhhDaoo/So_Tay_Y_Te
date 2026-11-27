import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../domain/entities/daily_health_task.dart';
import '../../../../../domain/entities/medication_popup_reminder.dart';
import '../../../../common_widgets/senior_40plus/senior_ui_kit.dart';

/// Khối Tiến độ thuốc & Việc cần làm hằng ngày với thiết kế phẳng, tinh gọn chuẩn y tế.
class HomeMedicationTasksSection extends StatelessWidget {
  final TodayMedicationProgress medicationProgress;
  final List<DailyHealthTask> tasks;
  final VoidCallback onOpenMedicationPopup;
  final ValueChanged<DailyHealthTask> onToggleTask;
  final VoidCallback onAddCustomTask;

  const HomeMedicationTasksSection({
    super.key,
    required this.medicationProgress,
    required this.tasks,
    required this.onOpenMedicationPopup,
    required this.onToggleTask,
    required this.onAddCustomTask,
  });

  @override
  Widget build(BuildContext context) {
    final nextSlot = medicationProgress.nextPendingSlot;

    return SeniorSectionBlock(
      title: 'Tiến độ thuốc & Việc cần làm',
      subtitle: 'Chạm vào từng mục bên dưới để đánh dấu hoàn thành',
      iconAsset: 'assets/icons/ic_rx_clock_schedule.svg',
      iconColor: AppColors.iceOlive,
      trailing: SeniorLabeledIconButton(
        icon: Icons.add_rounded,
        label: 'Thêm việc',
        onTap: onAddCustomTask,
      ),
      child: Column(
        children: [
          // 1. Thẻ Tiến độ uống thuốc hôm nay
          SeniorCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 72,
                            height: 72,
                            child: CircularProgressIndicator(
                              value: medicationProgress.ratio,
                              strokeWidth: 6.5,
                              backgroundColor: AppColors.iceSecondaryCard,
                              color: AppColors.reportTeal,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Text(
                            '${medicationProgress.percent}%',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              fontFeatures: [FontFeature.tabularFigures()],
                              color: AppColors.iceTextNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LỊCH THUỐC HÔM NAY',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.55,
                              color: AppColors.iceTextMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Đã uống ${medicationProgress.fractionLabel}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.6,
                              fontFeatures: [FontFeature.tabularFigures()],
                              color: AppColors.iceTextNavy,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            nextSlot != null
                                ? 'Cữ kế tiếp: ${nextSlot.slotTitle} • ${nextSlot.timeLabel}'
                                : 'Đã hoàn thành đủ các cữ thuốc trong ngày',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: nextSlot != null
                                  ? AppColors.textWarmBrown
                                  : AppColors.reportTeal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SeniorActionButton(
                  label: nextSlot != null
                      ? 'Mở nhắc uống thuốc (${nextSlot.slotTitle})'
                      : 'Xem lại đơn thuốc hôm nay',
                  icon: Icons.notifications_none_rounded,
                  variant: nextSlot != null
                      ? SeniorButtonVariant.callNow
                      : SeniorButtonVariant.secondaryOutline,
                  onPressed: onOpenMedicationPopup,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Danh sách checklist việc cần làm gộp gọn trong 1 thẻ sạch sẽ (chia bằng đường kẻ mảnh)
          if (tasks.isNotEmpty)
            SeniorCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  for (int i = 0; i < tasks.length; i++) ...[
                    _CleanChecklistRow(
                      task: tasks[i],
                      onTap: () => onToggleTask(tasks[i]),
                    ),
                    if (i < tasks.length - 1)
                      const Padding(
                        padding: EdgeInsets.only(left: 60, right: 18),
                        child: Divider(height: 1, color: AppColors.divider),
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CleanChecklistRow extends StatelessWidget {
  final DailyHealthTask task;
  final VoidCallback onTap;

  const _CleanChecklistRow({
    required this.task,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final done = task.isCompleted;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: done ? AppColors.reportTeal : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: done
                        ? AppColors.reportTeal
                        : const Color(0xFFB5B8AE),
                    width: 1.8,
                  ),
                ),
                alignment: Alignment.center,
                child: done
                    ? SvgPicture.asset(
                        'assets/icons/ic_check.svg',
                        width: 13,
                        height: 13,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.15,
                      color: done
                          ? AppColors.iceTextMuted
                          : AppColors.iceTextNavy,
                      decoration: done ? TextDecoration.lineThrough : null,
                      height: 1.3,
                    ),
                  ),
                  if (task.subtitle != null && task.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      task.subtitle!,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                        color: AppColors.iceTextMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (task.timeLabel != null && task.timeLabel!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.iceSecondaryCard,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task.timeLabel!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: AppColors.iceOliveDark,
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
