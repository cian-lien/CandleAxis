part of 'drawing_overlay.dart';

extension _DrawingStatisticsPanel on _DrawingOverlayState {
  /// 面板默认停在左上角；区间右边界顶部的 X 落在面板下方时改停右上角，
  /// 让出退出按钮。
  Widget _statisticsPanelPositioned(Size size) {
    const margin = 8.0, priceAxis = 64.0;
    final width = math.min(260.0, math.max(1.0, size.width - priceAxis));
    final map = c.lastCoordinates;
    final layout = map == null
        ? null
        : DrawingRangeLayout.of(map, c.rangeStart, c.rangeEnd);
    final closeX = layout?.closeCenter.dx;
    final coversClose = closeX != null &&
        closeX <= margin + width + DrawingRangeLayout.closeHitRadius;
    final right = size.width - priceAxis - width;
    final useRight = coversClose &&
        right > margin &&
        closeX < right - DrawingRangeLayout.closeHitRadius;
    return Positioned(
        key: ValueKey(
            useRight ? 'drawing-statistics-right' : 'drawing-statistics-left'),
        left: useRight ? right : margin,
        top: margin,
        width: width,
        child: _statisticsPanel(size));
  }

  Widget _statisticsPanel(Size size) {
    final raw = DrawingRangeStatistics.calculate(
        widget.rawData, c.rangeStart!, c.rangeEnd!,
        latestClosed: widget.latestClosed);
    // PriceFormatter expects raw prices and owns the host dimension conversion.
    String value(double? v) => v == null ? '--' : widget.priceFormatter(v);
    String quantity(double? v) => v == null
        ? '--'
        : widget.amountFormatter?.call(v) ?? v.toStringAsPrecision(6);
    final rows = <(String, String)>[
      (
        labels.time,
        raw.startTime == null
            ? '--'
            : '${widget.dateFormatter(raw.startTime)} → ${widget.dateFormatter(raw.endTime)}'
      ),
      (labels.count, '${raw.count}'),
      (labels.start, value(raw.startValue)),
      (labels.end, value(raw.endValue)),
      (labels.high, value(raw.high)),
      (labels.low, value(raw.low)),
      (
        labels.change,
        '${value(raw.change)} / ${raw.changePercent?.toStringAsFixed(2) ?? '--'}%'
      ),
      (labels.volume, quantity(raw.volume)),
      if (raw.amount != null) (labels.amount, quantity(raw.amount)),
    ];
    // 退出入口是区间右边界顶部的 X；面板只展示数据，不拦截触点，
    // 以免盖住下方的 X 或手柄。
    return IgnorePointer(
        child: _surface(ConstrainedBox(
            key: const ValueKey('drawing-statistics'),
            constraints:
                BoxConstraints(maxHeight: math.max(80, size.height - 24)),
            child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                      '${labels.statistics} · ${widget.isMarketCap ? labels.marketCap : labels.price}'),
                  Flexible(
                      child: SingleChildScrollView(
                          child: Column(children: [
                    for (final row in rows)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(width: 58, child: Text(row.$1)),
                                Expanded(
                                    child: Text(row.$2,
                                        textAlign: TextAlign.right)),
                              ])),
                    if (raw.includesUnclosed)
                      Text(labels.includesUnclosed,
                          style: const TextStyle(
                              color: Colors.amber, fontSize: 10)),
                  ]))),
                ])))));
  }
}
