import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../renderer/chart_text_cache.dart';
import 'drawing_coordinates.dart';
import 'drawing_models.dart';

class DrawingGeometry {
  DrawingGeometry(this.object, this.coordinates, {this.textCache});
  final DrawingObject object;
  final DrawingCoordinates coordinates;
  final ChartTextCache? textCache;
  // A geometry belongs to one immutable drawing and viewport snapshot.
  late final List<Offset> points =
      object.anchors.map(coordinates.toScreen).toList(growable: false);

  /// Paint and hit-test the same derived handles, preserving anchor direction.
  List<Offset> get handlePoints {
    if (object.tool.isFreehand && object.anchors.length >= 2) {
      return [
        coordinates.toScreen(object.anchors.first),
        coordinates.toScreen(object.anchors.last)
      ];
    }
    final p = points;
    if (object.tool == DrawingTool.text) {
      final bounds = textBounds;
      return bounds == null
          ? []
          : [
              bounds.topLeft,
              bounds.topRight,
              bounds.bottomLeft,
              bounds.bottomRight
            ];
    }
    if (object.tool == DrawingTool.parallelChannel && p.length > 2) {
      // The third anchor defines width on the infinite parallel line; it may
      // lie beyond the finite channel. Use the painted line's projection.
      return [p[0], p[1], (p[0] + p[1]) / 2 + _channelOffset(p)];
    }
    if (object.tool != DrawingTool.measure || p.length != 2) return p;
    final center = Rect.fromPoints(p[0], p[1]).center;
    return [
      ...p,
      for (final handle in DrawingBoxHandle.values)
        Offset(handle.timeIndex == null ? center.dx : p[handle.timeIndex!].dx,
            handle.priceIndex == null ? center.dy : p[handle.priceIndex!].dy)
    ];
  }

  (Offset, Offset)? get parallelEdge {
    final p = points;
    if (object.tool != DrawingTool.parallelChannel || p.length < 3) return null;
    final offset = _channelOffset(p);
    return clipDrawingLine(p[0] + offset, p[1] + offset, coordinates.plot,
        extendStart: object.style.extend, extendEnd: object.style.extend);
  }

  /// Decorative only: kept out of [segments] and handle hit testing.
  (Offset, Offset)? get parallelMidline {
    final p = points;
    if (object.tool != DrawingTool.parallelChannel || p.length < 3) return null;
    // Average the corresponding rail endpoints before clipping: each rail
    // may intersect a different viewport edge or be entirely offscreen.
    final halfOffset = _channelOffset(p) / 2;
    return clipDrawingLine(
        p[0] + halfOffset, p[1] + halfOffset, coordinates.plot,
        extendStart: object.style.extend, extendEnd: object.style.extend);
  }

  Offset _channelOffset(List<Offset> p) {
    final d = p[1] - p[0];
    // Preserve the baseline's time endpoints. A screen-normal projection
    // would move them horizontally whenever the price-axis scale changes.
    if (d.dx.abs() < 1e-12) return Offset(p[2].dx - p[0].dx, 0);
    return Offset(0, p[2].dy - p[0].dy - d.dy * (p[2].dx - p[0].dx) / d.dx);
  }

  late final List<(Offset, Offset)> segments = _buildSegments();

  List<(Offset, Offset)> _buildSegments() {
    final p = points, rect = coordinates.plot;
    if (p.isEmpty) return [];
    final result = <(Offset, Offset)>[];
    void add(Offset a, Offset b, {bool start = false, bool end = false}) {
      final segment =
          clipDrawingLine(a, b, rect, extendStart: start, extendEnd: end);
      if (segment != null) result.add(segment);
    }

    switch (object.tool) {
      case DrawingTool.horizontalLine:
        add(Offset(rect.left, p[0].dy), Offset(rect.right, p[0].dy));
      case DrawingTool.priceLine:
        add(p[0], Offset(rect.right, p[0].dy));
      case DrawingTool.verticalLine:
        add(Offset(p[0].dx, rect.top), Offset(p[0].dx, rect.bottom));
      case DrawingTool.trendLine:
      case DrawingTool.extendedLine:
      case DrawingTool.ray:
        if (p.length > 1) {
          add(p[0], p[1],
              start: object.tool == DrawingTool.extendedLine,
              end: object.tool != DrawingTool.trendLine);
        }
      case DrawingTool.rectangle:
      case DrawingTool.measure:
        if (p.length > 1) {
          final r = Rect.fromPoints(p[0], p[1]);
          add(r.topLeft, r.topRight);
          add(r.topRight, r.bottomRight);
          add(r.bottomRight, r.bottomLeft);
          add(r.bottomLeft, r.topLeft);
        }
      case DrawingTool.parallelChannel:
        if (p.length > 1) {
          add(p[0], p[1], start: object.style.extend, end: object.style.extend);
          if (p.length > 2) {
            final offset = _channelOffset(p);
            add(p[0] + offset, p[1] + offset,
                start: object.style.extend, end: object.style.extend);
          }
        }
      case DrawingTool.fibonacci:
        if (p.length > 1) {
          for (final price in object.fibonacciPrices) {
            final y = coordinates.priceToY(price);
            add(
                Offset(math.min(p[0].dx, p[1].dx), y),
                Offset(
                    object.style.extend
                        ? rect.right
                        : math.max(p[0].dx, p[1].dx),
                    y));
          }
        }
      case DrawingTool.threeWave:
      case DrawingTool.fiveWave:
      case DrawingTool.brush:
        for (var i = 1; i < p.length; i++) {
          add(p[i - 1], p[i]);
        }
      case DrawingTool.text:
        // 文本没有线几何，命中范围由 textBounds 提供。
        break;
    }
    return result;
  }

