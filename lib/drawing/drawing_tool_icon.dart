import 'package:flutter/material.dart';

import 'drawing_models.dart';

/// Small chart-specific symbols keep line, shape and wave categories distinct.
class DrawingToolIcon extends StatelessWidget {
  const DrawingToolIcon({super.key, required this.tool, required this.color});
  final DrawingTool tool;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size(22, 22),
        painter: _ToolPainter(tool, color),
      );
}

class _ToolPainter extends CustomPainter {
  const _ToolPainter(this.tool, this.color);
  final DrawingTool tool;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void line(Offset a, Offset b) => canvas.drawLine(a, b, paint);
    void anchor(Offset p) => canvas.drawCircle(p, 2, paint);
    const a = Offset(5, 19), b = Offset(19, 5);
    switch (tool) {
      case DrawingTool.trendLine:
      case DrawingTool.extendedLine:
      case DrawingTool.ray:
        line(tool == DrawingTool.extendedLine ? const Offset(1, 23) : a,
            tool == DrawingTool.trendLine ? b : const Offset(23, 1));
        anchor(a);
        anchor(b);
      case DrawingTool.horizontalLine:
        line(const Offset(2, 12), const Offset(22, 12));
        anchor(const Offset(12, 12));
      case DrawingTool.priceLine:
        anchor(const Offset(4, 16));
        line(const Offset(6, 16), const Offset(22, 16));
        _number(canvas, '123', const Offset(9, 5));
      case DrawingTool.verticalLine:
        line(const Offset(12, 3), const Offset(12, 21));
        anchor(const Offset(12, 3));
        anchor(const Offset(12, 21));
      case DrawingTool.parallelChannel:
        line(const Offset(2, 17), const Offset(16, 3));
        line(const Offset(8, 23), const Offset(22, 9));
        anchor(const Offset(4, 15));
        anchor(const Offset(14, 5));
        anchor(const Offset(18, 13));
      case DrawingTool.measure:
        canvas.drawRect(const Rect.fromLTRB(4, 4, 20, 20), paint);
        line(const Offset(8, 16), const Offset(16, 8));
        line(const Offset(8, 16), const Offset(8, 11));
        line(const Offset(16, 8), const Offset(11, 8));
      case DrawingTool.rectangle:
        canvas.drawRect(const Rect.fromLTRB(4, 4, 20, 20), paint);
        for (final p in [
          const Offset(4, 4),
          const Offset(20, 4),
          const Offset(20, 20),
          const Offset(4, 20)
        ]) {
          anchor(p);
        }
      case DrawingTool.fibonacci:
        for (final y in [4.0, 9.0, 12.0, 16.0, 21.0]) {
          line(Offset(3, y), Offset(21, y));
        }
      case DrawingTool.threeWave:
      case DrawingTool.fiveWave:
        final points = tool == DrawingTool.threeWave
            ? [
                const Offset(3, 17),
                const Offset(9, 8),
                const Offset(15, 14),
                const Offset(21, 6)
              ]
            : [
                const Offset(2, 18),
                const Offset(6, 10),
                const Offset(10, 15),
                const Offset(14, 6),
                const Offset(18, 11),
                const Offset(22, 3)
              ];
        final path = Path()..moveTo(points.first.dx, points.first.dy);
        for (final point in points.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
        canvas.drawPath(path, paint);
        _number(canvas, '1', const Offset(2, 1));
        _number(canvas, tool == DrawingTool.threeWave ? '3' : '5',
            const Offset(17, 16));
      case DrawingTool.brush:
        final stroke = Path()
          ..moveTo(3, 17)
          ..cubicTo(7, 6, 12, 22, 16, 11)
          ..cubicTo(18, 6, 20, 9, 21, 6);
        canvas.drawPath(stroke, paint);
      case DrawingTool.text:
        line(const Offset(6, 5), const Offset(18, 5));
        line(const Offset(12, 5), const Offset(12, 20));
        line(const Offset(9, 20), const Offset(15, 20));
    }
  }

  void _number(Canvas canvas, String number, Offset position) {
    final text = TextPainter(
      text: TextSpan(text: number, style: TextStyle(fontSize: 8, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, position);
  }

  @override
  bool shouldRepaint(_ToolPainter oldDelegate) =>
      oldDelegate.tool != tool || oldDelegate.color != color;
}

class DrawingUtilityIcon extends StatelessWidget {
  const DrawingUtilityIcon(
      {super.key, required this.erase, required this.color});
  final bool erase;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size(22, 22),
        painter: _UtilityPainter(erase, color),
      );
}

class _UtilityPainter extends CustomPainter {
  const _UtilityPainter(this.erase, this.color);
  final bool erase;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    if (erase) {
      final path = Path()
        ..moveTo(3, 15)
        ..lineTo(14, 4)
        ..lineTo(21, 11)
        ..lineTo(11, 21)
        ..lineTo(7, 21)
        ..close();
      canvas.drawPath(path, paint);
      canvas.drawLine(const Offset(9, 9), const Offset(16, 16), paint);
      canvas.drawLine(const Offset(7, 21), const Offset(22, 21), paint);
    } else {
      final path = Path()
        ..moveTo(4, 3)
        ..lineTo(4, 14)
        ..cubicTo(4, 24, 20, 24, 20, 14)
        ..lineTo(20, 3)
        ..lineTo(15, 3)
        ..lineTo(15, 14)
        ..cubicTo(15, 18, 9, 18, 9, 14)
        ..lineTo(9, 3)
        ..close();
      canvas.drawPath(path, paint);
      canvas.drawLine(const Offset(4, 8), const Offset(9, 8), paint);
      canvas.drawLine(const Offset(15, 8), const Offset(20, 8), paint);
    }
  }

  @override
  bool shouldRepaint(_UtilityPainter oldDelegate) =>
      oldDelegate.erase != erase || oldDelegate.color != color;
}
