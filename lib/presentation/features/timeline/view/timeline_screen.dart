import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common_widgets/layout/app_layout.dart';
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
  bool _isFabVisible = true;

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
        final activeYear =
            records.isNotEmpty ? records.first.year : DateTime.now().year;

        return Scaffold(
          backgroundColor: AppColors.iceBackground,
          extendBody: true,
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              NotificationListener<UserScrollNotification>(
                onNotification: (notification) {
                  if (notification.direction == ScrollDirection.reverse) {
                    if (_isFabVisible) {
                      setState(() => _isFabVisible = false);
                    }
                  } else if (notification.direction == ScrollDirection.forward) {
                    if (!_isFabVisible) {
                      setState(() => _isFabVisible = true);
                    }
                  }
                  return true;
                },
                child: ListView(
                  padding: EdgeInsets.only(
                    top: topPadding + 78,
                    bottom: bottomPadding + 152,
                    left: AppLayoutTokens.screenPadding,
                    right: AppLayoutTokens.screenPadding,
                  ),
                  children: [
                    // Cụm 1: Tìm kiếm & Lọc nhanh
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
                    const SizedBox(height: AppLayoutTokens.sectionGap),

                    // Cụm 2: Sinh hiệu mới nhất (2x2 Bento thoáng đãng)
                    TimelineVitalsBento(
                      bloodPressure: state.latestBloodPressure,
                      heartRate: state.latestHeartRate,
                      spo2: state.latestSpo2,
                      bloodSugar: state.latestBloodSugar,
                      onViewReports: () =>
                          Navigator.pushNamed(context, AppRoutes.vitalReports),
                    ),
                    const SizedBox(height: AppLayoutTokens.sectionGap),

                    // Cụm 3: Trục thời gian bệnh án
                    SectionContainer(
                      title: 'Dòng thời gian bệnh án',
                      iconAsset: 'assets/icons/ic_timeline_history.svg',
                      bottomSpacing: 0,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.iceAccentCream,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Năm $activeYear',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: AppColors.timelineBadgeBrown,
                          ),
                        ),
                      ),
                      child: _buildChronologicalSpine(
                        records,
                        hasUnfilteredRecords: state.records.isNotEmpty,
                      ),
                    ),
                  ],
                ),
              ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: TimelineHeader(),
              ),
              Positioned(
                right: AppLayoutTokens.screenPadding,
                bottom: bottomPadding + 76,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isFabVisible ? 1.0 : 0.0,
                    child: TimelineStickyFab(
                      onPressed: () async {
                        final res = await Navigator.pushNamed(
                          context,
                          AppRoutes.addRecord,
                        );
                        if (res == true) {
                          _viewModel.loadRecords();
                        }
                      },
                    ),
                  ),
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

  Widget _buildChronologicalSpine(
    List<TimelineRecordItem> records, {
    bool hasUnfilteredRecords = false,
  }) {
    if (records.isEmpty) {
      if (hasUnfilteredRecords) {
        return CleanCard(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.iceOlive.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 32,
                  color: AppColors.iceOlive,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Không tìm thấy bệnh án phù hợp',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.iceTextNavy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Không có đợt khám nào khớp với từ khóa hoặc bộ lọc hiện tại.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.iceTextSlate,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.iceOlive,
                  side: const BorderSide(color: AppColors.iceOlive),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: const Text(
                  'Xóa bộ lọc tìm kiếm',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onPressed: () {
                  _viewModel.searchController.clear();
                  _viewModel.updateSearchQuery('');
                  _viewModel.selectFilter('all');
                },
              ),
            ],
          ),
        );
      }
      return CleanCard(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.iceOlive.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medical_information_outlined,
                size: 34,
                color: AppColors.iceOlive,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa Có Hồ Sơ Đợt Khám Nào',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.iceTextNavy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy thêm đợt khám đầu tiên để lưu trữ chẩn đoán, đơn thuốc và kết quả xét nghiệm.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.iceTextSlate,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.iceOlive,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Thêm Đợt Khám Đầu Tiên',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: () async {
                final res = await Navigator.pushNamed(
                  context,
                  AppRoutes.addRecord,
                );
                if (res == true) {
                  _viewModel.loadRecords();
                }
              },
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Positioned(
          left: 10,
          top: 16,
          bottom: 20,
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
                  const SizedBox(height: 8),
                  _buildYearSeparator(records[i].year),
                  const SizedBox(height: 14),
                ],
                TimelineRecordCard(
                  record: records[i],
                  onOpenDetail: () async {
                    final res = await Navigator.pushNamed(
                      context,
                      AppRoutes.recordDetail,
                      arguments: records[i].id,
                    );
                    if (res == true) {
                      _viewModel.loadRecords();
                    }
                  },
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.timelineChipBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Năm $year',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: AppColors.iceTextSlate,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
