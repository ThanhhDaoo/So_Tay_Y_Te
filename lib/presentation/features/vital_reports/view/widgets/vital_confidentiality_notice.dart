import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class VitalConfidentialityNotice extends StatelessWidget {
  const VitalConfidentialityNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.reportNoticeBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.reportBorderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            'assets/icons/ic_report_shield_notice.svg',
            width: 16,
            height: 22,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Dữ liệu xuất được mã hóa 256-bit chuẩn HIPAA/GDPR y tế. Bản in PDF có mã QR xác minh trực tiếp với cơ sở khám chữa bệnh.',
              style: AppTypography.caption.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                height: 1.4,
                color: AppColors.reportTextMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

