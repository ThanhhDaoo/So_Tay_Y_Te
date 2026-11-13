import 'package:flutter/material.dart';
import '../../viewmodel/vital_reports_state.dart';

class VitalChartPainter extends CustomPainter {
  final List<VitalChartPoint> points;
  final double minVal;
  final double maxVal;

  const VitalChartPainter({
    required this.points,
    this.minVal = 60,
    this.maxVal = 160,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final double width = size.width;
    final double height = size.height;
    final double topPad = 24.0;
    final double botPad = 28.0;
    final double chartHeight = height - topPad - botPad;
    final double rightMargin = 78.0; // Space for threshold labels
    final double chartWidth = width - rightMargin;

    double getY(double val) {
      final norm = (val - minVal) / (maxVal - minVal);
      return height - botPad - (norm * chartHeight);
    }

    final double y140 = getY(140);
    final double y120 = getY(120);
    final double y80 = getY(80);

    // 1. Subtle background zones
    final zoneRedPaint = Paint()..color = const Color(0x0DBB0112);
    final zoneYellowPaint = Paint()..color = const Color(0x0DFBBF24);
    final zoneGreenPaint = Paint()..color = const Color(0x0D10B981);

    canvas.drawRect(Rect.fromLTRB(0, topPad, chartWidth, y140), zoneRedPaint);
    canvas.drawRect(Rect.fromLTRB(0, y140, chartWidth, y120), zoneYellowPaint);
    canvas.drawRect(Rect.fromLTRB(0, y120, chartWidth, height - botPad), zoneGreenPaint);

    // 2. Threshold dashed lines and labels
    _drawThresholdLine(
      canvas: canvas,
      y: y140,
      width: chartWidth,
      label: '140 THA',
      color: const Color(0xFFBA1A1A),
      labelX: chartWidth + 6,
    );

    _drawThresholdLine(
      canvas: canvas,
      y: y120,
      width: chartWidth,
      label: '120 Ngưỡng',
      color: const Color(0xFF8C5C28),
      labelX: chartWidth + 6,
    );

    _drawThresholdLine(
      canvas: canvas,
      y: y80,
      width: chartWidth,
      label: '80 Tâm trương',
      color: const Color(0xFF515849),
      labelX: chartWidth + 6,
    );

    // 3. Compute point coordinates
    final int count = points.length;
    final double stepX = chartWidth / (count > 1 ? count - 1 : 1);

    final List<Offset> systolicOffsets = [];
    final List<Offset> diastolicOffsets = [];

    for (int i = 0; i < count; i++) {
      final x = i * stepX;
      final ySys = getY(points[i].systolic.toDouble());
      final yDia = getY(points[i].diastolic.toDouble());
      systolicOffsets.add(Offset(x, ySys));
      diastolicOffsets.add(Offset(x, yDia));
    }

    // 4. Draw smooth bezier curve for Systolic (Tâm thu)
    _drawSmoothCurve(
      canvas: canvas,
      offsets: systolicOffsets,
      strokeColor: const Color(0xFF00685F),
      strokeWidth: 2.5,
    );

    // 5. Draw smooth bezier curve for Diastolic (Tâm trương)
    _drawSmoothCurve(
      canvas: canvas,
      offsets: diastolicOffsets,
      strokeColor: const Color(0xFF545B4D),
      strokeWidth: 2.0,
    );

    // 6. Draw dots on points
    for (int i = 0; i < count; i++) {
      final isLast = points[i].isLatest;

      // Systolic dot
      final sysCenter = systolicOffsets[i];
      canvas.drawCircle(
        sysCenter,
        isLast ? 5.0 : 4.0,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        sysCenter,
        isLast ? 4.0 : 3.0,
        Paint()..color = const Color(0xFF00685F),
      );

      // Diastolic dot
      final diaCenter = diastolicOffsets[i];
      canvas.drawCircle(
        diaCenter,
        isLast ? 4.5 : 3.5,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        diaCenter,
        isLast ? 3.5 : 2.5,
        Paint()..color = const Color(0xFF545B4D),
      );

      // Callout tooltip on the latest point
      if (isLast) {
        _drawCalloutBadge(
          canvas: canvas,
          anchor: sysCenter,
          text: '118/78',
        );
      }
    }
  }

  void _drawThresholdLine({
    required Canvas canvas,
    required double y,
    required double width,
    required String label,
    required Color color,
    required double labelX,
  }) {
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw dashed line
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + dashWidth, y),
        linePaint,
      );
      startX += dashWidth + dashSpace;
    }

    // Draw label
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: 'Courier',
          fontSize: 9.0,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(labelX, y - (textPainter.height / 2)));
  }

  void _drawSmoothCurve({
    required Canvas canvas,
    required List<Offset> offsets,
    required Color strokeColor,
    required double strokeWidth,
  }) {
    if (offsets.length < 2) return;

    final path = Path();
    path.moveTo(offsets[0].dx, offsets[0].dy);

    for (int i = 0; i < offsets.length - 1; i++) {
      final p0 = offsets[i];
      final p1 = offsets[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  void _drawCalloutBadge({
    required Canvas canvas,
    required Offset anchor,
    required String text,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final badgeWidth = textPainter.width + 12;
    final badgeHeight = textPainter.height + 6;
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(anchor.dx - 14, anchor.dy - 18),
        width: badgeWidth,
        height: badgeHeight,
      ),
      const Radius.circular(6),
    );

    // Shadow
    canvas.drawRRect(
      badgeRect.shift(const Offset(0, 2)),
      Paint()..color = const Color(0x26000000),
    );

    // Pill background
    canvas.drawRRect(
      badgeRect,
      Paint()..color = const Color(0xFF545B4D),
    );

    // Text inside
    textPainter.paint(
      canvas,
      Offset(
        badgeRect.left + 6,
        badgeRect.top + 3,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant VitalChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