  /// 斐波那契相邻档位之间的色带；横向范围与档位线一致（延伸时到绘图区右缘）。
  List<Rect> get fibonacciBands {
    final p = points;
    if (object.tool != DrawingTool.fibonacci || p.length < 2) return const [];
    final left = math.min(p[0].dx, p[1].dx);
    final right = object.style.extend
        ? coordinates.plot.right
        : math.max(p[0].dx, p[1].dx);
    final ys = [
      for (final price in object.fibonacciPrices) coordinates.priceToY(price)
    ];
    return [
      for (var i = 1; i < ys.length; i++)
        Rect.fromLTRB(
            left, math.min(ys[i - 1], ys[i]), right, math.max(ys[i - 1], ys[i]))
    ];
  }

  /// 右侧价格轴标签的纵坐标；水平直线与价格线共用，关闭价格标签时为 null。
  double? get axisPriceY {
    if (!object.style.showPrice || object.anchors.isEmpty) return null;
    if (object.tool != DrawingTool.horizontalLine &&
        object.tool != DrawingTool.priceLine) {
      return null;
    }
    return coordinates.toScreen(object.anchors.first).dy;
  }

  /// 价格线线上价格文字的左上角：压在锚点起点上方。水平直线只在价格轴标注。
  Offset? get inlinePriceOrigin {
    if (object.tool != DrawingTool.priceLine || !object.style.showPrice) {
      return null;
    }
    final points = this.points;
    if (points.isEmpty) return null;
    return points.first + const Offset(0, -15);
  }

  /// 文本排版：字号、加粗、斜体取自样式。
  TextPainter? get textPainter {
    final value = object.text;
    if (object.tool != DrawingTool.text || value == null || value.isEmpty) {
      return null;
    }
    final span = TextSpan(text: value, style: drawingTextStyle(object.style));
    return textCache?.layout(span) ??
        (TextPainter(text: span, textDirection: TextDirection.ltr)..layout());
  }

  /// 文本左上角：锚点即左上角，不吸附绘图区边缘，可部分或完全移出屏幕
  /// （超出部分由画布裁剪隐藏）。绘制、命中与选框共用此位置。
  Offset? textOrigin(Size size) {
    if (object.tool != DrawingTool.text || points.isEmpty) return null;
    return points.first;
  }

  /// 文本工具的可点击范围与选中框：实际排版矩形外扩少许留白；
  /// 有底色时同时覆盖整块底色。
  Rect? get textBounds {
    final painter = textPainter;
    if (painter == null) return null;
    final origin = textOrigin(painter.size);
    if (origin == null) return null;
    final bounds = (origin & painter.size).inflate(textSelectionPadding);
    final background = textBackgroundRect;
    return background == null
        ? bounds
        : bounds.expandToInclude(background.outerRect.inflate(2));
  }

  /// 文本底色的圆角矩形；留白随字号等比缩放（12 号字为 6×3）。
  RRect? get textBackgroundRect {
    if (object.style.textBackground == null) return null;
    final painter = textPainter;
    if (painter == null) return null;
    final origin = textOrigin(painter.size);
    if (origin == null) return null;
    final scale = object.style.fontSize / 12;
    return RRect.fromRectAndRadius(
        Rect.fromLTRB(
            origin.dx - 6 * scale,
            origin.dy - 3 * scale,
            origin.dx + painter.width + 6 * scale,
            origin.dy + painter.height + 3 * scale),
        const Radius.circular(textBackgroundRadius));
  }

  static const double textBackgroundRadius = 4;

  static const double textSelectionPadding = 4;

  late final Path? fillPath = _buildFillPath();

  /// Dense brush paths are reusable while the immutable drawing and map match.
  late final Path? freehandPath = _buildFreehandPath();

