import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../domain/entities/daily_health_task.dart';
import '../../../../../domain/entities/medication_popup_reminder.dart';
import '../../../../common_widgets/senior_40plus/senior_ui_kit.dart';

/// Khối Tiến độ thuốc & Việc cần làm hằng ngày gọn gàng, tỷ lệ chữ hài hòa.
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
      subtitle: 'Chạm vào từng việc bên dưới để đánh dấu hoàn thành',
      iconAsset: 'assets/icons/ic_rx_clock_schedule.svg',
      iconColor: AppColors.primary,
      trailing: SeniorLabeledIconButton(
        icon: Icons.add_rounded,
        label: 'Thêm việc',
        onTap: onAddCustomTask,
      ),
      child: Column(
        children: [
          SeniorCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 58,
                      height: 58,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 58,
                            height: 58,
                            child: CircularProgressIndicator(
                              value: medicationProgress.ratio,
                              strokeWidth: 5.5,
                              backgroundColor: AppColors.iceAccentCream,
                              color: medicationProgress.ratio >= 1.0
                                  ? AppColors.reportTeal
                                  : AppColors.primary,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Text(
                            '${medicationProgress.percent}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFeatures: [FontFeature.tabularFigures()],
                              color: AppColors.iceTextNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tiến độ uống thuốc hôm nay',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.iceTextMuted,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Đã uống ${medicationProgress.fractionLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              fontFeatures: [FontFeature.tabularFigures()],
                              color: AppColors.iceTextNavy,
                              height: 1.18,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            nextSlot != null
                                ? 'Cữ kế tiếp: ${nextSlot.slotTitle} • ${nextSlot.timeLabel}'
                                : 'Đã hoàn thành đủ các cữ thuốc trong ngày',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: nextSlot != null
                                  ? AppColors.primary
                                  : AppColors.reportTeal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SeniorActionButton(
                  label: nextSlot != null
                      ? 'Nhắc uống thuốc (${nextSlot.slotTitle})'
                      : 'Xem lại đơn thuốc hôm nay',
                  icon: Icons.notifications_none_rounded,
                  variant: nextSlot != null
                      ? SeniorButtonVariant.primary
                      : SeniorButtonVariant.secondaryOutline,
                  onPressed: onOpenMedicationPopup,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (tasks.isNotEmpty)
            SeniorCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (int i = 0; i < tasks.length; i++) ...[
                    _CleanChecklistRow(
                      task: tasks[i],
                      onTap: () => onToggleTask(tasks[i]),
                    ),
                    if (i < tasks.length - 1)
                      const Padding(
                        padding: EdgeInsets.only(left: 52, right: 14),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: done ? AppColors.reportTeal : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: done
                      ? AppColors.reportTeal
                      : AppColors.checkboxBorder,
                  width: 1.6,
                ),
              ),
              alignment: Alignment.center,
              child: done
                  ? const Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: done
                          ? AppColors.iceTextMuted
                          : AppColors.iceTextNavy,
                      decoration: done ? TextDecoration.lineThrough : null,
                      height: 1.28,
                    ),
                  ),
                  if (task.subtitle != null && task.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      task.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: AppColors.iceTextMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: done
                    ? AppColors.reportTealSoft
                    : AppColors.iceAccentCream,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                done
                    ? 'Đã xong'
                    : (task.timeLabel != null && task.timeLabel!.isNotEmpty
                        ? task.timeLabel!
                        : 'Chờ làm'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: done ? AppColors.reportTeal : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
