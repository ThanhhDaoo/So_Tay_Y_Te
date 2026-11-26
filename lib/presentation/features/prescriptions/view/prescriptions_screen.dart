import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common_widgets/layout/app_layout.dart';
import '../../../routes/app_routes.dart';
import '../../main_shell/view/main_shell_screen.dart';
import '../../emergency_card/view/widgets/ice_bottom_nav_bar.dart';
import '../viewmodel/prescriptions_viewmodel.dart';
import 'widgets/prescription_ocr_result_modal.dart';
import 'widgets/rx_active_plan_card.dart';
import 'widgets/rx_adherence_summary_card.dart';
import 'widgets/rx_dose_slot_card.dart';
import 'widgets/rx_header.dart';
import 'widgets/rx_pharmacist_advice_card.dart';
import 'widgets/rx_quick_actions_row.dart';

/// Màn hình Quản Lý Toa Thuốc & Lịch Uống theo kiến trúc MVVM.
class PrescriptionsScreen extends StatefulWidget {
  final bool showBottomNav;
  final PrescriptionsViewModel? viewModel;

  const PrescriptionsScreen({
    super.key,
    this.showBottomNav = true,
    this.viewModel,
  });

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  late final PrescriptionsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = (widget.viewModel ?? PrescriptionsViewModel())
      ..addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel
      ..removeListener(_onViewModelChanged)
      ..dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    final message = _viewModel.state.lastActionMessage;
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.rxOlive,
          behavior: SnackBarBehavior.floating,
        ),
      );
    _viewModel.clearActionMessage();
  }

  void _onNavTabSelected(int index) {
    if (index == 1) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainShellScreen(initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final now = DateTime.now();

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final state = _viewModel.state;

        return Scaffold(
          backgroundColor: AppColors.rxBackground,
          extendBody: true,
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              ListView(
                padding: EdgeInsets.only(
                  top: topPadding + 78,
                  bottom: bottomPadding + 104,
                  left: AppLayoutTokens.screenPadding,
                  right: AppLayoutTokens.screenPadding,
                ),
                children: [
                  // Cụm 1: Tóm tắt tuân thủ & Thao tác nhanh
                  RxAdherenceSummaryCard(
                    dayTitle: state.dayTitle,
                    planSubtitle: state.planSubtitle,
                    completedCount: state.completedCount,
                    totalCount: state.totalCount,
                    adherencePercent: state.adherencePercent,
                    nextDoseHighlight: state.nextDoseHighlight,
                  ),
                  const SizedBox(height: AppLayoutTokens.cardGap),
                  RxQuickActionsRow(
                    onAddPrescription: () =>
                        Navigator.pushNamed(context, AppRoutes.addRecord),
                    onScanOcr: () {
                      PrescriptionOcrResultModal.show(
                        context,
                        onApplyResult: (result) async {
                          await _viewModel.saveOcrPrescription(result);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _viewModel.testSendInstantReminder,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_active_outlined,
                            size: 15,
                            color: AppColors.rxOlive,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Bấm để thử chuông báo thức uống thuốc ngay lập tức',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.iceTextMuted,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: AppColors.iceTextMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Cụm 2: Lịch nhắc thuốc hôm nay (Trọng tâm màn hình)
                  SectionContainer(
                    title: 'Lịch nhắc thuốc hôm nay',
                    iconAsset: 'assets/icons/ic_rx_clock_schedule.svg',
                    bottomSpacing: AppLayoutTokens.sectionGap,
                    trailing: Text(
                      '${now.day}/${now.month}/${now.year}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.iceTextMuted,
                      ),
                    ),
                    child: state.slots.isEmpty
                        ? CleanCard(
                            borderColor: AppColors.rxBorder,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 28,
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.rxOlive
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.notifications_off_outlined,
                                    size: 32,
                                    color: AppColors.rxOlive,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Chưa Có Đơn Thuốc Nào',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.iceTextNavy,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Bạn chưa có lịch nhắc uống thuốc đang hoạt động. Mọi thông báo nhắc lịch cũ đã được tắt.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.iceTextSlate,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: _viewModel.clearAllReminders,
                                  icon: const Icon(
                                    Icons.notifications_off_outlined,
                                    size: 16,
                                    color: AppColors.rxOlive,
                                  ),
                                  label: const Text(
                                    'Hủy sạch chuông thông báo cũ',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.rxOlive,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: AppColors.rxBorder,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              for (int i = 0; i < state.slots.length; i++) ...[
                                RxDoseSlotCard(
                                  slot: state.slots[i],
                                  onMarkTaken: () => _viewModel
                                      .markDoseTaken(state.slots[i].id),
                                  onSnooze: () =>
                                      _viewModel.snoozeDose(state.slots[i].id),
                                ),
                                if (i < state.slots.length - 1)
                                  const SizedBox(
                                    height: AppLayoutTokens.cardGap,
                                  ),
                              ],
                            ],
                          ),
                  ),

                  // Cụm 3: Đơn thuốc đang điều trị (gộp Lời dặn dược sĩ & chi phí vào BottomSheet Chi tiết)
                  if (state.activePlan != null)
                    RxActivePlanCard(
                      plan: state.activePlan!,
                      pharmacistAdvice: state.pharmacistAdvice,
                      onDetailTap: () => _viewModel.notifyUser(
                        'Đang xem chi tiết đơn thuốc: ${state.activePlan!.title}',
                      ),
                    )
                  else if (state.pharmacistAdvice != null)
                    RxPharmacistAdviceCard(advice: state.pharmacistAdvice!),
                ],
              ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: RxHeader(),
              ),
              if (widget.showBottomNav)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: IceBottomNavBar(
                    selectedIndex: 1,
                    onSelectTab: _onNavTabSelected,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
