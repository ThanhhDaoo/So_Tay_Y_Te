import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../emergency_card/view/widgets/ice_bottom_nav_bar.dart';
import '../viewmodel/prescriptions_viewmodel.dart';
import 'widgets/rx_active_plan_card.dart';
import 'widgets/rx_adherence_summary_card.dart';
import 'widgets/rx_dose_slot_card.dart';
import 'widgets/rx_header.dart';
import 'widgets/rx_pharmacist_advice_card.dart';
import 'widgets/rx_quick_actions_row.dart';

/// Màn hình Quản Lý Toa Thuốc & Lịch Uống theo kiến trúc MVVM.
class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  late final PrescriptionsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PrescriptionsViewModel()..addListener(_onViewModelChanged);
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
    if (index == 0) {
      Navigator.pushReplacementNamed(context, AppRoutes.timeline);
      return;
    }
    if (index == 2) {
      Navigator.pushReplacementNamed(context, AppRoutes.emergencyCard);
      return;
    }
    _viewModel.notifyUser('Tính năng đang được phát triển');
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

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
                  bottom: bottomPadding + 96,
                  left: 16,
                  right: 16,
                ),
                children: [
                  RxAdherenceSummaryCard(
                    dayTitle: state.dayTitle,
                    planSubtitle: state.planSubtitle,
                    completedCount: state.completedCount,
                    totalCount: state.totalCount,
                    adherencePercent: state.adherencePercent,
                    nextDoseHighlight: state.nextDoseHighlight,
                  ),
                  const SizedBox(height: 16),
                  RxQuickActionsRow(
                    onAddPrescription: () =>
                        Navigator.pushNamed(context, AppRoutes.addRecord),
                    onScanOcr: () =>
                        Navigator.pushNamed(context, AppRoutes.paywall),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/ic_rx_clock_schedule.svg',
                            width: 16.67,
                            height: 16.67,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Lịch nhắc thuốc hôm nay',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.iceTextNavy,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        '22 Tháng 4, 2024',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.44,
                          color: AppColors.iceTextMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (int i = 0; i < state.slots.length; i++) ...[
                    RxDoseSlotCard(
                      slot: state.slots[i],
                      onMarkTaken: () =>
                          _viewModel.markDoseTaken(state.slots[i].id),
                      onSnooze: () => _viewModel.snoozeDose(state.slots[i].id),
                    ),
                    if (i < state.slots.length - 1) const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 24),
                  RxActivePlanCard(
                    plan: state.activePlan,
                    onDetailTap: () => _viewModel.notifyUser(
                      'Đang xem chi tiết đơn thuốc điều trị HP',
                    ),
                  ),
                  const SizedBox(height: 16),
                  RxPharmacistAdviceCard(advice: state.pharmacistAdvice),
                ],
              ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: RxHeader(),
              ),
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

