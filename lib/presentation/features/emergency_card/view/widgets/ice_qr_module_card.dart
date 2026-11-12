import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';

/// Module mã QR tóm tắt lâm sàng khẩn cấp cho điều dưỡng & bác sĩ.
class IceQrModuleCard extends StatelessWidget {
  final VoidCallback onExpandQr;

  const IceQrModuleCard({super.key, required this.onExpandQr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.iceSecondaryCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.iceCardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.iceTextNavy.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SvgPicture.asset(
              'assets/icons/ic_emergency_qr.svg',
              width: 80,
              height: 80,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MÃ QR ĐIỀU DƯỠNG & BS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.iceOlive,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Tóm Tắt Lâm Sàng Khẩn',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.iceTextNavy,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Quét bằng camera bất kỳ để mở hồ sơ số khẩn cấp khi nạn nhân hôn mê hoặc mất tri giác.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: AppColors.iceTextSlate,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: onExpandQr,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Phóng to toàn màn hình',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.iceOlive,
                          ),
                        ),
                        const SizedBox(width: 6),
                        SvgPicture.asset(
                          'assets/icons/ic_fullscreen_qr.svg',
                          width: 12,
                          height: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hiển thị hộp thoại phóng to mã QR lâm sàng khẩn cấp.
Future<void> showFullScreenEmergencyQrDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: AppColors.iceBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'MÃ QR LÂM SÀNG KHẨN CẤP',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.iceOlive,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.iceCardBorder),
              ),
              child: SvgPicture.asset(
                'assets/icons/ic_emergency_qr.svg',
                width: 200,
                height: 200,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Đưa mã QR này cho nhân viên y tế để truy cập nhanh nhóm máu, dị ứng và liên hệ ICE.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.iceTextSlate),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.iceOlive,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
