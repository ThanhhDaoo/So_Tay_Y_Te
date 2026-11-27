import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../domain/entities/medication_popup_reminder.dart';
import '../../../../common_widgets/senior_40plus/senior_ui_kit.dart';

/// Popup nhắc uống thuốc thiết kế theo chuẩn y khoa MedVault (Olive trầm + Kem ấm):
/// Tinh tế, rõ nét, dùng icon SVG y tế gốc thay vì hộp màu sặc sỡ.
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: AppColors.iceBackground,
        clipBehavior: Clip.antiAlias,
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
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Olive trầm đồng bộ với IceEmergencyBanner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.iceBannerStart, AppColors.iceBannerEnd],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.iceAccentCream.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'assets/icons/ic_rx_med_bottle.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      AppColors.iceAccentCream,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NHẮC UỐNG THUỐC ĐÚNG GIỜ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.65,
                          color: AppColors.iceAccentCream,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Nhắc Uống Thuốc • ${reminder.slotTitle}',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 16,
                            color: AppColors.iceAccentCream,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Khung giờ: ${reminder.timeLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFE5E2DA),
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

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < reminder.medicines.length; i++) ...[
                    _MedEditorialRow(medicine: reminder.medicines[i]),
                    if (i < reminder.medicines.length - 1)
                      const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
            child: Column(
              children: [
                SeniorActionButton(
                  label: 'Đã uống xong cữ này',
                  icon: Icons.check_rounded,
                  variant: SeniorButtonVariant.callNow,
                  minHeight: 54,
                  onPressed: onMarkTaken,
                ),
                const SizedBox(height: 10),
                SeniorActionButton(
                  label: 'Nhắc lại sau (15 phút)',
                  icon: Icons.snooze_outlined,
                  variant: SeniorButtonVariant.secondaryOutline,
                  minHeight: 52,
                  onPressed: onSnoozeLater,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MedEditorialRow extends StatelessWidget {
  final PopupMedicineDetail medicine;

  const _MedEditorialRow({required this.medicine});

  String _formLabel(PillVisualType type) {
    switch (type) {
      case PillVisualType.capsule:
        return 'Viên nang';
      case PillVisualType.sachet:
        return 'Gói uống';
      case PillVisualType.syrupBottle:
        return 'Dung dịch';
      case PillVisualType.tablet:
        return 'Viên nén';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.iceCardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.iceSecondaryCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SvgPicture.asset(
                  'assets/icons/ic_prescription_pill.svg',
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(
                    AppColors.iceOlive,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _formLabel(medicine.visualType),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.iceOliveDark,
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
                    fontSize: 17.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.iceTextNavy,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Liều dùng: ${medicine.dosage}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.reportTeal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  medicine.mealInstruction,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.iceTextSlate,
                    height: 1.38,
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
