import 'dart:math' as math;
import 'dart:ui';

import 'drawing_coordinates.dart';
import 'drawing_models.dart';

/// 区间统计中可交互的部件：左/右边界手柄与右边界顶部的关闭按钮。
enum DrawingRangeTarget { start, end, close }

/// 区间统计的屏幕几何。绘制与命中共用同一份布局，平移/缩放时
/// 边界随蜡烛（按时间）移动，手柄与关闭按钮始终贴在虚线上。
class DrawingRangeLayout {
  const DrawingRangeLayout._(
      {required this.left, required this.right, required this.plot});

  /// 左边界在起始蜡烛左缘，右边界在结束蜡烛右缘。
  static DrawingRangeLayout? of(DrawingCoordinates map, int? start, int? end) {
    if (start == null || end == null || !map.isUsable) return null;
    final half = map.pointWidth * map.scaleX / 2;
    double x(int time) =>
        map.toScreen(DrawingAnchor(time: time, price: map.minPrice)).dx;
    final a = x(start), b = x(end);
    return DrawingRangeLayout._(
        left: math.min(a, b) - half,
        right: math.max(a, b) + half,
        plot: map.plot);
  }

  final double left, right;
  final Rect plot;

  static const handleWidth = 16.0, handleHeight = 28.0, closeRadius = 8.0;

  /// 手柄与关闭按钮的触控范围比绘制尺寸更大，便于手指抓取。
  static const handleSlop = 10.0, closeHitRadius = 16.0;

  Rect get leftHandle => Rect.fromCenter(
      center: Offset(left, plot.center.dy),
      width: handleWidth,
      height: handleHeight);
  Rect get rightHandle => Rect.fromCenter(
      center: Offset(right, plot.center.dy),
      width: handleWidth,
      height: handleHeight);
  Offset get closeCenter => Offset(right, plot.top + closeRadius + 4);

  bool _onPlot(double x) => x >= plot.left && x <= plot.right;

  DrawingRangeTarget? hitTest(Offset point) {
    if (_onPlot(right) && (point - closeCenter).distance <= closeHitRadius) {
      return DrawingRangeTarget.close;
    }
    final hitLeft =
        _onPlot(left) && leftHandle.inflate(handleSlop).contains(point);
    final hitRight =
        _onPlot(right) && rightHandle.inflate(handleSlop).contains(point);
    if (hitLeft && hitRight) {
      // 区间很窄时两个手柄重叠，取离手指更近的一侧。
      return (point.dx - left).abs() <= (point.dx - right).abs()
          ? DrawingRangeTarget.start
          : DrawingRangeTarget.end;
    }
    if (hitLeft) return DrawingRangeTarget.start;
    if (hitRight) return DrawingRangeTarget.end;
    return null;
  }
}
