import 'dart:io';
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
  bool _ownsOcrService = false;
  bool _isLoading = false;
  bool _showRawText = false;
  ParsedPrescriptionResult? _result;

  @override
  void initState() {
    super.initState();
    if (widget.ocrService != null) {
      _ocrService = widget.ocrService!;
    } else if (sl.isRegistered<OcrService>()) {
      _ocrService = sl<OcrService>();
    } else {
      _ocrService = OcrServiceImpl();
      _ownsOcrService = true;
    }
  }

  @override
  void dispose() {
    if (_ownsOcrService) {
      _ocrService.dispose();
    }
    super.dispose();
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
            _showRawText = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi quét ảnh đơn thuốc: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddOrEditMedDialog({int? editIndex}) {
    if (_result == null) return;
    final existing = (editIndex != null &&
            editIndex >= 0 &&
            editIndex < _result!.medicines.length)
        ? _result!.medicines[editIndex]
        : null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final dosageCtrl = TextEditingController(text: existing?.dosage ?? '1 viên/lần');
    final instCtrl = TextEditingController(text: existing?.instruction ?? 'Ngày uống 2 lần sau ăn');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          existing != null ? 'Chỉnh Sửa Thuốc Bóc Tách' : 'Bổ Sung Thuốc Vào Đơn',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Tên thuốc & hàm lượng'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: dosageCtrl,
              decoration: const InputDecoration(labelText: 'Số lượng / Liều lượng'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: instCtrl,
              decoration: const InputDecoration(labelText: 'Cách uống'),
            ),
          ],
        ),
        actions: [
          if (existing != null)
            TextButton(
              onPressed: () {
                final updatedMeds = List<ParsedMedicineItem>.from(_result!.medicines)
                  ..removeAt(editIndex!);
                setState(() {
                  _result = ParsedPrescriptionResult(
                    rawText: _result!.rawText,
                    prescriptionType: _result!.prescriptionType,
                    doctorName: _result!.doctorName,
                    hospital: _result!.hospital,
                    diagnosis: _result!.diagnosis,
                    advice: _result!.advice,
                    medicines: updatedMeds,
                    imagePath: _result!.imagePath,
                  );
                });
                Navigator.pop(ctx);
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.redAccent)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              final newItem = ParsedMedicineItem(
                name: nameCtrl.text.trim(),
                dosage: dosageCtrl.text.trim(),
                instruction: instCtrl.text.trim(),
              );
              final updatedMeds = List<ParsedMedicineItem>.from(_result!.medicines);
              if (existing != null) {
                updatedMeds[editIndex!] = newItem;
              } else {
                updatedMeds.add(newItem);
              }
              setState(() {
                _result = ParsedPrescriptionResult(
                  rawText: _result!.rawText,
                  prescriptionType: _result!.prescriptionType,
                  doctorName: _result!.doctorName,
                  hospital: _result!.hospital,
                  diagnosis: _result!.diagnosis,
                  advice: _result!.advice,
                  medicines: updatedMeds,
                  imagePath: _result!.imagePath,
                );
              });
              Navigator.pop(ctx);
            },
            child: Text(existing != null ? 'Cập nhật' : 'Thêm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomPadding),
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
            const SizedBox(height: 14),

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
            const SizedBox(height: 6),
            const Text(
              'Nhận diện tiếng Việt có dấu trên đơn thuốc bệnh viện, phòng khám & nhà thuốc, tự động bóc tách chẩn đoán, tên thuốc và liều uống.',
              style: TextStyle(fontSize: 15.5, color: AppColors.textSecondaryLight, height: 1.35),
            ),
            const SizedBox(height: 18),

            if (_isLoading) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 12),
                      Text(
                        'Đang phân tích hình ảnh và bóc tách đơn thuốc...',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_result == null) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 54),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _pickAndProcess(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded, size: 24),
                      label: const Text('Chụp Camera', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        minimumSize: const Size(0, 54),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _pickAndProcess(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded, size: 24),
                      label: const Text('Chọn Ảnh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_result!.imagePath != null && File(_result!.imagePath!).existsSync()) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            height: 96,
                            width: double.infinity,
                            child: Image.file(
                              File(_result!.imagePath!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
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
                                    _result!.hospital ?? 'Cơ sở y tế (Chưa ghi trên đơn)',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Chẩn đoán / Đơn thuốc: ${_result!.diagnosis ?? "Chưa nhận diện chẩn đoán"}',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.iceTextNavy),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Bác sĩ kê đơn: ${_result!.doctorName ?? "Chưa rõ tên bác sĩ"}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                            ),
                            if (_result!.advice != null && _result!.advice!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Lời dặn: ${_result!.advice!}',
                                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondaryLight),
                              ),
                            ],
                            const Divider(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Danh sách thuốc bóc tách (${_result!.medicines.length} loại):',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => _showAddOrEditMedDialog(),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Text(
                                      '+ Thêm thuốc',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_result!.medicines.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8E1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _result!.rawText.trim().isEmpty
                                      ? 'Không nhận diện được chữ trên ảnh đã chọn. Hãy chụp thẳng góc, đủ sáng vào tờ đơn thuốc hoặc bấm "+ Thêm thuốc".'
                                      : 'Đã đọc được văn bản trên ảnh nhưng chưa thấy dòng thuốc chuẩn hàm lượng (mg/ml/viên). Bạn có thể xem văn bản gốc bên dưới hoặc bấm "+ Thêm thuốc".',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF795548), height: 1.35),
                                ),
                              )
                            else
                              ..._result!.medicines.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final m = entry.value;
                                return InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => _showAddOrEditMedDialog(editIndex: idx),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.rxBorder.withValues(alpha: 0.7)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${idx + 1}. ',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.primary),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${m.name} (${m.dosage})',
                                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                m.instruction,
                                                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.edit_outlined,
                                          size: 15,
                                          color: AppColors.primary,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            if (_result!.rawText.trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () => setState(() => _showRawText = !_showRawText),
                                child: Row(
                                  children: [
                                    Icon(
                                      _showRawText ? Icons.expand_less : Icons.expand_more,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        _showRawText ? 'Ẩn văn bản gốc đọc từ ảnh' : 'Xem toàn bộ chữ đọc từ ảnh',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_showRawText) ...[
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Text(
                                    _result!.rawText,
                                    style: const TextStyle(fontSize: 11, color: AppColors.iceTextSlate, height: 1.35),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.4),
                      minimumSize: const Size(0, 52),
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => setState(() => _result = null),
                    icon: const Icon(Icons.refresh_rounded, size: 22),
                    label: const Text('Quét lại', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 52),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: (_result!.medicines.isEmpty && _result!.rawText.trim().isEmpty)
                          ? null
                          : () {
                              widget.onApplyResult?.call(_result!);
                              Navigator.pop(context);
                            },
                      icon: const Icon(Icons.check_circle_rounded, size: 22),
                      label: const Text('Lưu Vào Lịch Uống Thuốc', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
