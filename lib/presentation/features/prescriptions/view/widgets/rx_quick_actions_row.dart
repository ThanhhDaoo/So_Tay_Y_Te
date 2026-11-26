import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../common_widgets/layout/app_layout.dart';

/// Hai nút thao tác nhanh: "+ Thêm đơn thuốc" và "Quét đơn OCR (PRO)".
class RxQuickActionsRow extends StatelessWidget {
  final VoidCallback onAddPrescription;
  final VoidCallback onScanOcr;

  const RxQuickActionsRow({
    super.key,
    required this.onAddPrescription,
    required this.onScanOcr,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: onAddPrescription,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rxOlive,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/ic_rx_add_white.svg',
                    width: 16,
                    height: 16,
                  ),
                  const SizedBox(width: 6),
                  const Flexible(
                    child: Text(
                      '+ Thêm đơn thuốc',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppLayoutTokens.cardGap),
        Expanded(
          child: SizedBox(
            height: 46,
            child: OutlinedButton(
              onPressed: onScanOcr,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.rxOlive,
                side: const BorderSide(color: AppColors.rxBorder),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/ic_rx_ocr_scan.svg',
                    width: 16,
                    height: 18,
                  ),
                  const SizedBox(width: 6),
                  const Flexible(
                    child: Text(
                      'Quét đơn OCR',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.rxOlive,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.iceDangerBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.rxProDarkText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
