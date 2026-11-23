import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../renderer/chart_text_cache.dart';
import 'chart_drawing_controller.dart';
import 'drawing_anchor_painter.dart';
import 'drawing_coordinates.dart';
import 'drawing_geometry.dart';
import 'drawing_geometry_cache.dart';
import 'drawing_models.dart';
import 'drawing_range_layout.dart';
import 'fibonacci_label_layout.dart';
import 'measure_arrow_geometry.dart';

/// Drawing and magnifier use identical geometry, clipping and coordinates.
class DrawingCanvas {
  static void draw(
      Canvas canvas, ChartDrawingController controller, DrawingCoordinates map,
      {String Function(double)? priceFormatter,
      String Function(int?)? dateFormatter,
      ChartTextCache? textCache,
      DrawingGeometryCache? geometryCache,
      Color anchorSurface = Colors.white}) {
    if (!map.isUsable) return;
    void anchor(Offset point, Color color, {bool active = false}) =>
        DrawingAnchorPainter.paint(canvas, point, color: color, active: active);
    canvas.save();
    canvas.clipRect(map.plot);
    if (!controller.hidden) {
      for (final object in controller.visibleObjects) {
        _object(canvas, object, map, priceFormatter, textCache, geometryCache);
      }
    }
    final draft = controller.draftObject;
    if (draft != null) _object(canvas, draft, map, priceFormatter, textCache);
    final selected = controller.selectedObject;
    if (selected != null && controller.mode == DrawingMode.edit) {
      if (selected.tool == DrawingTool.text) {
        _textSelection(
            canvas, DrawingGeometry(selected, map, textCache: textCache));
      } else {
        final active = controller.activeHandleIndex;
        final handles = DrawingGeometry(selected, map).handlePoints;
        for (var i = 0; i < handles.length; i++) {
          anchor(handles[i], selected.style.color, active: i == active);
        }
      }
    }
    // 画笔草稿是密集轨迹采样，逐点画锚点会变成一串圆点。
    if (controller.tool?.isFreehand != true) {
      for (final a in controller.draftAnchors) {
        anchor(map.toScreen(a), controller.currentStyle.color);
      }
    }
    final preview = controller.preview;
    if (preview != null) {
      final p = map.toScreen(preview);
      final paint = Paint()
        ..color = controller.currentStyle.color.withValues(alpha: .65)
        ..strokeWidth = .7;
      canvas.drawLine(
          Offset(map.plot.left, p.dy), Offset(map.plot.right, p.dy), paint);
      canvas.drawLine(
          Offset(p.dx, map.plot.top), Offset(p.dx, map.plot.bottom), paint);
      // 绘制中跟手的锚点即当前正在放置的点，按激活态强调。
      anchor(p, controller.currentStyle.color, active: true);
    }
    if (controller.mode == DrawingMode.statistics) {
      final layout = DrawingRangeLayout.of(
          map, controller.rangeStart, controller.rangeEnd);
      if (layout != null) {
        _range(canvas, layout, controller.activeRangeTarget, anchorSurface);
      }
    }
    canvas.restore();
    // 时间标签独立于图形的纵向裁剪，保留日期轴上方的完整标签。
    if (dateFormatter != null) {
      final rectangle =
          draft ?? (controller.mode == DrawingMode.edit ? selected : null);
      if (rectangle?.tool == DrawingTool.rectangle &&
          rectangle!.anchors.length == 2) {
        _rectangleTimes(canvas, rectangle, map, dateFormatter, textCache);
      }
    }
  }

