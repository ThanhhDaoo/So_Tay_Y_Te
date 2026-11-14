import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/services/ocr_service.dart';
import '../../../../../core/theme/app_colors.dart';

class PrescriptionOcrResultModal extends StatefulWidget {
  final ValueChanged<ParsedPrescriptionResult>? onApplyResult;
  final OcrService? ocrService;

  const PrescriptionOcrResultModal({
    super.key,
    this.onApplyResult,
    this.ocrService,
  });

  static Future<void> show(
    BuildContext context, {
    ValueChanged<ParsedPrescriptionResult>? onApplyResult,
    OcrService? ocrService,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PrescriptionOcrResultModal(
        onApplyResult: onApplyResult,
        ocrService: ocrService,
      ),
    );
  }

  @override
  State<PrescriptionOcrResultModal> createState() => _PrescriptionOcrResultModalState();
}

class _PrescriptionOcrResultModalState extends State<PrescriptionOcrResultModal> {
  late final OcrService _ocrService;
  bool _isLoading = false;
  ParsedPrescriptionResult? _result;

  @override
  void initState() {
    super.initState();
    _ocrService = widget.ocrService ??
        (sl.isRegistered<OcrService>() ? sl<OcrService>() : OcrServiceImpl());
  }

  Future<void> _pickAndProcess(ImageSource source) async {
    setState(() => _isLoading = true);
    try {
      final imagePath = await _ocrService.pickImage(source: source);
      if (imagePath != null && mounted) {
        final parsed = await _ocrService.processPrescriptionImage(imagePath);
        if (mounted) {
          setState(() {
            _result = parsed;
          });
        }
      }
    } catch (_) {} finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.document_scanner_rounded, color: AppColors.primary, size: 24),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Quét Toa Thuốc Bằng AI',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Hệ thống nhận diện chữ viết tay và toa thuốc in theo chuẩn y tế, tự động bóc tách tên thuốc và liều lượng.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 18),

          if (_isLoading) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 12),
                    Text(
                      'AI đang bóc tách nội dung đơn thuốc...',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (_result == null) ...[
            // Actions: Camera & Gallery
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _pickAndProcess(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded, size: 18),
                    label: const Text('Chụp Camera', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _pickAndProcess(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded, size: 18),
                    label: const Text('Chọn Ảnh', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Extracted Results Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.rxBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_hospital_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _result!.hospital ?? 'Cơ sở khám bệnh',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Bác sĩ: ${_result!.doctorName ?? 'Chưa rõ'}', style: const TextStyle(fontSize: 12)),
                  Text('Chẩn đoán: ${_result!.diagnosis ?? 'Theo dõi'}', style: const TextStyle(fontSize: 12)),
                  const Divider(height: 16),
                  const Text('Danh sách thuốc bóc tách được:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  ..._result!.medicines.map((m) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                '${m.name} (${m.dosage}) - ${m.instruction}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  widget.onApplyResult?.call(_result!);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text('Lưu Vào Lịch Uống Thuốc', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
