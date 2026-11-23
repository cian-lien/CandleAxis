import 'package:flutter/material.dart';

/// Shared solid boundaries for chart rows; painting never changes their size.
class ChartSectionBorder extends StatelessWidget {
  const ChartSectionBorder({
    super.key,
    required this.color,
    required this.child,
    this.top = true,
    this.bottom = true,
  });

  final Color color;
  final Widget child;
  final bool top;
  final bool bottom;

  @override
  Widget build(BuildContext context) => CustomPaint(
        foregroundPainter: _SectionBorderPainter(color, top, bottom),
        child: child,
      );
}

void drawChartSectionDivider(
    Canvas canvas, double width, double y, Color color) {
  final paint = Paint()
    ..color = color
    ..strokeWidth = 1
    ..isAntiAlias = false;
  canvas.drawLine(Offset(0, y), Offset(width, y), paint);
}

class _SectionBorderPainter extends CustomPainter {
  const _SectionBorderPainter(this.color, this.top, this.bottom);

  final Color color;
  final bool top;
  final bool bottom;

  @override
  void paint(Canvas canvas, Size size) {
    if (top) drawChartSectionDivider(canvas, size.width, .5, color);
    if (bottom) {
      drawChartSectionDivider(canvas, size.width, size.height - .5, color);
    }
  }

  @override
  bool shouldRepaint(_SectionBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      top != oldDelegate.top ||
      bottom != oldDelegate.bottom;
}
