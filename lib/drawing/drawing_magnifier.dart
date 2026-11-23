part of 'drawing_overlay.dart';

extension _DrawingMagnifier on _DrawingOverlayState {
  List<Widget> _magnifier(Size size) {
    final map = c.lastCoordinates!;
    final anchor = c.preview!;
    final point = map.toScreen(anchor);
    _magnifierOnLeft ??= point.dx > size.width / 2;
    final diameter = math.min(100.0, math.max(40.0, size.height - 60));
    final right = math.max(8.0, size.width - diameter - 48);
    Rect window(bool onLeft) =>
        Rect.fromLTWH(onLeft ? 8 : right, 42, diameter, diameter).inflate(16);
    // Stay on the chosen side until the finger approaches that window;
    // switch only when the opposite window is clear, avoiding midpoint jitter.
    if (window(_magnifierOnLeft!).contains(point) &&
        !window(!_magnifierOnLeft!).contains(point)) {
      _magnifierOnLeft = !_magnifierOnLeft!;
    }
    final left = _magnifierOnLeft! ? 8.0 : right;
    // 放大镜随宿主主题：浅色主题白底黑十字，深色主题深底白十字。
    final scheme = Theme.of(context).colorScheme;
    return [
      Positioned(
          left: left,
          top: 42,
          child: IgnorePointer(
              child: CustomPaint(
                  key: const ValueKey('drawing-magnifier'),
                  size: Size.square(diameter),
                  painter: _MagnifierPainter(
                      point, widget.chartSize, widget.paintChart,
                      background: scheme.surface,
                      foreground: scheme.onSurface)))),
      Positioned(
          left: math.min(
              math.max(8.0, point.dx - 90), math.max(8.0, size.width - 230)),
          top: math.min(
              math.max(38.0, point.dy + 18), math.max(38.0, size.height - 42)),
          child: IgnorePointer(
              child: _surface(Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                      '${labels.time} ${widget.dateFormatter(anchor.time)}\n'
                      '${widget.isMarketCap ? labels.marketCap : labels.price} ${widget.priceFormatter(anchor.price)}',
                      style: const TextStyle(fontSize: 10)))))),
    ];
  }
}

class _MagnifierPainter extends CustomPainter {
  _MagnifierPainter(this.point, this.chartSize, this.paintChart,
      {required this.background, required this.foreground});
  final Offset point;
  final Size chartSize;
  final void Function(Canvas, Size) paintChart;

  /// 镜内底色与十字准线颜色，取自主题的 surface / onSurface。
  final Color background, foreground;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    canvas.drawColor(background, BlendMode.srcOver);
    canvas.translate(center.dx, center.dy);
    canvas.scale(2);
    canvas.translate(-point.dx, -point.dy);
    paintChart(
        canvas, chartSize); // Shared painter; no screenshots or UI recursion.
    canvas.restore();
    final guide = Paint()
      ..color = foreground.withValues(alpha: .6)
      ..strokeWidth = .5;
    canvas.drawLine(Offset(center.dx - 10, center.dy),
        Offset(center.dx + 10, center.dy), guide);
    canvas.drawLine(Offset(center.dx, center.dy - 10),
        Offset(center.dx, center.dy + 10), guide);
    canvas.drawOval(
        rect.deflate(1),
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_MagnifierPainter oldDelegate) => true;
}
