import 'dart:math' as math;
import 'package:flutter/painting.dart';

/// Price/average/order lines share a few horizontal dash patterns. Record each
/// pattern once and submit one stroke instead of one draw call per dash.
class ChartDashCache {
  final _paths = <(double, double, double), Path>{};

  void draw(Canvas canvas, double width, double y, double length, double gap,
      Paint paint) {
    final step = length + gap;
    if (!width.isFinite ||
        !y.isFinite ||
        !step.isFinite ||
        width <= 0 ||
        length <= 0 ||
        step <= 0) {
      return;
    }
    final key = (width, length, gap);
    var path = _paths[key];
    if (path == null) {
      path = Path();
      for (var x = 0.0; x < width; x += step) {
        path
          ..moveTo(x, 0)
          ..lineTo(math.min(x + length, width), 0);
      }
      if (_paths.length == 4) _paths.remove(_paths.keys.first);
      _paths[key] = path;
    }
    final style = paint.style;
    canvas.save();
    canvas.translate(0, y);
    canvas.drawPath(path, paint..style = PaintingStyle.stroke);
    paint.style = style;
    canvas.restore();
  }
}
