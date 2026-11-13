import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../viewmodel/vital_reports_state.dart';

class VitalReportActionButtons extends StatelessWidget {
  final ExportActionType exportingAction;
  final VoidCallback onExportPdf;
  final VoidCallback onPrintAirPrint;
  final VoidCallback onSendDoctor;

  const VitalReportActionButtons({
    super.key,
    required this.exportingAction,
    required this.onExportPdf,
    required this.onPrintAirPrint,
    required this.onSendDoctor,
  });

  @override
  Widget build(BuildContext context) {
    final isBusy = exportingAction != ExportActionType.none;

    return Column(
      children: [
        // Primary Button: Xuất PDF Bệnh Án
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: isBusy ? null : onExportPdf,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.reportOliveDark,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.reportOliveDark.withValues(alpha: 0.6),
              elevation: 2,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: exportingAction == ExportActionType.pdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/ic_report_btn_pdf.svg',
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Xuất PDF Bệnh Án (A4 chuẩn y khoa)',
                          style: AppTypography.labelSemiBold.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),

        // Row of 2 secondary buttons
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: isBusy ? null : onPrintAirPrint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.reportCream,
                    foregroundColor: const Color(0xFF433624),
                    disabledBackgroundColor: AppColors.reportCream.withValues(alpha: 0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: exportingAction == ExportActionType.print
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF433624)),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/ic_report_btn_print.svg',
                              width: 18,
                              height: 18,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF433624),
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'In AirPrint',
                                style: AppTypography.labelSemiBold.copyWith(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF433624),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: isBusy ? null : onSendDoctor,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.reportCream,
                    foregroundColor: const Color(0xFF433624),
                    disabledBackgroundColor: AppColors.reportCream.withValues(alpha: 0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: exportingAction == ExportActionType.sendDoctor
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF433624)),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/ic_report_btn_send_doc.svg',
                              width: 18,
                              height: 18,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF433624),
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Gửi Bác Sĩ',
                                style: AppTypography.labelSemiBold.copyWith(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF433624),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
