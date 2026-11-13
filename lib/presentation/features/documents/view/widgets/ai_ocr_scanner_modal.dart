import 'package:flutter/material.dart';

class AiOcrScannerModal extends StatefulWidget {
  final VoidCallback onScanComplete;

  const AiOcrScannerModal({super.key, required this.onScanComplete});

  static void show(BuildContext context, {required VoidCallback onScanComplete}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiOcrScannerModal(onScanComplete: onScanComplete),
    );
  }

  @override
  State<AiOcrScannerModal> createState() => _AiOcrScannerModalState();
}

class _AiOcrScannerModalState extends State<AiOcrScannerModal> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  bool _isProcessing = false;
  bool _isDone = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _triggerCapture() {
    setState(() => _isProcessing = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isDone = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1F1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
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
                Row(
                  children: const [
                    Icon(Icons.document_scanner, color: Color(0xFF5CE1E6), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'AI OCR Scanner Pro',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
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
                  // Simulated camera viewfinder
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
                          Image.asset(
                            'assets/images/img_doc_blood_test.png',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          Container(
                            color: Colors.black.withValues(alpha: 0.4),
                          ),
                          if (!_isDone)
                            AnimatedBuilder(
                              animation: _animController,
                              builder: (context, _) {
                                return Positioned(
                                  top: _animController.value * 280,
                                  left: 0,
                                  right: 0,
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
                          if (_isDone)
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF00C48C)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Color(0xFF00C48C), size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Trích Xuất Thành Công (100%)',
                                        style: TextStyle(color: Color(0xFF00C48C), fontWeight: FontWeight.w700, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '• Loại: Toa thuốc ngoại trú BV Bạch Mai\n• Thuốc 1: Panadol 500mg (2 viên/ngày)\n• Thuốc 2: Cefuroxim 500mg (2 viên/ngày)\n• Bác sĩ: BS. Nguyễn Hoàng Nam',
                                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Framing corners
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF5CE1E6), width: 3), left: BorderSide(color: Color(0xFF5CE1E6), width: 3)))),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF5CE1E6), width: 3), right: BorderSide(color: Color(0xFF5CE1E6), width: 3)))),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF5CE1E6), width: 3), left: BorderSide(color: Color(0xFF5CE1E6), width: 3)))),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF5CE1E6), width: 3), right: BorderSide(color: Color(0xFF5CE1E6), width: 3)))),
                  ),
                ],
              ),
            ),
          ),

          // Control footer
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomPadding),
            child: _isDone
                ? ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onScanComplete();
                    },
                    icon: const Icon(Icons.archive_outlined),
                    label: const Text('Lưu Vào Kho Tài Liệu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C48C),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _triggerCapture,
                          icon: const Icon(Icons.photo_library_outlined, color: Colors.white70),
                          label: const Text('Chọn từ album', style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white30),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _triggerCapture,
                          icon: _isProcessing
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : const Icon(Icons.camera_alt),
                          label: Text(_isProcessing ? 'Đang đọc...' : 'Chụp Quét'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5CE1E6),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
