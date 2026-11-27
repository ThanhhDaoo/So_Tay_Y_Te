import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common_widgets/layout/app_layout_tokens.dart';
import '../../../common_widgets/senior_40plus/senior_ui_kit.dart';
import '../../../routes/app_routes.dart';
import '../viewmodel/home_state.dart';
import '../viewmodel/home_viewmodel.dart';
import 'widgets/home_blood_pressure_card.dart';
import 'widgets/home_medication_tasks_section.dart';
import 'widgets/home_user_time_header.dart';
import 'widgets/manual_blood_pressure_sheet.dart';
import 'widgets/medication_reminder_popup.dart';

/// Trang Chủ mới (Home Screen) chuẩn người trung niên & cao tuổi (40+):
/// Sắp xếp đúng 5 khối từ trên xuống:
/// 1. Header thông tin & thời gian (Ngày, thứ, giờ + Họ tên, Tuổi, Giới tính + ảnh/icon giới tính).
/// 2. Khối Huyết áp hằng ngày (Ưu tiên số 1: Hôm qua vs Hôm nay + Cập nhật + Chụp Scan).
/// 3. Khối Việc cần làm & Tiến độ uống thuốc + Popup nhắc uống thuốc trực quan.
/// 4. Khối Tổng quan sức khỏe.
/// 5. Lưới Tiện ích sức khỏe (Big Action Cards: Hồ sơ bệnh án, Bác sĩ của tôi, Video sức khỏe, Dinh dưỡng & TPCN).
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
            content: Text(msg, style: const TextStyle(fontSize: 16)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Thêm Việc Cần Làm Hôm Nay',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              style: const TextStyle(fontSize: 17),
              decoration: InputDecoration(
                labelText: 'Tên công việc (VD: Đo đường huyết)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: timeCtrl,
              style: const TextStyle(fontSize: 17),
              decoration: InputDecoration(
                labelText: 'Khung giờ nhắc (VD: 09:00)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(fontSize: 17)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(110, 50),
            ),
            onPressed: () {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;
              Navigator.pop(ctx);
              _viewModel.addCustomTask(title, timeLabel: timeCtrl.text.trim());
            },
            child: const Text(
              'Thêm việc',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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
          backgroundColor: AppColors.backgroundLight,
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _viewModel.loadDashboard,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppLayoutTokens.screenPadding,
                topPad + 14,
                AppLayoutTokens.screenPadding,
                bottomPad + 128,
              ),
              children: [
                // KHỐI 1: Header thông tin & thời gian
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

                // KHỐI 5: Lưới Tiện ích sức khỏe (Big Action Cards 2x2)
                SeniorSectionBlock(
                  title: 'Tiện ích chăm sóc sức khỏe',
                  subtitle: 'Chạm vào thẻ lớn để mở từng chuyên mục',
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
                                subtitle: 'Tiền sử, lưu ý đặc biệt & lịch sử khám',
                                icon: Icons.assignment_rounded,
                                accentColor: const Color(0xFF2B6CB0),
                                onTap: () {
                                  if (widget.onSelectMainTab != null) {
                                    widget.onSelectMainTab!(1);
                                  } else {
                                    Navigator.pushNamed(context, AppRoutes.timeline);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: SeniorBigGridCard(
                                title: 'Bác sĩ của tôi',
                                subtitle: 'Danh bạ bác sĩ từng khám & gọi ngay',
                                icon: Icons.medical_services_rounded,
                                accentColor: SeniorTokens.callActionGreen,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.myDoctors,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: SeniorBigGridCard(
                                title: 'Video sức khỏe',
                                subtitle: 'Bài tập dưỡng sinh, khớp gối & hơi thở',
                                icon: Icons.ondemand_video_rounded,
                                accentColor: const Color(0xFFC05621),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.healthVideos,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: SeniorBigGridCard(
                                title: 'Dinh dưỡng & Thực phẩm chức năng',
                                subtitle: 'Món nên ăn, nên kiêng & thuốc bổ',
                                icon: Icons.restaurant_rounded,
                                accentColor: const Color(0xFF6B46C1),
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
      subtitle: 'Tóm tắt thể trạng & bệnh lý nền đang theo dõi',
      icon: Icons.favorite_border_rounded,
      iconColor: AppColors.accent,
      trailing: SeniorLabeledIconButton(
        icon: Icons.bar_chart_rounded,
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
                  child: _OverviewMetricTile(
                    icon: Icons.water_drop_rounded,
                    iconColor: const Color(0xFFC62828),
                    label: 'Nhóm máu',
                    value: summary.bloodType,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OverviewMetricTile(
                    icon: Icons.accessibility_new_rounded,
                    iconColor: AppColors.primary,
                    label: 'Chỉ số thể trạng',
                    value: summary.bmiStatusText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _OverviewTextRow(
              icon: Icons.straighten_rounded,
              title: 'Chiều cao & Cân nặng:',
              content: summary.heightWeightText,
            ),
            const SizedBox(height: 10),
            _OverviewTextRow(
              icon: Icons.healing_rounded,
              title: 'Bệnh nền theo dõi:',
              content: summary.chronicConditions.isNotEmpty
                  ? summary.chronicConditions.join(', ')
                  : 'Ổn định • Chưa ghi nhận bệnh lý nền mạn tính',
            ),
            if (summary.allergies.isNotEmpty) ...[
              const SizedBox(height: 10),
              _OverviewTextRow(
                icon: Icons.warning_amber_rounded,
                iconColor: AppColors.iceDangerText,
                title: 'Cảnh báo dị ứng:',
                content: summary.allergies.join(', '),
              ),
            ],
            const SizedBox(height: 10),
            _OverviewTextRow(
              icon: Icons.event_note_rounded,
              title: 'Lần khám gần nhất:',
              content: summary.latestCheckupSummary,
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewMetricTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _OverviewMetricTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.iceTextSlate,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.iceTextNavy,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTextRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;

  const _OverviewTextRow({
    required this.icon,
    this.iconColor = AppColors.primary,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 22, color: iconColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 16.5,
                color: AppColors.iceTextNavy,
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: '$title ',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(
                  text: content,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.iceTextSlate,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
