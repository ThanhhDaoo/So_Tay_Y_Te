import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
              left: 16,
              right: 16,
              top: 16,
              bottom: 96,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Clinical Context Header Banner
                ClinicalContextHeaderCard(
                  selectedMetric: state.selectedMetric,
                  onSelectMetric: _viewModel.selectMetric,
                ),
                const SizedBox(height: 16),

                // 2. Interactive Telemetry Dashboard Card
                VitalTelemetryChartCard(
                  state: state,
                  onSelectTimeframe: _viewModel.selectTimeframe,
                ),
                const SizedBox(height: 16),

                // 3. Medical Summary Report Export (Scaled down A4 Preview)
                A4MedicalSummaryPreview(state: state),
                const SizedBox(height: 16),

                // 4. Action Export Buttons
                VitalReportActionButtons(
                  exportingAction: state.exportingAction,
                  onExportPdf: _viewModel.exportPdf,
                  onPrintAirPrint: _viewModel.printAirPrint,
                  onSendDoctor: _viewModel.sendDoctor,
                ),
                const SizedBox(height: 12),

                // 5. Safety & Confidentiality Notice
                const VitalConfidentialityNotice(),
              ],
            ),
          ),
        );
      },
    );
  }
}