  Path? _buildFreehandPath() {
    final p = points;
    if (!object.tool.isFreehand || p.length < 2) return null;
    final path = Path()..moveTo(p.first.dx, p.first.dy);
    for (final point in p.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    return path;
  }

  Path? _buildFillPath() {
    final p = points;
    if ((object.tool == DrawingTool.rectangle ||
            object.tool == DrawingTool.measure) &&
        p.length > 1) {
      return Path()..addRect(Rect.fromPoints(p[0], p[1]));
    }
    if (object.tool == DrawingTool.parallelChannel && p.length > 2) {
      final d = p[1] - p[0];
      final offset = _channelOffset(p);
      double start = 0, end = 1;
      if (object.style.extend && d.distanceSquared > 1e-12) {
        final horizontal = d.dx.abs() >= d.dy.abs();
        final component = horizontal ? d.dx : d.dy;
        final rect = coordinates.plot;
        final minimum = horizontal ? rect.left : rect.top;
        final maximum = horizontal ? rect.right : rect.bottom;
        final base = horizontal ? p[0].dx : p[0].dy;
        final shifted = horizontal ? (p[0] + offset).dx : (p[0] + offset).dy;
        final ts = [
          (minimum - base) / component,
          (maximum - base) / component,
          (minimum - shifted) / component,
          (maximum - shifted) / component
        ];
        start = ts.reduce(math.min);
        end = ts.reduce(math.max);
      }
      final first = (p[0] + d * start, p[0] + d * end);
      final second = (first.$1 + offset, first.$2 + offset);
      // Clip the polygon at paint time: clipping its two independent borders
      // would lose visible fill when both borders sit outside the viewport.
      return Path()
        ..moveTo(first.$1.dx, first.$1.dy)
        ..lineTo(first.$2.dx, first.$2.dy)
        ..lineTo(second.$2.dx, second.$2.dy)
        ..lineTo(second.$1.dx, second.$1.dy)
        ..close();
    }
    return null;
  }

  DrawingHit? hitTestHandles(Offset point, double tolerance) {
    final p = handlePoints;
    var nearest = tolerance;
    int? anchor;
    for (var i = 0; i < p.length; i++) {
      final distance = (p[i] - point).distance;
      if (distance <= nearest) {
        nearest = distance;
        anchor = i;
      }
    }
    if (anchor != null) {
      if (object.tool == DrawingTool.text) {
        return DrawingHit(object.id, textCorner: anchor, distance: nearest);
      }
      if (object.tool == DrawingTool.parallelChannel && anchor == 2) {
        return DrawingHit(object.id, channelEdge: true, distance: nearest);
      }
      if (anchor >= object.anchors.length) {
        return DrawingHit(object.id,
            boxHandle: DrawingBoxHandle.values[anchor - 2], distance: nearest);
      }
      return DrawingHit(object.id,
          anchorIndex: object.tool.isFreehand && anchor == 1
              ? object.anchors.length - 1
              : anchor,
          distance: nearest);
    }
    return null;
  }

  DrawingHit? hitTest(Offset point, double tolerance) {
    // Text corners are edit targets only while their selection frame is visible.
    final handle = object.tool == DrawingTool.text
        ? null
        : hitTestHandles(point, tolerance);
    if (handle != null) return handle;
    final edge = parallelEdge;
    if (edge != null) {
      final distance = distanceToSegment(point, edge.$1, edge.$2);
      if (distance <= tolerance) {
        return DrawingHit(object.id, channelEdge: true, distance: distance);
      }
    }
    var nearest = tolerance;
    for (final segment in segments) {
      nearest =
          math.min(nearest, distanceToSegment(point, segment.$1, segment.$2));
    }
    final bounds = textBounds;
    if (nearest < tolerance ||
        fillPath?.contains(point) == true ||
        bounds?.contains(point) == true) {
      return DrawingHit(object.id, distance: nearest);
    }
    return null;
  }
}

enum FibonacciLabelSide { left, right, inside, hidden }

/// 斐波那契整组标签的位置，每次绘制按当前视口重新计算：
/// - 整个图形在绘图区外：[FibonacciLabelSide.hidden]；
/// - 比较色带左侧（bandLeft - plot.left）与锚点右缘右侧
///   （plot.right - anchorRight）的可见空间，放到更宽且放得下的一侧；
/// - 两侧都放不下：[FibonacciLabelSide.inside]，放进色带左上角内侧。
/// 右侧以锚点右缘计算，延伸只影响色带/档位线的绘制。
FibonacciLabelSide fibonacciLabelSide({
  required double labelWidth,
  required Rect band,
  required double anchorRight,
  required Rect plot,
  double gap = 4,
}) {
  if (!band.overlaps(plot)) return FibonacciLabelSide.hidden;
  final left = band.left - plot.left, right = plot.right - anchorRight;
  final need = labelWidth + gap;
  final best =
      right > left ? FibonacciLabelSide.right : FibonacciLabelSide.left;
  return math.max(left, right) >= need ? best : FibonacciLabelSide.inside;
}

/// 画线（水平直线/价格线）在右侧价格轴上的标签底框：与线垂直居中，
/// 不贴绘图区上下边缘，线移出屏幕时随之移出（由画布裁剪隐藏）。
Rect drawingAxisPillRect(
    {required Size label, required double y, required Rect plot}) {
  final width = label.width + 8, height = label.height + 4;
  return Rect.fromLTWH(plot.right - width - 2, y - height / 2, width, height);
}

/// 文本工具的绘制样式；颜色、字号、加粗、斜体都由 [DrawingStyle] 持久化。
TextStyle drawingTextStyle(DrawingStyle style) => TextStyle(
    color: style.color,
    fontSize: style.fontSize,
    fontWeight: style.bold ? FontWeight.w700 : FontWeight.w400,
    fontStyle: style.italic ? FontStyle.italic : FontStyle.normal);
