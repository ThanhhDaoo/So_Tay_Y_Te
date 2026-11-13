import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../main_shell/view/main_shell_screen.dart';
import '../../emergency_card/view/widgets/ice_bottom_nav_bar.dart';
import '../viewmodel/timeline_state.dart';
import '../viewmodel/timeline_viewmodel.dart';
import 'widgets/timeline_header.dart';
import 'widgets/timeline_record_card.dart';
import 'widgets/timeline_search_filter_bar.dart';
import 'widgets/timeline_sticky_fab.dart';
import 'widgets/timeline_vitals_bento.dart';

/// Màn hình Dòng Thời Gian Bệnh Án (Life Timeline) theo kiến trúc MVVM.
class TimelineScreen extends StatefulWidget {
  final bool showBottomNav;

  const TimelineScreen({super.key, this.showBottomNav = true});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  late final TimelineViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TimelineViewModel()..addListener(_onViewModelChanged);
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
          backgroundColor: AppColors.timelineOlive,
          behavior: SnackBarBehavior.floating,
        ),
      );
    _viewModel.clearActionMessage();
  }

  void _onNavTabSelected(int index) {
    if (index == 0) return;
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

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final state = _viewModel.state;
        final records = state.filteredRecords;

        return Scaffold(
          backgroundColor: AppColors.iceBackground,
          extendBody: true,
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              ListView(
                padding: EdgeInsets.only(
                  top: topPadding + 74,
                  bottom: bottomPadding + 148,
                  left: 16,
                  right: 16,
                ),
                children: [
                  TimelineSearchFilterBar(
                    controller: _viewModel.searchController,
                    onSearchChanged: _viewModel.updateSearchQuery,
                    onFilterTap: () => _viewModel.notifyUser(
                      'Đang lọc theo: ${state.selectedFilterId}',
                    ),
                    filters: state.filters,
                    selectedFilterId: state.selectedFilterId,
                    onSelectFilter: _viewModel.selectFilter,
                  ),
                  const SizedBox(height: 16),
                  TimelineVitalsBento(
                    onViewReports: () =>
                        Navigator.pushNamed(context, AppRoutes.vitalReports),
                  ),
                  const SizedBox(height: 18),
                  _buildTimelineSectionHeader(),
                  const SizedBox(height: 12),
                  _buildChronologicalSpine(records),
                ],
              ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: TimelineHeader(),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: bottomPadding + 74,
                child: TimelineStickyFab(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.addRecord),
                ),
              ),
              if (widget.showBottomNav)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: IceBottomNavBar(
                    selectedIndex: 0,
                    onSelectTab: _onNavTabSelected,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/ic_timeline_history.svg',
                width: 15,
                height: 16.67,
              ),
              const SizedBox(width: 8),
              const Text(
                'Dòng thời gian bệnh án',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.iceTextNavy,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.iceAccentCream,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Năm 2024',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.44,
                color: AppColors.timelineBadgeBrown,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChronologicalSpine(List<TimelineRecordItem> records) {
    if (records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.timelineCardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Không tìm thấy đợt khám phù hợp.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.iceTextSlate),
        ),
      );
    }

    return Stack(
      children: [
        Positioned(
          left: 10,
          top: 12,
          bottom: 16,
          width: 2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Image.asset(
              'assets/images/img_timeline_spine.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Column(
            children: [
              for (int i = 0; i < records.length; i++) ...[
                if (i > 0 && records[i].year != records[i - 1].year) ...[
                  _buildYearSeparator(records[i].year),
                  const SizedBox(height: 12),
                ],
                TimelineRecordCard(
                  record: records[i],
                  onOpenDetail: () => Navigator.pushNamed(
                    context,
                    AppRoutes.recordDetail,
                    arguments: records[i].id,
                  ),
                  onViewAllDocs: () =>
                      Navigator.pushNamed(context, AppRoutes.documents),
                  onViewPrescription: () =>
                      Navigator.pushNamed(context, AppRoutes.prescriptions),
                ),
                if (i < records.length - 1) const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildYearSeparator(int year) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.timelineChipBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Năm $year',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.44,
                color: AppColors.iceTextSlate,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.timelineChipBg,
            ),
          ),
        ],
      ),
    );
  }
}
