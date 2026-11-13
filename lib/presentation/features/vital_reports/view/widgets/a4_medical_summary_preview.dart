import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../viewmodel/vital_reports_state.dart';

class A4MedicalSummaryPreview extends StatelessWidget {
  final VitalReportsState state;

  const A4MedicalSummaryPreview({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.reportZoneRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        'assets/icons/ic_report_pdf_export_header.svg',
                        width: 20,
                        height: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xuất Bệnh Án A4 Chuẩn Y Tế',
                            style: AppTypography.heading3.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.reportTextDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Đồng bộ chuẩn HL7 / FHIR phục vụ hội chẩn',
                            style: AppTypography.caption.copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  'Bản xem trước',
                  style: AppTypography.caption.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.reportCreamDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Scaled Down A4 Medical Document Preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.reportCream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // MEDVAULT Watermark
                  Positioned(
                    right: 12,
                    top: 80,
                    child: Transform.rotate(
                      angle: -25 * (math.pi / 180),
                      child: Opacity(
                        opacity: 0.08,
                        child: Text(
                          'MEDVAULT',
                          style: AppTypography.heading1.copyWith(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            color: AppColors.reportTeal,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // A4 Document Content
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Official Header
                        Text(
                          'CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM',
                          style: AppTypography.caption.copyWith(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.45,
                            color: AppColors.reportTextDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Độc lập - Tự do - Hạnh phúc',
                          style: AppTypography.caption.copyWith(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: AppColors.reportTextSlate,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: 64,
                          height: 1.5,
                          color: AppColors.reportDividerGray,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/ic_report_medvault_seal.svg',
                                    width: 16,
                                    height: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'HỆ THỐNG MEDVAULT EHR',
                                      style: AppTypography.caption.copyWith(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.reportTeal,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                'Mã hồ sơ: ${state.dossierCode}',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.reportCreamDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'TỔNG HỢP HỒ SƠ Y TẾ & SINH HIỆU LÂM SÀNG',
                          style: AppTypography.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.reportTextDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Administrative Info Box
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF4FF).withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: AppTypography.caption.copyWith(fontSize: 8.5),
                                        children: [
                                          const TextSpan(
                                            text: 'Họ và tên: ',
                                            style: TextStyle(color: AppColors.reportTextMuted),
                                          ),
                                          TextSpan(
                                            text: state.patientName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.reportTextDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: AppTypography.caption.copyWith(fontSize: 8.5),
                                        children: [
                                          const TextSpan(
                                            text: 'Ngày sinh: ',
                                            style: TextStyle(color: AppColors.reportTextMuted),
                                          ),
                                          TextSpan(
                                            text: state.patientDob,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.reportTextDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: AppTypography.caption.copyWith(fontSize: 8.5),
                                        children: [
                                          const TextSpan(
                                            text: 'Nhóm máu: ',
                                            style: TextStyle(color: AppColors.reportTextMuted),
                                          ),
                                          TextSpan(
                                            text: state.patientBloodGroup,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.reportZoneRed,
                                            ),
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: AppTypography.caption.copyWith(fontSize: 8.5),
                                        children: [
                                          const TextSpan(
                                            text: 'CCCD/BHYT: ',
                                            style: TextStyle(color: AppColors.reportTextMuted),
                                          ),
                                          TextSpan(
                                            text: state.patientNationalId,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.reportTextDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Severe Allergy Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.reportAllergyBannerBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/ic_report_allergy_alert.svg',
                                    width: 14,
                                    height: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'CẢNH BÁO DỊ ỨNG THUỐC NGHIÊM TRỌNG (HIGH RISK)',
                                      style: AppTypography.caption.copyWith(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.reportZoneRed,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '• PENICILLIN (Sốc phản vệ độ 2) • ASPIRIN / NSAIDs (Khó thở co thắt)',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.reportAllergyTextRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Active Prescriptions Overview
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4,
                              children: [
                                Text(
                                  'ĐƠN THUỐC ĐANG DÙNG (02 LOẠI)',
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.reportCreamDark,
                                  ),
                                ),
                                Text(
                                  'CẬP NHẬT: 02 NGÀY TRƯỚC',
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.reportCreamDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF4FF).withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                children: state.activePrescriptions.map((rx) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 1.5),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${rx.order} ${rx.name}',
                                            style: AppTypography.caption.copyWith(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.reportTextDark,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          rx.dosage,
                                          style: AppTypography.caption.copyWith(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.reportTextMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Recent 3 Diagnostic Encounters Summary
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TÓM TẮT 3 ĐỢT KHÁM GẦN NHẤT',
                              style: AppTypography.caption.copyWith(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: AppColors.reportTextDark,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Column(
                              children: state.recentEncounters.map((enc) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 3),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF4FF).withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: AppTypography.caption.copyWith(fontSize: 7.5),
                                            children: [
                                              TextSpan(
                                                text: enc.date,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.reportTextDark,
                                                ),
                                              ),
                                              TextSpan(
                                                text: ' - ${enc.diagnosis} (${enc.facility})',
                                                style: const TextStyle(
                                                  color: AppColors.reportTextDark,
                                                ),
                                              ),
                                            ],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceMuted,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                        child: Text(
                                          enc.resultBadge,
                                          style: AppTypography.caption.copyWith(
                                            fontSize: 7.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.reportCreamDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Digital Signature & Security QR
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppColors.reportQrBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: 2,
                                          top: 2,
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            color: AppColors.reportTextDark,
                                          ),
                                        ),
                                        Positioned(
                                          right: 2,
                                          bottom: 2,
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            color: AppColors.reportTextDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Chữ ký số BV xác thực',
                                          style: AppTypography.caption.copyWith(
                                            fontSize: 7.5,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.reportTextMuted,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          state.signatureSha256,
                                          style: AppTypography.caption.copyWith(
                                            fontSize: 7.5,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'Courier',
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
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Bác sĩ điều trị',
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.reportTextMuted,
                                  ),
                                ),
                                Text(
                                  state.doctorName,
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.reportTeal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
