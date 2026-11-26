import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../common_widgets/layout/app_layout.dart';
import '../../viewmodel/prescriptions_state.dart';
import 'rx_pharmacist_advice_card.dart';

/// Thẻ đơn thuốc đang điều trị tinh gọn theo 3-Point Rule:
/// Mặt ngoài hiển thị (1) Tên phác đồ + Trạng thái, (2) Bác sĩ/phác đồ, (3) Thanh tiến độ ngày.
/// Các thông tin phụ (Nhà thuốc, Tổng chi phí, Ngày bắt đầu/kết thúc, Lời dặn dược sĩ)
/// được đưa vào BottomSheet khi bấm "Chi tiết".
class RxActivePlanCard extends StatelessWidget {
  final ActiveTreatmentPlan plan;
  final VoidCallback onDetailTap;
  final String? pharmacistAdvice;

  const RxActivePlanCard({
    super.key,
    required this.plan,
    required this.onDetailTap,
    this.pharmacistAdvice,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (plan.currentDay / plan.totalDays).clamp(0.0, 1.0);

    return SectionContainer(
      title: 'Đơn thuốc đang điều trị',
      iconAsset: 'assets/icons/ic_rx_active_plan.svg',
      bottomSpacing: 0,
      trailing: InkWell(
        onTap: () => _openPlanDetailSheet(context),
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            'Chi tiết ›',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.rxOlive,
            ),
          ),
        ),
      ),
      child: CleanCard(
        onTap: () => _openPlanDetailSheet(context),
        borderColor: AppColors.rxBorder,
        padding: const EdgeInsets.all(AppLayoutTokens.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Điểm 1: Tên phác đồ + Trạng thái
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    plan.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.iceTextNavy,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.rxBadgeCream,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    plan.statusLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textWarmBrown,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Điểm 2: Bác sĩ / Phác đồ ngắn gọn 1 dòng
            Text(
              plan.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.iceTextMuted,
              ),
            ),
            const SizedBox(height: 14),

            // Điểm 3: Tiến độ điều trị trực quan
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tiến độ liệu trình',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.iceTextSlate,
                  ),
                ),
                Text(
                  'Ngày ${plan.currentDay} / ${plan.totalDays}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.rxOlive,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: AppColors.rxProgressTrack,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.rxOlive,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPlanDetailSheet(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          AppLayoutTokens.screenPadding,
          12,
          AppLayoutTokens.screenPadding,
          bottomPadding + 24,
        ),
        decoration: const BoxDecoration(
          color: AppColors.rxBackground,
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
                  color: AppColors.rxBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SectionHeader(
              title: plan.title,
              subtitle: plan.subtitle,
              iconAsset: 'assets/icons/ic_rx_active_plan.svg',
              trailing: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.iceTextMuted,
                ),
              ),
            ),
            const SizedBox(height: 14),
            CleanCard(
              borderColor: AppColors.rxBorder,
              child: Column(
                children: [
                  KeyValueRow(label: 'Trạng thái', value: plan.statusLabel),
                  KeyValueRow(
                    label: 'Tiến độ điều trị',
                    value: 'Ngày thứ ${plan.currentDay} / ${plan.totalDays} ngày',
                  ),
                  KeyValueRow(label: 'Ngày bắt đầu', value: plan.startDate),
                  KeyValueRow(label: 'Dự kiến hoàn tất', value: plan.endDate),
                  KeyValueRow(label: 'Nhà thuốc cấp phát', value: plan.pharmacyName),
                  KeyValueRow(
                    label: 'Tổng chi phí đơn',
                    value: plan.totalCost,
                    valueWeight: FontWeight.w700,
                  ),
                ],
              ),
            ),
            if (pharmacistAdvice != null &&
                pharmacistAdvice!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              RxPharmacistAdviceCard(advice: pharmacistAdvice!),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.rxOlive,
                  side: const BorderSide(color: AppColors.rxBorder),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  onDetailTap();
                },
                icon: SvgPicture.asset(
                  'assets/icons/ic_rx_pharmacy.svg',
                  width: 14,
                  height: 14,
                ),
                label: const Text(
                  'Xác nhận đã xem phác đồ',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
