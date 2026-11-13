import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../viewmodel/documents_state.dart';

class DocumentPrescriptionOcrCard extends StatelessWidget {
  const DocumentPrescriptionOcrCard({
    super.key,
    this.onViewScannedRx,
    this.onDrugTap,
  });

  final VoidCallback? onViewScannedRx;
  final ValueChanged<String>? onDrugTap;

  static const List<ExtractedDrugItem> _drugs = [
    ExtractedDrugItem(
      name: 'Esomeprazole 40mg',
      dosage: '1 viên • Trước ăn 30p',
    ),
    ExtractedDrugItem(
      name: 'Amoxicillin 500mg',
      dosage: '2 viên/ngày • Sau ăn',
    ),
    ExtractedDrugItem(
      name: 'Clarithromycin 500mg',
      dosage: '1 viên • Sáng / Tối',
    ),
    ExtractedDrugItem(
      name: 'Bismuth Subsalicylate',
      dosage: '2 viên • Trưa / Tối',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECE7DD)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0x8099EFE5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/ic_doc_prescription.svg',
                    width: 22,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF00685F),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đơn thuốc điều trị HP 14 ngày',
                      style: AppTypography.heading3.copyWith(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.iceTextNavy,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'BS.CKII Nguyễn Văn Bình • BV ĐH Y Dược',
                      style: AppTypography.body.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF3D4947),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x1A00685F),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/ic_doc_ocr_success.svg',
                      width: 13,
                      height: 13,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF00685F),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'OCR 100%',
                      style: AppTypography.caption.copyWith(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF00685F),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ĐÃ BÓC TÁCH TỰ ĐỘNG (4 THUỐC)',
                      style: AppTypography.caption.copyWith(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: const Color(0xFF3D4947),
                      ),
                    ),
                    Text(
                      'Đã lên lịch nhắc',
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF00685F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    mainAxisExtent: 58,
                  ),
                  itemCount: _drugs.length,
                  itemBuilder: (context, index) {
                    final drug = _drugs[index];
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      child: InkWell(
                        onTap: () => onDrugTap?.call(drug.name),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                drug.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelSemiBold.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.iceTextNavy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                drug.dosage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF3D4947),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/ic_doc_archive.svg',
                    width: 11,
                    height: 14,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF3D4947),
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Bản gốc đã lưu trữ (WebP • 210 KB)',
                    style: AppTypography.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3D4947),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onViewScannedRx,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Xem toa quét',
                        style: AppTypography.labelSemiBold.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF00685F),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SvgPicture.asset(
                        'assets/icons/ic_doc_arrow_right.svg',
                        width: 6,
                        height: 9,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF00685F),
                          BlendMode.srcIn,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

