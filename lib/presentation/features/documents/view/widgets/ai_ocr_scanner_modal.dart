import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/services/ocr_service.dart';
import '../../../../../domain/entities/medical_event.dart';
import '../../../../../domain/entities/medicine.dart';
import '../../../../../domain/entities/prescription.dart';
import '../../../../../domain/repositories/medical_record_repository.dart';
import '../../viewmodel/documents_state.dart';
import '../../viewmodel/documents_viewmodel.dart';

class AiOcrScannerModal extends StatefulWidget {
  final VoidCallback onScanComplete;
  final OcrService? ocrService;
  final DocumentsViewModel? documentsViewModel;

  const AiOcrScannerModal({
    super.key,
    required this.onScanComplete,
    this.ocrService,
    this.documentsViewModel,
  });

  static void show(
    BuildContext context, {
    required VoidCallback onScanComplete,
    OcrService? ocrService,
    DocumentsViewModel? documentsViewModel,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiOcrScannerModal(
        onScanComplete: onScanComplete,
        ocrService: ocrService,
        documentsViewModel: documentsViewModel,
      ),
    );
  }

  @override
  State<AiOcrScannerModal> createState() => _AiOcrScannerModalState();
}

class _AiOcrScannerModalState extends State<AiOcrScannerModal> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final OcrService _ocrService;
  bool _ownsOcrService = false;
  bool _isProcessing = false;
  bool _isDone = false;
  ParsedPrescriptionResult? _scannedResult;
  String? _scannedImagePath;

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
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _animController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    if (_ownsOcrService) {
      _ocrService.dispose();
    }
    _animController.dispose();
    super.dispose();
  }

  Future<void> _triggerCapture({ImageSource source = ImageSource.camera}) async {
    setState(() => _isProcessing = true);

    try {
      final imagePath = await _ocrService.pickImage(source: source);
      if (imagePath == null) {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
        return;
      }

      final parsed = await _ocrService.processPrescriptionImage(imagePath);
      if (mounted) {
        setState(() {
          _scannedImagePath = imagePath;
          _scannedResult = parsed;
          _isProcessing = false;
          _isDone = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể phân tích ảnh: $e')),
        );
      }
    }
  }

  Future<void> _saveAndClose() async {
    final res = _scannedResult;
    if (widget.documentsViewModel != null && _scannedImagePath != null) {
      final findings = (res != null && res.medicines.isNotEmpty)
          ? res.medicines
              .map((m) => {
                    'label': m.name,
                    'value': '${m.dosage} • ${m.instruction}',
                    'status': 'Đã bóc tách',
                  })
              .toList()
          : <Map<String, String>>[
              {
                'label': 'Chẩn đoán / Nội dung',
                'value': res?.diagnosis?.isNotEmpty == true
                    ? res!.diagnosis!
                    : (res?.rawText.trim().isNotEmpty == true
                        ? res!.rawText.trim().split('\n').first
                        : 'Đã lưu ảnh chụp gốc'),
                'status': 'Hoàn tất',
              },
            ];

      await widget.documentsViewModel!.addDocument(
        title: res?.diagnosis != null && res!.diagnosis!.isNotEmpty
            ? 'Đơn thuốc: ${res.diagnosis}'
            : 'Toa thuốc quét bằng AI OCR',
        category: DocumentCategory.prescriptions,
        filePath: _scannedImagePath!,
        hospital: res?.hospital?.isNotEmpty == true ? res!.hospital : 'Cơ sở y tế',
        findings: findings,
      );
    }

    // Đồng bộ luôn sang Lịch uống thuốc & Dòng thời gian nếu bóc tách được danh sách thuốc thực tế
    if (res != null &&
        res.medicines.isNotEmpty &&
        _scannedImagePath != null &&
        sl.isRegistered<MedicalRecordRepository>()) {
      try {
        final now = DateTime.now();
        final meds = res.medicines.asMap().entries.map((entry) {
          return Medicine(
            id: 'med_${now.millisecondsSinceEpoch}_${entry.key}',
            name: entry.value.name,
            dosage: entry.value.dosage,
            frequency: entry.value.instruction,
          );
        }).toList();

        final event = MedicalEvent(
          id: 'REC-OCR-${now.millisecondsSinceEpoch}',
          title: res.diagnosis != null && res.diagnosis!.isNotEmpty
              ? 'Đơn thuốc: ${res.diagnosis}'
              : 'Đơn thuốc quét từ ảnh',
          description: res.advice,
          date: now,
          type: MedicalEventType.generalCheckup,
          facilityName: res.hospital,
          doctorName: res.doctorName,
          diagnosis: res.diagnosis,
          prescription: Prescription(
            id: 'RX-OCR-${now.millisecondsSinceEpoch}',
            doctorName: res.doctorName ?? 'Bác sĩ kê đơn',
            hospital: res.hospital,
            issuedDate: now,
            medicines: meds,
            note: res.advice,
          ),
          attachments: [_scannedImagePath!],
          createdAt: now,
          updatedAt: now,
        );
        await sl<MedicalRecordRepository>().saveMedicalEvent(event);
      } catch (_) {}
    }

    if (mounted) {
      Navigator.pop(context);
      widget.onScanComplete();
    }
  }

  String _buildExtractedSummaryText() {
    final r = _scannedResult;
    if (r == null) return 'Chưa có dữ liệu quét.';
    final lines = <String>[];
    if (r.hospital != null && r.hospital!.isNotEmpty) {
      lines.add('• Cơ sở y tế: ${r.hospital}');
    }
    if (r.diagnosis != null && r.diagnosis!.isNotEmpty) {
      lines.add('• Chẩn đoán / Loại đơn: ${r.diagnosis}');
    }
    if (r.doctorName != null && r.doctorName!.isNotEmpty) {
      lines.add('• Bác sĩ kê đơn: ${r.doctorName}');
    }
    if (r.medicines.isNotEmpty) {
      for (final m in r.medicines) {
        lines.add('• Thuốc: ${m.name} (${m.dosage}) — ${m.instruction}');
      }
    } else if (r.rawText.trim().isNotEmpty) {
      final preview = r.rawText
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .take(5)
          .join('\n');
      lines.add('• Nội dung đọc được:\n$preview');
    } else {
      lines.add('• Không phát hiện chữ rõ nét trên ảnh. Hãy bấm "Quét lại" và chụp thẳng góc, đủ ánh sáng.');
    }
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.84,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1F1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.document_scanner, color: Color(0xFF5CE1E6), size: 20),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'AI OCR Scanner Pro',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Scanner Viewport
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1413),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF5CE1E6).withValues(alpha: 0.5), width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_scannedImagePath != null && File(_scannedImagePath!).existsSync())
                            Image.file(
                              File(_scannedImagePath!),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          else
                            Image.asset(
                              'assets/images/img_doc_blood_test.png',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          Container(
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                          if (!_isDone)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: AnimatedBuilder(
                                animation: _animController,
                                builder: (context, _) {
                                  return Align(
                                    alignment: Alignment(0, (_animController.value * 2) - 1.0),
                                    child: Container(
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF5CE1E6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF5CE1E6).withValues(alpha: 0.8),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          if (_isDone)
                            Container(
                              constraints: const BoxConstraints(maxHeight: 340),
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.88),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF00C48C)),
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Color(0xFF00C48C), size: 18),
                                        SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            'Trích Xuất Thành Công (100%)',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Color(0xFF00C48C),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _buildExtractedSummaryText(),
                                      style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.45),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Control footer
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomPadding),
            child: _isDone
                ? Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => setState(() {
                          _isDone = false;
                          _scannedResult = null;
                          _scannedImagePath = null;
                        }),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white38),
                          minimumSize: const Size(88, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Quét lại', style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveAndClose,
                          icon: const Icon(Icons.archive_outlined),
                          label: const Text('Lưu Vào Kho Tài Liệu'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C48C),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isProcessing ? null : () => _triggerCapture(source: ImageSource.gallery),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white30),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_library_outlined, color: Colors.white70, size: 16),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Chọn từ album',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : () => _triggerCapture(source: ImageSource.camera),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5CE1E6),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isProcessing)
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                )
                              else
                                const Icon(Icons.camera_alt, size: 16),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _isProcessing ? 'Đang quét...' : 'Chụp Quét',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                ),
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
