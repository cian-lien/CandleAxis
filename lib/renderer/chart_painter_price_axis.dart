part of 'chart_painter.dart';

/// Ticks are price values, not fixed screen slots. The shared animated range
/// projects them to Y; entering labels are clipped at the plot edges.
extension _ChartPriceAxis on ChartPainter {
  List<double> _resolvePriceAxisLineYs(MainRenderer renderer) {
    final labelHeight =
        getTextPainter('0', chartColors.defaultTextColor).height;
    final count = PriceAxisLayout.resolveCount(
      plotHeight: mMainRect.height,
      labelHeight: labelHeight,
      maxCount: chartStyle.priceAxisLabelCount ?? mGridRows + 1,
      minGap: chartStyle.priceAxisLabelMinGap,
    );
    if (count < 2) return const [];
    double priceAt(double y) =>
        renderer.maxValue -
        (y - renderer.getY(renderer.maxValue)) / renderer.scaleY;
    final factor = valueType == ChartValueType.marketCap ? mcapFactor : 1.0;
    final values = PriceAxisLayout.tickValues(
      min: priceAt(mMainRect.bottom + labelHeight) * factor,
      max: priceAt(mMainRect.top) * factor,
      // Include an extra label below the clip without changing the interval.
      span: mMainRect.height / renderer.scaleY * factor,
      count: count,
    );
    renderer.priceAxisValues = [for (final value in values) value / factor];
    return renderer.priceAxisValues!.map(renderer.getY).toList();
  }

  void drawMainPriceAxisImpl(Canvas canvas) {
    final renderer = mMainRenderer as MainRenderer;
    if (hidePriceAxis) {
      priceAxisLabels = const [];
      return;
    }
    canvas.save();
    canvas.clipRect(mMainRect);
    priceAxisLabels = renderer.drawPriceAxisLabels(
      canvas,
      getTextStyle(chartColors.defaultTextColor),
      renderer.priceAxisTargetValues(),
    );
    canvas.restore();
  }
}
