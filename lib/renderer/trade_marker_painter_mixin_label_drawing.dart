part of 'trade_marker_painter_mixin.dart';

extension _TradeMarkerPainterMixinLabelDrawing on TradeMarkerPainterMixin {
  /// Lines and tags rebuild the same deterministic layout, so collision
  /// avoidance moves their centers together, including at either sticky edge.
  void _layoutPriceLabels(List<_PlotLabelSpec> specs) {
    if (specs.isEmpty) return;
    const gap = 2.0, border = 0.4;
    specs.sort((a, b) => a.y.compareTo(b.y));
    var nextTop = mMainRect.top + border;
    for (final spec in specs) {
      spec.y = clampMainPlotY(spec.y, spec.boxHeight, padding: border);
      spec.labelTop = math.max(spec.labelTop, nextTop);
      nextTop = spec.labelTop + spec.boxHeight + gap;
    }
    var bottom = mMainRect.bottom - border;
    for (final spec in specs.reversed) {
      spec.labelTop = math.min(spec.labelTop, bottom - spec.boxHeight);
      bottom = spec.labelTop - gap;
    }
    // An undersized plot cannot fit every tag; keep each centered inside it.
    for (final spec in specs) {
      spec.y = clampMainPlotY(spec.y, spec.boxHeight, padding: border);
    }
  }

  void _drawSplitLabel(
    Canvas canvas,
    _AvgLabelParts parts,
    double top,
    Paint paint,
  ) {
    // 均价徽标固定贴左侧边界，避免与 drawNowPrice 的右侧/自适应标签重叠。
    const offsetX = 0.0;
    final titleWidth = parts.titleWidth;
    final height = parts.height;
    final titleRect = Rect.fromLTWH(offsetX, top, titleWidth, height);
    final titlePath = _leftRoundedRectPath(
        titleRect, TradeMarkerPainterMixin._avgLabelCornerRadius.x);
    final borderPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = paint.color;
    canvas.drawPath(titlePath, paint);
    canvas.drawPath(titlePath, borderPaint);
    parts.titlePainter.paint(
      canvas,
      Offset(
        offsetX + TradeMarkerPainterMixin._avgLabelPaddingH,
        top + (height - parts.titlePainter.height) / 2,
      ),
    );
    final valuePainter = parts.valuePainter;
    if (valuePainter == null) return;
    final valueLeft = offsetX + titleWidth;
    final valueWidth = parts.valueWidth;
    final valueRect = Rect.fromLTWH(valueLeft, top, valueWidth, height);
    final valuePath = _rightRoundedRectPath(
        valueRect, TradeMarkerPainterMixin._avgLabelCornerRadius.x);
    final fillPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..color = chartColors.selectFillColor;
    canvas.drawPath(valuePath, fillPaint);
    canvas.drawPath(valuePath, borderPaint);
    valuePainter.paint(
      canvas,
      Offset(
        valueLeft + TradeMarkerPainterMixin._avgLabelPaddingH,
        top + (height - valuePainter.height) / 2,
      ),
    );
  }

  Path _leftRoundedRectPath(Rect rect, double radius) {
    final effectiveRadius =
        math.min(radius, math.min(rect.width, rect.height) / 2);
    return Path()
      ..moveTo(rect.left + effectiveRadius, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left + effectiveRadius, rect.bottom)
      ..quadraticBezierTo(
          rect.left, rect.bottom, rect.left, rect.bottom - effectiveRadius)
      ..lineTo(rect.left, rect.top + effectiveRadius)
      ..quadraticBezierTo(
          rect.left, rect.top, rect.left + effectiveRadius, rect.top)
      ..close();
  }

  Path _rightRoundedRectPath(Rect rect, double radius) {
    final effectiveRadius =
        math.min(radius, math.min(rect.width, rect.height) / 2);
    return Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.right - effectiveRadius, rect.top)
      ..quadraticBezierTo(
          rect.right, rect.top, rect.right, rect.top + effectiveRadius)
      ..lineTo(rect.right, rect.bottom - effectiveRadius)
      ..quadraticBezierTo(
          rect.right, rect.bottom, rect.right - effectiveRadius, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
  }
}
