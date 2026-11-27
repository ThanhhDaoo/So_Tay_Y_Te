import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common_widgets/layout/app_layout.dart';
import '../../../common_widgets/senior_40plus/senior_ui_kit.dart';
import '../../../routes/app_routes.dart';
import '../viewmodel/home_state.dart';
import '../viewmodel/home_viewmodel.dart';
import 'widgets/home_blood_pressure_card.dart';
import 'widgets/home_medication_tasks_section.dart';
import 'widgets/home_user_time_header.dart';
import 'widgets/manual_blood_pressure_sheet.dart';
import 'widgets/medication_reminder_popup.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onSelectMainTab;
  final HomeViewModel? viewModel;
  final bool enableAutoMedicationPopup;

  const HomeScreen({
    super.key,
    this.onSelectMainTab,
    this.viewModel,
    this.enableAutoMedicationPopup = true,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeViewModel _viewModel;
  bool _ownsViewModel = false;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
    } else {
      _viewModel = HomeViewModel();
      _ownsViewModel = true;
    }
    _viewModel.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onStateChanged);
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  void _onStateChanged() {
    if (!mounted) return;
    final state = _viewModel.state;

    final msg = state.feedbackMessage;
    if (msg != null && msg.isNotEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(msg, style: const TextStyle(fontSize: 15.5)),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      _viewModel.clearFeedback();
    }

    if (widget.enableAutoMedicationPopup &&
        state.shouldAutoPromptMedication &&
        state.medicationProgress.nextPendingSlot != null) {
      final reminder = state.medicationProgress.nextPendingSlot!;
      _viewModel.markAutoPromptHandled();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openMedicationPopup(reminderSlotId: reminder.slotId);
      });
    }
  }

  void _openMedicationPopup({String? reminderSlotId}) {
    final progress = _viewModel.state.medicationProgress;
    if (progress.allSlots.isEmpty) {
      widget.onSelectMainTab?.call(2);
      return;
    }
    final target = (reminderSlotId != null
            ? progress.allSlots
                .where((s) => s.slotId == reminderSlotId)
                .firstOrNull
            : null) ??
        progress.nextPendingSlot ??
        progress.allSlots.first;

    MedicationReminderPopup.show(
      context,
      reminder: target,
      onMarkTaken: () => _viewModel.markPopupMedicationTaken(target),
      onSnoozeLater: () => _viewModel.snoozePopupMedication(target),
    );
  }

  Future<void> _showAddTaskDialog() async {
    final titleCtrl = TextEditingController();
    final timeCtrl = TextEditingController(text: '09:00');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Thêm Việc Cần Làm',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.iceTextNavy,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              style: const TextStyle(fontSize: 16.5),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.iceBackground,
                labelText: 'Tên công việc (VD: Đo đường huyết)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: timeCtrl,
              style: const TextStyle(fontSize: 16.5),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.iceBackground,
                labelText: 'Giờ nhắc (VD: 09:00)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Hủy',
              style: TextStyle(fontSize: 16, color: AppColors.iceTextSlate),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(104, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;
              Navigator.pop(ctx);
              _viewModel.addCustomTask(title, timeLabel: timeCtrl.text.trim());
            },
            child: const Text(
              'Thêm việc',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final state = _viewModel.state;

        return Scaffold(
          backgroundColor: AppColors.iceBackground,
          extendBodyBehindAppBar: true,
          appBar: const MedVaultGlassAppBar(
            title: 'Sổ Tay Y Tế',
          ),
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _viewModel.loadDashboard,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppLayoutTokens.screenPadding,
                topPad + 76,
                AppLayoutTokens.screenPadding,
                bottomPad + 132,
              ),
              children: [
                // KHỐI 1: Header thông tin bệnh nhân & thời gian thực
                HomeUserTimeHeader(
                  fullName: state.fullName,
                  ageLabel: state.ageLabel,
                  genderLabel: state.genderLabel,
                  avatarPath: state.avatarPath,
                  onOpenEmergencyCard: () => Navigator.pushNamed(
                    context,
                    AppRoutes.emergencyCard,
                    arguments: true,
                  ),
                  onTapProfile: () => widget.onSelectMainTab?.call(3),
                ),
                const SizedBox(height: SeniorTokens.sectionGap),

                // KHỐI 2: Huyết áp hằng ngày (Ưu tiên số 1)
                HomeBloodPressureCard(
                  comparison: state.bpComparison,
                  onUpdateManual: () {
                    ManualBloodPressureSheet.show(
                      context,
                      previousLog: state.bpComparison.today ??
                          state.bpComparison.yesterday,
                      onSave: (sys, dia, pulse, note) =>
                          _viewModel.saveManualBloodPressure(
                        systolic: sys,
                        diastolic: dia,
                        heartRate: pulse,
                        note: note,
                      ),
                    );
                  },
                  onScanMachine: () async {
                    final saved = await Navigator.pushNamed(
                      context,
                      AppRoutes.scanBloodPressure,
                    );
                    if (saved == true) {
                      _viewModel.loadDashboard();
                    }
                  },
                ),

                // KHỐI 3: Việc cần làm & Tiến độ uống thuốc
                HomeMedicationTasksSection(
                  medicationProgress: state.medicationProgress,
                  tasks: state.todayTasks,
                  onOpenMedicationPopup: () => _openMedicationPopup(),
                  onToggleTask: _viewModel.toggleTask,
                  onAddCustomTask: _showAddTaskDialog,
                ),

                // KHỐI 4: Tổng quan sức khỏe chung
                _buildHealthOverviewBlock(state.healthOverview),

                // KHỐI 5: Lưới Tiện ích sức khỏe (Big Action Cards)
                SeniorSectionBlock(
                  title: 'Tiện ích chăm sóc sức khỏe',
                  subtitle: 'Chạm vào từng mục để mở trang chuyên biệt',
                  icon: Icons.grid_view_rounded,
                  iconColor: AppColors.primary,
                  bottomSpacing: 0,
                  child: Column(
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: SeniorBigGridCard(
                                title: 'Hồ sơ bệnh án',
                                subtitle: 'Tiền sử, lưu ý đặc biệt & đợt khám',
                                icon: Icons.assignment_outlined,
                                svgAsset: 'assets/icons/ic_timeline_history.svg',
                                accentColor: AppColors.primary,
                                onTap: () {
                                  if (widget.onSelectMainTab != null) {
                                    widget.onSelectMainTab!(1);
                                  } else {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.timeline,
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SeniorBigGridCard(
                                title: 'Bác sĩ của tôi',
                                subtitle: 'Danh bạ bác sĩ khám & gọi trực tiếp',
                                icon: Icons.medical_services_outlined,
                                svgAsset: 'assets/icons/ic_doctor_bag.svg',
                                accentColor: AppColors.reportTeal,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.myDoctors,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: SeniorBigGridCard(
                                title: 'Video sức khỏe',
                                subtitle: 'Bài tập dưỡng sinh, khớp gối & thở',
                                icon: Icons.play_circle_outline_rounded,
                                accentColor: const Color(0xFF2563EB),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.healthVideos,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SeniorBigGridCard(
                                title: 'Dinh dưỡng & Thực phẩm chức năng',
                                subtitle: 'Thực đơn nên ăn, nên kiêng & thuốc bổ',
                                icon: Icons.spa_outlined,
                                accentColor: const Color(0xFF0891B2),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.nutritionSupplements,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHealthOverviewBlock(HomeHealthOverviewSummary summary) {
    return SeniorSectionBlock(
      title: 'Tổng quan sức khỏe',
      subtitle: 'Thông số cơ thể & bệnh lý đang theo dõi',
      iconAsset: 'assets/icons/ic_vitals_pulse.svg',
      iconColor: AppColors.primary,
      trailing: SeniorLabeledIconButton(
        icon: Icons.insights_rounded,
        label: 'Biểu đồ',
        onTap: () => Navigator.pushNamed(context, AppRoutes.vitalReports),
      ),
      child: SeniorCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.iceBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.iceCardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nhóm máu',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.iceTextMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          summary.bloodType,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.iceTextNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.iceBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.iceCardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thể trạng',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.iceTextMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          summary.bmiStatusText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.iceTextNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            KeyValueRow(
              label: 'Chiều cao • Cân nặng',
              value: summary.heightWeightText,
            ),
            KeyValueRow(
              label: 'Bệnh nền theo dõi',
              value: summary.chronicConditions.isNotEmpty
                  ? summary.chronicConditions.join(', ')
                  : 'Ổn định • Chưa ghi nhận',
            ),
            if (summary.allergies.isNotEmpty)
              KeyValueRow(
                label: 'Cảnh báo dị ứng',
                value: summary.allergies.join(', '),
                valueColor: AppColors.iceDangerText,
                valueWeight: FontWeight.w700,
              ),
            KeyValueRow(
              label: 'Khám gần nhất',
              value: summary.latestCheckupSummary,
            ),
            if (summary.allergies.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/ic_prof_allergy_alert.svg',
                    width: 15,
                    height: 15,
                    colorFilter: const ColorFilter.mode(
                      AppColors.iceDangerText,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Luôn thông báo tiền sử dị ứng cho bác sĩ trước khi nhận đơn.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppColors.iceDangerText,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