  static void _rectangleTimes(
      Canvas canvas,
      DrawingObject rectangle,
      DrawingCoordinates map,
      String Function(int?) formatter,
      ChartTextCache? textCache) {
    final anchors = rectangle.anchors.toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    Rect? previous;
    final color = rectangle.style.color;
    for (final anchor in anchors) {
      final x = map.toScreen(anchor).dx;
      if (x < map.plot.left || x > map.plot.right) continue;
      final span = TextSpan(
          text: formatter(anchor.time),
          style: TextStyle(
              fontSize: 11,
              color: color.computeLuminance() > .5
                  ? const Color(0xFF111111)
                  : Colors.white));
      final maxWidth = math.max(1.0, map.plot.width - 8);
      final painter = textCache?.layout(span,
              maxWidth: maxWidth, maxLines: 1, ellipsis: '…') ??
          (TextPainter(
              text: span,
              textDirection: TextDirection.ltr,
              maxLines: 1,
              ellipsis: '…')
            ..layout(maxWidth: maxWidth));
      final width = painter.width + 8, height = painter.height + 4;
      final left = (x - width / 2)
          .clamp(map.plot.left, math.max(map.plot.left, map.plot.right - width))
          .toDouble();
      var rect =
          Rect.fromLTWH(left, map.plot.bottom - height - 4, width, height);
      // 相邻时间很近时上下错开，避免两个标签互相覆盖。
      if (previous != null && previous.overlaps(rect)) {
        rect = rect.translate(0, -height - 2);
      }
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          Paint()..color = color);
      painter.paint(canvas, rect.topLeft + const Offset(4, 2));
      previous = rect;
    }
  }

  static const rangeAccent = Color(0xFF4285F4);

  /// 区间统计：两侧虚线 + 中间浅色填充；虚线中部是带 ‹ / › 的圆角手柄，
  /// 右边界顶部是退出用的 X。边界本身不画背景条。
  static void _range(Canvas canvas, DrawingRangeLayout layout,
      DrawingRangeTarget? active, Color surface) {
    final plot = layout.plot;
    canvas.drawRect(
        Rect.fromLTRB(layout.left, plot.top, layout.right, plot.bottom),
        Paint()..color = rangeAccent.withValues(alpha: .08));
    final line = Paint()
      ..color = rangeAccent
      ..strokeWidth = 1;
    for (final x in [layout.left, layout.right]) {
      _line(canvas, Offset(x, plot.top), Offset(x, plot.bottom), line,
          DrawingLineStyle.dashed);
    }
    _rangeHandle(canvas, layout.leftHandle,
        left: true,
        active: active == DrawingRangeTarget.start,
        surface: surface);
    _rangeHandle(canvas, layout.rightHandle,
        left: false,
        active: active == DrawingRangeTarget.end,
        surface: surface);
    final center = layout.closeCenter;
    canvas.drawCircle(
        center, DrawingRangeLayout.closeRadius, Paint()..color = rangeAccent);
    final cross = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    const r = 3.0;
    canvas.drawLine(
        center + const Offset(-r, -r), center + const Offset(r, r), cross);
    canvas.drawLine(
        center + const Offset(r, -r), center + const Offset(-r, r), cross);
  }

  static void _rangeHandle(Canvas canvas, Rect rect,
      {required bool left, required bool active, required Color surface}) {
    final box = RRect.fromRectAndRadius(
        active ? rect.inflate(2) : rect, const Radius.circular(4));
    canvas.drawRRect(box, Paint()..color = active ? rangeAccent : surface);
    canvas.drawRRect(
        box,
        Paint()
          ..color = rangeAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    final c = rect.center;
    final dx = left ? 1.5 : -1.5;
    final chevron = Path()
      ..moveTo(c.dx + dx, c.dy - 4)
      ..lineTo(c.dx - dx, c.dy)
      ..lineTo(c.dx + dx, c.dy + 4);
    canvas.drawPath(
        chevron,
        Paint()
          ..color = active ? Colors.white : rangeAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
  }

  static void _object(
      Canvas canvas,
      DrawingObject object,
      DrawingCoordinates map,
      String Function(double)? formatter,
      ChartTextCache? textCache,
      [DrawingGeometryCache? geometryCache]) {
    final geometry =
        geometryCache?.resolve(object, map, textCache: textCache) ??
            DrawingGeometry(object, map, textCache: textCache);
    final fill = object.style.fillColor;
    if (fill != null && geometry.fillPath != null) {
      canvas.drawPath(geometry.fillPath!, Paint()..color = fill);
    }
    final bands = geometry.fibonacciBands;
    if (bands.isNotEmpty) {
      // 各档位色带统一一种浅色，合并成一块绘制，避免相邻色带接缝处出现细线。
      canvas.drawRect(
          bands.reduce((a, b) => a.expandToInclude(b)),
          Paint()
            ..color = object.style.color
                .withValues(alpha: object.style.color.a * .3));
    }
    final paint = Paint()
      ..color = object.style.color
      ..strokeWidth = object.style.width
      ..style = PaintingStyle.stroke;
    if (object.tool.isFreehand &&
        object.style.lineStyle == DrawingLineStyle.solid) {
      // 画笔整条轨迹一笔描出，避免逐段 drawLine 在拐点处出现缺口和叠点。
      paint
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      final path = geometry.freehandPath;
      if (path != null) canvas.drawPath(path, paint);
    } else {
      for (final segment in geometry.segments) {
        _line(canvas, segment.$1, segment.$2, paint, object.style.lineStyle);
      }
    }
    final midline = geometry.parallelMidline;
    if (midline != null) {
      final midlinePaint = Paint()
        ..color = object.style.color
        ..strokeWidth = object.style.width / 2
        ..style = PaintingStyle.stroke;
      _line(canvas, midline.$1, midline.$2, midlinePaint,
          DrawingLineStyle.dashed);
    }
    // 波浪只画折线，不在拐点标注 0/1/2… 或 A/B/C 序号。
    final points = geometry.points;
    if (object.tool == DrawingTool.measure && points.length == 2) {
      final arrows = computeMeasureArrows(points[0], points[1]);
      if (arrows != null) {
        final arrowPaint = Paint()
          ..color = object.style.color
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;
        for (final arrow in [arrows.horizontal, arrows.vertical]) {
          canvas.drawLine(arrow.start, arrow.tip, arrowPaint);
          canvas.drawLine(arrow.wing1, arrow.tip, arrowPaint);
          canvas.drawLine(arrow.tip, arrow.wing2, arrowPaint);
        }
      }
    }
    if (object.tool == DrawingTool.fibonacci && bands.isNotEmpty) {
      // 整组标签按最宽标签统一决定一次位置（每帧随平移/缩放重新计算）：
      // 两侧外面取可见空间更大且放得下的一侧，都放不下则贴色带左缘内侧，
      // 图形整体移出绘图区时不画。右侧空间按锚点右缘计算，延伸不影响标签。
      final values = object.fibonacciPrices;
      final band = bands.reduce((a, b) => a.expandToInclude(b));
      final anchorRight = math.max(points[0].dx, points[1].dx);
      final painters = [
        for (var i = 0; i < values.length; i++)
          _painter(
              '${DrawingObject.fibonacciRatios[i]}  '
              '${_price(values[i], map, formatter)}',
              object.style.color,
              textCache)
      ];
      final side = fibonacciLabelSide(
          labelWidth: painters.fold(0.0, (w, p) => math.max(w, p.width)),
          band: band,
          anchorRight: anchorRight,
          plot: map.plot);
      // 文字始终放在各自档位线上方，重叠的低优先级标签不画，越界部分由画布裁剪。
      final origins = layoutFibonacciLabels(
          labels: [for (final p in painters) p.size],
          levels: [for (final value in values) map.priceToY(value)],
          bandLeft: band.left,
          anchorRight: anchorRight,
          side: side,
          plot: map.plot);
      for (var i = 0; i < origins.length; i++) {
        final origin = origins[i];
        if (origin != null) painters[i].paint(canvas, origin);
      }
    }
    final axisY = geometry.axisPriceY;
    if (axisY != null) {
      final value = _price(object.anchors[0].price, map, formatter);
      final origin = geometry.inlinePriceOrigin;
      if (origin != null) {
        _painter(value, object.style.color, textCache).paint(canvas, origin);
      }
      _axisPill(canvas, value, axisY, object.style.color, map.plot, textCache);
    }
    final textPainter = geometry.textPainter;
    if (textPainter != null) {
      final background = geometry.textBackgroundRect;
      if (background != null) {
        canvas.drawRRect(
            background, Paint()..color = object.style.textBackground!);
      }
      final origin = geometry.textOrigin(textPainter.size);
      if (origin != null) textPainter.paint(canvas, origin);
    }
  }

  static String _price(double price, DrawingCoordinates map,
          String Function(double)? formatter) =>
      formatter?.call(price) ?? (price * map.factor).toStringAsPrecision(6);

  /// 右侧价格轴上的实心标签，底色取线色，与现价标签同侧对齐。
  /// 随线移动、不贴边，越界部分由画布裁剪隐藏。
  static void _axisPill(Canvas canvas, String text, double y, Color color,
      Rect plot, ChartTextCache? textCache) {
    final span = TextSpan(
        text: text,
        style: TextStyle(
            color: color.computeLuminance() > .5
                ? const Color(0xFF111111)
                : Colors.white,
            fontSize: 10));
    final painter = textCache?.layout(span) ??
        (TextPainter(text: span, textDirection: TextDirection.ltr)..layout());
    final rect = drawingAxisPillRect(label: painter.size, y: y, plot: plot);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        Paint()..color = color);
    painter.paint(canvas, rect.topLeft + const Offset(4, 2));
  }

  /// 选中文本时的设计工具式选框：细边框 + 四角方形手柄。
  static void _textSelection(Canvas canvas, DrawingGeometry geometry) {
    final bounds = geometry.textBounds;
    if (bounds == null) return;
    const accent = Color(0xFF4285F4);
    canvas.drawRect(
        bounds,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    for (final corner in geometry.handlePoints) {
      final handle = Rect.fromCenter(center: corner, width: 6, height: 6);
      canvas.drawRect(handle, Paint()..color = Colors.white);
      canvas.drawRect(
          handle,
          Paint()
            ..color = accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
    }
  }

  static TextPainter _painter(
      String text, Color color, ChartTextCache? textCache) {
    final span =
        TextSpan(text: text, style: TextStyle(color: color, fontSize: 10));
    return textCache?.layout(span) ??
        (TextPainter(text: span, textDirection: TextDirection.ltr)..layout());
  }

  static void _line(
      Canvas canvas, Offset a, Offset b, Paint paint, DrawingLineStyle style) {
    if (style == DrawingLineStyle.solid) {
      canvas.drawLine(a, b, paint);
      return;
    }
    final length = (b - a).distance;
    if (length == 0) return;
    final direction = (b - a) / length;
    final dash = style == DrawingLineStyle.dotted ? 1.0 : 6.0;
    for (double d = 0; d < length; d += dash + 4) {
      canvas.drawLine(
          a + direction * d, a + direction * math.min(length, d + dash), paint);
    }
  }
}
