import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../domain/entities/medication_popup_reminder.dart';
import '../../../../common_widgets/senior_40plus/senior_ui_kit.dart';

/// Popup nhắc uống thuốc trực quan cỡ lớn cho người trung niên & cao tuổi (40+):
/// Hiển thị tên thuốc, liều lượng, ảnh/hình minh họa viên thuốc & hộp thuốc rõ nét,
/// kèm 2 nút lớn: "Đã uống" (cập nhật tiến độ ngay) và "Nhắc lại sau".
class MedicationReminderPopup extends StatelessWidget {
  final MedicationPopupReminder reminder;
  final VoidCallback onMarkTaken;
  final VoidCallback onSnoozeLater;

  const MedicationReminderPopup({
    super.key,
    required this.reminder,
    required this.onMarkTaken,
    required this.onSnoozeLater,
  });

  static Future<void> show(
    BuildContext context, {
    required MedicationPopupReminder reminder,
    required VoidCallback onMarkTaken,
    required VoidCallback onSnoozeLater,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: MedicationReminderPopup(
          reminder: reminder,
          onMarkTaken: () {
            Navigator.of(ctx).pop();
            onMarkTaken();
          },
          onSnoozeLater: () {
            Navigator.of(ctx).pop();
            onSnoozeLater();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.86,
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner đầu Popup với chuông báo & giờ uống
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryPeach.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.iceBorderCream, width: 1.4),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.medication_liquid_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nhắc Uống Thuốc • ${reminder.slotTitle}',
                          style: const TextStyle(
                            fontSize: 19.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.iceTextNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_filled_rounded,
                              size: 20,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Khung giờ: ${reminder.timeLabel}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Danh sách thuốc cần uống:',
              style: TextStyle(
                fontSize: 17.5,
                fontWeight: FontWeight.w800,
                color: AppColors.iceTextNavy,
              ),
            ),
            const SizedBox(height: 10),

            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: reminder.medicines
                      .map((med) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PillVisualCard(medicine: med),
                          ))
                      .toList(),
                ),
              ),
            ),

            const SizedBox(height: 8),
            // 2 nút hành động lớn tối thiểu 54px - 56px
            SeniorActionButton(
              label: 'Đã uống xong cữ này',
              icon: Icons.check_circle_rounded,
              variant: SeniorButtonVariant.callNow,
              minHeight: 56,
              onPressed: onMarkTaken,
            ),
            const SizedBox(height: 12),
            SeniorActionButton(
              label: 'Nhắc lại sau (15 phút)',
              icon: Icons.snooze_rounded,
              variant: SeniorButtonVariant.secondaryOutline,
              minHeight: 54,
              onPressed: onSnoozeLater,
            ),
          ],
        ),
      ),
    );
  }
}

class _PillVisualCard extends StatelessWidget {
  final PopupMedicineDetail medicine;

  const _PillVisualCard({required this.medicine});

  (IconData, Color, String) _resolvePillIllustration(PillVisualType type) {
    switch (type) {
      case PillVisualType.capsule:
        return (
          Icons.medication_rounded,
          const Color(0xFFD96B27),
          'Viên nang',
        );
      case PillVisualType.sachet:
        return (
          Icons.inventory_2_rounded,
          const Color(0xFF2B6CB0),
          'Gói thuốc',
        );
      case PillVisualType.syrupBottle:
        return (
          Icons.science_rounded,
          const Color(0xFF00796B),
          'Ống / Lọ uống',
        );
      case PillVisualType.tablet:
        return (
          Icons.vaccines_rounded,
          const Color(0xFF4C6347),
          'Viên nén',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, tint, formLabel) = _resolvePillIllustration(medicine.visualType);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.rxBorder, width: 1.3),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hình minh họa viên thuốc / hộp thuốc trực quan kèm nhãn tiếng Việt
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tint.withValues(alpha: 0.35), width: 1.3),
            ),
            child: Column(
              children: [
                Icon(icon, size: 32, color: tint),
                const SizedBox(height: 4),
                Text(
                  formLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: tint,
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
                Text(
                  medicine.name,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.iceTextNavy,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Liều lượng: ${medicine.dosage}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: tint,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  medicine.mealInstruction,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.iceTextSlate,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
