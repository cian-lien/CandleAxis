part of 'main_renderer.dart';

extension _MainRendererBatch on MainRenderer {
  void _appendLine(Path path, double? a, double? b, double x0, double x1) {
    if (a == null || b == null || !a.isFinite || !b.isFinite) return;
    // Separate contours preserve warm-up gaps and directional breaks.
    path
      ..moveTo(x0, getY(a))
      ..lineTo(x1, getY(b));
  }

  void _drawBatchedIndicator(MainState state, List<KLineEntity> data, int start,
      int stop, double step, Canvas canvas) {
    if (state == MainState.SUPER) {
      _drawBatchedSuperTrend(data, start, stop, step, canvas);
      return;
    }
    if (state == MainState.SAR) {
      canvas.save();
      canvas.scale(1 / scaleX, 1);
      final dots = Path();
      for (var i = start; i <= stop; i++) {
        final value = data[i].sar;
        if (value == null || !value.isFinite || !getY(value).isFinite) continue;
        dots.addOval(Rect.fromCircle(
            center: Offset((i * step + step / 2) * scaleX, getY(value)),
            radius: 2));
      }
      canvas.drawPath(
          dots,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = .8
            ..color = chartColors.sarColor);
      canvas.restore();
      return;
    }
    final count = mainIndicatorLineCount(state, maCount: maDayList.length);
    final lines = List.generate(count, (_) => Path());
    final cloudUp = Path(), cloudDown = Path();
    final futureA = Path(), futureB = Path();
    for (var i = start; i <= stop; i++) {
      final cur = data[i], last = data[i == 0 ? 0 : i - 1];
      final x = i * step + step / 2, lastX = i == 0 ? x : x - step;
      final index = state == MainState.ICHI ? _candleIndex(cur) : null;
      final lastIndex = state == MainState.ICHI ? _candleIndex(last) : null;
      for (var line = 0; line < count; line++) {
        if (state == MainState.RESIST) {
          final b = mainIndicatorValue(state,
              chartData?.isNotEmpty == true ? chartData!.last : cur, line);
          if (b == null || !b.isFinite) continue;
          final y = getY(b), dash = 4 / scaleX;
          for (var dx = lastX; dx < x; dx += dash * 2) {
            lines[line]
              ..moveTo(dx, y)
              ..lineTo((dx + dash).clamp(lastX, x), y);
          }
          continue;
        }
        final a = state == MainState.ICHI && lastIndex != null
            ? mainIndicatorValueAt(state, lastIndex, chartData!, line)
            : mainIndicatorValue(state, last, line);
        final b = state == MainState.ICHI && index != null
            ? mainIndicatorValueAt(state, index, chartData!, line)
            : mainIndicatorValue(state, cur, line);
        final shift = chartData == null
            ? mainIndicatorOffset(state, line) * (x - lastX)
            : 0.0;
        _appendLine(lines[line], a, b, lastX + shift, x + shift);
      }
      if (state != MainState.ICHI || chartData == null) continue;
      if (index != null &&
          lastIndex != null &&
          index >= 26 &&
          lastIndex >= 26) {
        _appendCloud(cloudUp, cloudDown, chartData![lastIndex - 26],
            chartData![index - 26], lastX, x);
      }
      if (index != null && index + 26 >= chartData!.length) {
        final shift = 26 * (x - lastX);
        _appendLine(futureA, last.indicators[IndicatorLine.senkouA],
            cur.indicators[IndicatorLine.senkouA], lastX + shift, x + shift);
        _appendLine(futureB, last.indicators[IndicatorLine.senkouB],
            cur.indicators[IndicatorLine.senkouB], lastX + shift, x + shift);
        _appendCloud(cloudUp, cloudDown, last, cur, lastX + shift, x + shift);
      }
    }
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _indicatorWidth;
    for (var line = 0; line < count; line++) {
      canvas.drawPath(lines[line], stroke..color = _indicatorColor(line));
    }
    if (state == MainState.ICHI && chartData != null) {
      final fill = Paint();
      canvas.drawPath(futureA, stroke..color = chartColors.getMAColor(2));
      canvas.drawPath(futureB, stroke..color = chartColors.getMAColor(3));
      canvas.drawPath(
          cloudUp, fill..color = chartColors.upColor.withValues(alpha: .12));
      canvas.drawPath(
          cloudDown, fill..color = chartColors.dnColor.withValues(alpha: .12));
    }
  }

  void _appendCloud(Path up, Path down, KLineEntity last, KLineEntity cur,
      double x0, double x1) {
    final a = last.indicators[IndicatorLine.senkouA],
        b = last.indicators[IndicatorLine.senkouB],
        c = cur.indicators[IndicatorLine.senkouA],
        d = cur.indicators[IndicatorLine.senkouB];
    if (a == null ||
        b == null ||
        c == null ||
        d == null ||
        !a.isFinite ||
        !b.isFinite ||
        !c.isFinite ||
        !d.isFinite) {
      return;
    }
    (c >= d ? up : down)
      ..moveTo(x0, getY(a))
      ..lineTo(x1, getY(c))
      ..lineTo(x1, getY(d))
      ..lineTo(x0, getY(b))
      ..close();
  }

  void _drawBatchedSuperTrend(
      List<KLineEntity> data, int start, int stop, double step, Canvas canvas) {
    final lines = [Path(), Path()], bands = [Path(), Path()];
    final colors = [
      chartColors.superTrendUpColor,
      chartColors.superTrendDnColor
    ];
    for (var i = start; i <= stop; i++) {
      if (i == 0) continue;
      final last = data[i - 1], cur = data[i];
      final a = last.indicators[IndicatorLine.superTrend],
          b = cur.indicators[IndicatorLine.superTrend];
      if (a == null || b == null || !a.isFinite || !b.isFinite) continue;
      final bullish = cur.close >= b;
      if ((last.close >= a) != bullish) continue;
      final side = bullish ? 0 : 1;
      final x = i * step + step / 2, x0 = x - step;
      bands[side]
        ..moveTo(x0, getY(a))
        ..lineTo(x, getY(b))
        ..lineTo(x, getY((cur.open + cur.close) / 2))
        ..lineTo(x0, getY((last.open + last.close) / 2))
        ..close();
      _appendLine(lines[side], a, b, x0, x);
    }
    final fill = Paint();
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _indicatorWidth;
    for (var side = 0; side < 2; side++) {
      canvas.drawPath(
          bands[side], fill..color = colors[side].withValues(alpha: .14));
      canvas.drawPath(lines[side], stroke..color = colors[side]);
    }
  }
}
