import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common_widgets/layout/app_layout.dart';
import '../viewmodel/vital_reports_state.dart';
import '../viewmodel/vital_reports_viewmodel.dart';
import 'widgets/a4_medical_summary_preview.dart';
import 'widgets/clinical_context_header_card.dart';
import 'widgets/vital_confidentiality_notice.dart';
import 'widgets/vital_report_action_buttons.dart';
import 'widgets/vital_reports_header.dart';
import 'widgets/vital_telemetry_chart_card.dart';

class VitalReportsScreen extends StatefulWidget {
  final bool showBottomNav;

  const VitalReportsScreen({
    super.key,
    this.showBottomNav = true,
  });

  @override
  State<VitalReportsScreen> createState() => _VitalReportsScreenState();
}

class _VitalReportsScreenState extends State<VitalReportsScreen> {
  late final VitalReportsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = VitalReportsViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _listenForNotifications(BuildContext context, VitalReportsState state) {
    if (state.notificationMessage != null) {
      final msg = state.notificationMessage!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(seconds: 3),
            backgroundColor: AppColors.reportOliveDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        _viewModel.clearNotification();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final state = _viewModel.state;
        _listenForNotifications(context, state);

        return Scaffold(
          backgroundColor: AppColors.reportBackground,
          appBar: VitalReportsHeader(
            onProfileTap: () {},
          ),
          body: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              left: AppLayoutTokens.screenPadding,
              right: AppLayoutTokens.screenPadding,
              top: 16,
              bottom: 96,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cụm 1: Ngữ cảnh báo cáo & Bộ chọn chỉ số sinh hiệu
                ClinicalContextHeaderCard(
                  selectedMetric: state.selectedMetric,
                  onSelectMetric: _viewModel.selectMetric,
                ),
                const SizedBox(height: AppLayoutTokens.sectionGap),

                // Cụm 2: Biểu đồ xu hướng trực quan
                VitalTelemetryChartCard(
                  state: state,
                  onSelectTimeframe: _viewModel.selectTimeframe,
                ),
                const SizedBox(height: AppLayoutTokens.sectionGap),

                // Cụm 3: Thẻ tóm tắt Xuất Bệnh Án A4 (bấm mở Modal phóng to toàn trang) & Nút Xuất/In
                A4MedicalSummaryPreview(state: state),
                const SizedBox(height: 16),
                VitalReportActionButtons(
                  exportingAction: state.exportingAction,
                  onExportPdf: _viewModel.exportPdf,
                  onPrintAirPrint: _viewModel.printAirPrint,
                  onSendDoctor: _viewModel.sendDoctor,
                ),
                const SizedBox(height: 16),

                // Cụm 4: Ghi chú bảo mật HIPAA/GDPR
                const VitalConfidentialityNotice(),
              ],
            ),
          ),
        );
      },
    );
  }
}
