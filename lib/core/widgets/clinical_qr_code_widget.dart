import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

/// Widget vẽ mã QR chuẩn ISO/IEC 18004 trực tiếp trên Canvas (hoạt động 100% offline,
/// quét thực tế được bằng mọi camera điện thoại).
class ClinicalQrCodeWidget extends StatelessWidget {
  final String data;
  final double size;
  final Color foregroundColor;
  final Color backgroundColor;

  const ClinicalQrCodeWidget({
    super.key,
    required this.data,
    this.size = 160,
    this.foregroundColor = const Color(0xFF1A252F),
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final safePayload = data.trim().isNotEmpty ? data.trim() : 'SO-TAY-Y-TE';
    final qrCode = QrCode.fromData(
      data: safePayload,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);

    return Semantics(
      label: 'Mã QR Y Tế',
      child: Container(
        width: size,
        height: size,
        color: backgroundColor,
        padding: const EdgeInsets.all(6),
        child: CustomPaint(
          painter: _QrMatrixPainter(
            qrImage: qrImage,
            color: foregroundColor,
          ),
        ),
      ),
    );
  }
}

class _QrMatrixPainter extends CustomPainter {
  final QrImage qrImage;
  final Color color;

  _QrMatrixPainter({
    required this.qrImage,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final count = qrImage.moduleCount;
    if (count <= 0) return;

    final cellSize = size.width / count;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int row = 0; row < count; row++) {
      for (int col = 0; col < count; col++) {
        if (qrImage.isDark(row, col)) {
          canvas.drawRect(
            Rect.fromLTWH(
              col * cellSize,
              row * cellSize,
              cellSize + 0.35,
              cellSize + 0.35,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrMatrixPainter oldDelegate) {
    return oldDelegate.qrImage != qrImage || oldDelegate.color != color;
  }
}
