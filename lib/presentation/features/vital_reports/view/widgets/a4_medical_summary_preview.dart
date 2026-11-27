import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../common_widgets/layout/app_layout.dart';
import '../../viewmodel/vital_reports_state.dart';

/// Thẻ tóm tắt Xuất Bệnh Án A4 Chuẩn Y Tế:
/// Mặt ngoài hiển thị bản tóm tắt gọn (Quốc hiệu, Chủ hồ sơ, Cảnh báo dị ứng 1 dòng, nút Phóng to),
/// đẩy toàn bộ trang giấy A4 chi tiết (Đơn thuốc, 3 đợt khám, Chữ ký số) vào Modal xem trước hỗ trợ zoom.
class A4MedicalSummaryPreview extends StatelessWidget {
  final VitalReportsState state;

  const A4MedicalSummaryPreview({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return CleanCard(
      onTap: () => _showFullA4Modal(context),
      borderColor: AppColors.reportBorderLight,
      padding: const EdgeInsets.all(AppLayoutTokens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.reportZoneRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        'assets/icons/ic_report_pdf_export_header.svg',
                        width: 20,
                        height: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xuất Bệnh Án A4 Chuẩn Y Tế',
                            style: AppTypography.heading3.copyWith(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.reportTextDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Hồ sơ ${state.dossierCode} • Chuẩn HL7 / FHIR',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.reportTextMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.reportCream,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.zoom_in_rounded,
                      size: 14,
                      color: AppColors.reportCreamDark,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Xem bản A4',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.reportCreamDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tóm tắt gọn đầu tờ A4 (3 điểm dữ liệu, không nhồi bảng dài chữ siêu nhỏ)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.reportBorderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/ic_report_medvault_seal.svg',
                            width: 15,
                            height: 15,
                          ),
                          const SizedBox(width: 5),
                          const Flexible(
                            child: Text(
                              'HỆ THỐNG MEDVAULT EHR',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.reportTeal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.reportTextMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${state.patientName} • Máu ${state.patientBloodGroup}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.reportTextDark,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: state.hasSevereAllergy
                        ? AppColors.reportAllergyBannerBg
                        : const Color(0xFFEEF4FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    state.allergyBannerText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: state.hasSevereAllergy
                          ? AppColors.reportAllergyTextRed
                          : AppColors.iceTextSlate,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Gồm ${state.activePrescriptions.length} đơn thuốc & ${state.recentEncounters.length} đợt khám gần nhất',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.reportTextSlate,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Chạm để phóng to ›',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.reportTeal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullA4Modal(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.sizeOf(ctx).height * 0.88,
        padding: EdgeInsets.fromLTRB(
          AppLayoutTokens.screenPadding,
          12,
          AppLayoutTokens.screenPadding,
          bottomPadding + 20,
        ),
        decoration: const BoxDecoration(
          color: AppColors.reportBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.reportBorderLight,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            SectionHeader(
              title: 'Bản Xem Trước Bệnh Án A4',
              subtitle: 'Vuốt hoặc chụm 2 ngón tay để phóng to trang in',
              icon: Icons.description_outlined,
              iconColor: AppColors.reportTeal,
              trailing: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.reportTextMuted,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: InteractiveViewer(
                minScale: 0.9,
                maxScale: 2.8,
                child: SingleChildScrollView(
                  child: _FullA4SheetDocument(state: state),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullA4SheetDocument extends StatelessWidget {
  final VitalReportsState state;

  const _FullA4SheetDocument({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.reportCream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: 16,
              top: 100,
              child: Transform.rotate(
                angle: -25 * (math.pi / 180),
                child: Opacity(
                  opacity: 0.07,
                  child: Text(
                    'MEDVAULT',
                    style: AppTypography.heading1.copyWith(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: AppColors.reportTeal,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: AppColors.reportTextDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Độc lập - Tự do - Hạnh phúc',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.reportTextSlate,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 72,
                    height: 1.5,
                    color: AppColors.reportDividerGray,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/ic_report_medvault_seal.svg',
                            width: 16,
                            height: 16,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'HỆ THỐNG MEDVAULT EHR',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.reportTeal,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Mã hồ sơ: ${state.dossierCode}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.reportCreamDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'TỔNG HỢP HỒ SƠ Y TẾ & SINH HIỆU LÂM SÀNG',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.reportTextDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF4FF).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        KeyValueRow(
                          label: 'Họ và tên',
                          value: state.patientName,
                          valueColor: AppColors.reportTextDark,
                        ),
                        KeyValueRow(
                          label: 'Ngày sinh',
                          value: state.patientDob,
                          valueColor: AppColors.reportTextDark,
                        ),
                        KeyValueRow(
                          label: 'Nhóm máu',
                          value: state.patientBloodGroup,
                          valueColor: AppColors.reportZoneRed,
                        ),
                        KeyValueRow(
                          label: 'CCCD / BHYT',
                          value: state.patientNationalId,
                          valueColor: AppColors.reportTextDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: state.hasSevereAllergy
                          ? AppColors.reportAllergyBannerBg
                          : const Color(0xFFEEF4FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.hasSevereAllergy
                              ? 'CẢNH BÁO DỊ ỨNG THUỐC NGHIÊM TRỌNG (HIGH RISK)'
                              : 'GHI NHẬN TIỀN SỬ DỊ ỨNG THUỐC / DỊ NGUYÊN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: state.hasSevereAllergy
                                ? AppColors.reportZoneRed
                                : AppColors.iceOlive,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.allergyBannerText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: state.hasSevereAllergy
                                ? AppColors.reportAllergyTextRed
                                : AppColors.iceTextSlate,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ĐƠN THUỐC ĐANG DÙNG (${state.activePrescriptions.length})',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.reportCreamDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final rx in state.activePrescriptions)
                    KeyValueRow(
                      label: '${rx.order} ${rx.name}',
                      value: rx.dosage,
                      labelColor: AppColors.reportTextDark,
                      valueColor: AppColors.reportTextMuted,
                    ),
                  const SizedBox(height: 14),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'TÓM TẮT ĐỢT KHÁM GẦN NHẤT',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.reportTextDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final enc in state.recentEncounters)
                    KeyValueRow(
                      label: '${enc.date} • ${enc.diagnosis}',
                      value: '${enc.facility} (${enc.resultBadge})',
                      labelColor: AppColors.reportTextDark,
                      valueColor: AppColors.reportCreamDark,
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          state.signatureSha256,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontFamily: 'Courier',
                            color: AppColors.reportTextMuted,
                          ),
                        ),
                      ),
                      Text(
                        state.doctorName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          color: AppColors.reportTeal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
