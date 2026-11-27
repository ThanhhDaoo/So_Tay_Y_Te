import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../domain/entities/daily_health_task.dart';
import '../../../../../domain/entities/medication_popup_reminder.dart';
import '../../../../common_widgets/senior_40plus/senior_ui_kit.dart';

/// Khối 3 trên Trang chủ:
/// - Hiển thị vòng tròn & thanh tiến độ uống thuốc hôm nay (cỡ 26px - 30px, VD: Đã uống 2/3 cữ).
/// - Nút mở nhanh Popup nhắc uống thuốc trực quan.
/// - Danh sách việc cần làm trong ngày dạng thẻ lớn bấm tick hoàn thành trực tiếp.
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

  IconData _taskIcon(HealthTaskCategory cat) {
    switch (cat) {
      case HealthTaskCategory.bloodPressure:
        return Icons.monitor_heart_rounded;
      case HealthTaskCategory.medication:
        return Icons.medication_rounded;
      case HealthTaskCategory.exercise:
        return Icons.directions_walk_rounded;
      case HealthTaskCategory.hydration:
        return Icons.local_drink_rounded;
      case HealthTaskCategory.custom:
        return Icons.task_alt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextSlot = medicationProgress.nextPendingSlot;

    return SeniorSectionBlock(
      title: 'Tiến độ thuốc & Việc cần làm',
      subtitle: 'Chạm trực tiếp vào từng thẻ bên dưới để đánh dấu hoàn thành',
      icon: Icons.fact_check_rounded,
      iconColor: SeniorTokens.callActionGreen,
      iconBgColor: SeniorTokens.callActionGreenSoft,
      trailing: SeniorLabeledIconButton(
        icon: Icons.add_task_rounded,
        label: 'Thêm việc',
        onTap: onAddCustomTask,
      ),
      child: Column(
        children: [
          // 1. Thẻ Vòng tròn & Thanh tiến độ uống thuốc hôm nay
          SeniorCard(
            padding: const EdgeInsets.all(20),
            backgroundColor: Colors.white,
            borderColor: AppColors.rxBorder,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 84,
                      height: 84,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 84,
                            height: 84,
                            child: CircularProgressIndicator(
                              value: medicationProgress.ratio,
                              strokeWidth: 9,
                              backgroundColor: AppColors.rxProgressTrack,
                              color: SeniorTokens.callActionGreen,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Text(
                            '${medicationProgress.percent}%',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
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
                            'Tiến độ uống thuốc hôm nay',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.iceTextSlate,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Đã uống ${medicationProgress.fractionLabel}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.iceTextNavy,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            nextSlot != null
                                ? 'Sắp tới: ${nextSlot.slotTitle} (${nextSlot.timeLabel})'
                                : 'Đã hoàn thành đủ tất cả các cữ thuốc hôm nay!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: nextSlot != null
                                  ? AppColors.accent
                                  : SeniorTokens.callActionGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: medicationProgress.ratio,
                    minHeight: 12,
                    backgroundColor: AppColors.rxProgressTrack,
                    color: SeniorTokens.callActionGreen,
                  ),
                ),
                const SizedBox(height: 16),
                SeniorActionButton(
                  label: nextSlot != null
                      ? 'Mở nhắc uống thuốc (${nextSlot.slotTitle})'
                      : 'Xem lại đơn thuốc đã uống hôm nay',
                  icon: Icons.notifications_active_rounded,
                  variant: nextSlot != null
                      ? SeniorButtonVariant.callNow
                      : SeniorButtonVariant.secondaryOutline,
                  onPressed: onOpenMedicationPopup,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Danh sách Việc cần làm trong ngày dạng thẻ lớn bấm tick trực tiếp
          for (int i = 0; i < tasks.length; i++) ...[
            _SeniorTaskCard(
              task: tasks[i],
              categoryIcon: _taskIcon(tasks[i].category),
              onTap: () => onToggleTask(tasks[i]),
            ),
            if (i < tasks.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _SeniorTaskCard extends StatelessWidget {
  final DailyHealthTask task;
  final IconData categoryIcon;
  final VoidCallback onTap;

  const _SeniorTaskCard({
    required this.task,
    required this.categoryIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final done = task.isCompleted;

    return SeniorCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      backgroundColor:
          done ? SeniorTokens.callActionGreenSoft.withValues(alpha: 0.6) : Colors.white,
      borderColor: done
          ? SeniorTokens.callActionGreen.withValues(alpha: 0.5)
          : AppColors.iceCardBorder,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ô tick tròn lớn 34px dễ nhìn & dễ bấm cho người cao tuổi
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: done ? SeniorTokens.callActionGreen : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: done
                    ? SeniorTokens.callActionGreen
                    : AppColors.checkboxBorder,
                width: 2.2,
              ),
            ),
            child: done
                ? const Icon(Icons.check_rounded, size: 24, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      categoryIcon,
                      size: 22,
                      color: done
                          ? SeniorTokens.callActionGreen
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    if (task.timeLabel != null && task.timeLabel!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCream,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.timeLabel!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      done ? 'Đã xong' : 'Cần làm',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: done
                            ? SeniorTokens.callActionGreen
                            : AppColors.iceTextSlate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.iceTextNavy,
                    decoration: done ? TextDecoration.lineThrough : null,
                    height: 1.25,
                  ),
                ),
                if (task.subtitle != null && task.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.subtitle!,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.iceTextSlate,
                      height: 1.3,
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
}
