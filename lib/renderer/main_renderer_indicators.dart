part of 'main_renderer.dart';

extension _MainRendererIndicators on MainRenderer {
  Color _indicatorColor(int index) => switch (index) {
        0 => chartColors.ma5Color,
        1 => chartColors.ma10Color,
        2 => chartColors.ma30Color,
        3 => chartColors.macdColor,
        _ => chartColors.avgColor,
      };

  String _indicatorFormat(IndicatorSeries s) {
    final value = s.displayValue(valueType, mcapFactor);
    if (value == null || !value.isFinite) return '--';
    return valueType == ChartValueType.marketCap && mcapFormatter != null
        ? mcapFormatter!(value)
        : format(value);
  }

  String _seriesLabel(IndicatorSeries series, KLineEntity candle) {
    if (indicatorTextFormatter == null ||
        (!series.label.startsWith('AVL UTC') &&
            !series.label.startsWith('VWAP UTC'))) {
      return series.label;
    }
    final prefix = series.label.startsWith('AVL') ? 'AVL UTC' : 'VWAP UTC';
    final key = candle.indicators.sessionAverageEstimated
        ? 'estimatedAverage'
        : 'quoteBaseAverage';
    return '$prefix (${indicatorTextFormatter!(key)})';
  }

  void drawIndicatorLabels(Canvas canvas, KLineEntity c, double x) {
    final rects = <Rect>[];
    // 行距按实际文本高度累加：固定 12px 小于字体行高，相邻两行文字会重叠。
    var dy = chartRect.top;
    for (var row = 0; row < stateLi.length; row++) {
      final state = stateLi[row];
      final series = _seriesAt(state, c);
      final reason = (state == MainState.AVL || state == MainState.VWAP)
          ? c.indicators.unavailableReason
          : null;
      final spans = [
        for (var i = 0; i < series.length; i++)
          TextSpan(
              text:
                  '${_seriesLabel(series[i], c)}:${_indicatorFormat(series[i])}    ',
              style: getTextStyle(_indicatorColor(i))),
        if (reason != null)
          TextSpan(
              text:
                  '(${indicatorTextFormatter?.call(reason) ?? indicatorUnavailableText(reason)})',
              style: getTextStyle(chartColors.defaultTextColor))
      ];
      final tp = layoutText(TextSpan(children: spans));
      // 标签无底色，直接叠在主图上；绘制顺序保证其仍位于虚线、标签之上。
      final rect = Rect.fromLTWH(x - 2, dy, tp.width + 4, tp.height);
      tp.paint(canvas, Offset(x, dy));
      rects.add(rect);
      dy += tp.height;
    }
    debugIndicatorLabelRects = rects;
  }

  int? _candleIndex(KLineEntity candle) {
    final data = chartData;
    if (data == null || candle.time == null) return null;
    var lo = 0, hi = data.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) ~/ 2, time = data[mid].time;
      if (time == null) return null;
      if (time == candle.time) return mid;
      if (time < candle.time!) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return null;
  }

  List<IndicatorSeries> _seriesAt(MainState state, KLineEntity candle) {
    if (state != MainState.ICHI) {
      return mainIndicatorSeries(state, candle, maPeriods: maDayList);
    }
    final index = _candleIndex(candle);
    return index == null
        ? mainIndicatorSeries(state, candle, maPeriods: maDayList)
        : mainIndicatorSeriesAt(state, index, chartData!, maPeriods: maDayList);
  }

  void drawIndicators(KLineEntity last, KLineEntity cur, double lastX,
      double curX, Canvas canvas) {
    final hasIchimoku = stateLi.contains(MainState.ICHI);
    final index = hasIchimoku ? _candleIndex(cur) : null;
    final lastIndex = hasIchimoku ? _candleIndex(last) : null;
    for (final state in stateLi) {
      if (state == MainState.VWAP && stateLi.contains(MainState.AVL)) {
        continue;
      }
      if (state == MainState.SAR) {
        if (cur.sar != null) {
          drawCircle(canvas, curX, cur.sar!, chartColors.sarColor);
        }
        continue;
      }
      if (state == MainState.SUPER) {
        _drawSuperTrend(last, cur, lastX, curX, canvas);
        continue;
      }
      final count = mainIndicatorLineCount(state, maCount: maDayList.length);
      for (var i = 0; i < count; i++) {
        final a = state == MainState.ICHI && lastIndex != null
            ? mainIndicatorValueAt(state, lastIndex, chartData!, i)
            : mainIndicatorValue(state, last, i);
        final b = state == MainState.RESIST && chartData?.isNotEmpty == true
            ? mainIndicatorValue(state, chartData!.last, i)
            : state == MainState.ICHI && index != null
                ? mainIndicatorValueAt(state, index, chartData!, i)
                : mainIndicatorValue(state, cur, i);
        if (state == MainState.RESIST) {
          if (b == null || !b.isFinite) {
            continue;
          }
          final paint = Paint()
            ..color = _indicatorColor(i)
            ..strokeWidth = _indicatorWidth;
          final dash = 4 / scaleX;
          for (var x = lastX; x < curX; x += dash * 2) {
            canvas.drawLine(Offset(x, getY(b)),
                Offset((x + dash).clamp(lastX, curX), getY(b)), paint);
          }
        } else {
          final shift = chartData == null
              ? mainIndicatorOffset(state, i) * (curX - lastX)
              : 0.0;
          drawLine(
              a, b, canvas, lastX + shift, curX + shift, _indicatorColor(i),
              lineWidth: _indicatorWidth);
        }
      }
      if (state == MainState.ICHI && chartData != null) {
        if (index != null &&
            lastIndex != null &&
            index >= 26 &&
            lastIndex >= 26) {
          _drawCloud(chartData![lastIndex - 26], chartData![index - 26], lastX,
              curX, canvas);
        }
        // Draw the cloud into the future reserve without adding data candles.
        if (index != null && index + 26 >= chartData!.length) {
          final shift = 26 * (curX - lastX);
          for (final line in [IndicatorLine.senkouA, IndicatorLine.senkouB]) {
            drawLine(
                last.indicators[line],
                cur.indicators[line],
                canvas,
                lastX + shift,
                curX + shift,
                chartColors.getMAColor(line == IndicatorLine.senkouA ? 2 : 3),
                lineWidth: _indicatorWidth);
          }
          _drawCloud(last, cur, lastX + shift, curX + shift, canvas);
        }
      }
    }
  }

  /// SuperTrend 按主流行情软件（TradingView 内置脚本）的画法：
  /// - 多头时趋势线在价格下方用蓝色，空头时在上方用橙色；
  /// - 趋势翻转处断开，不画连接上下轨的竖线；
  /// - 趋势线与 K 线实体中点 (open+close)/2 之间按方向填充半透明色带。
  /// 参数保持 ATR(10) × 3。收盘价不低于趋势线即为多头（翻转规则保证二者等价）。
  void _drawSuperTrend(KLineEntity last, KLineEntity cur, double lastX,
      double curX, Canvas canvas) {
    final a = last.indicators[IndicatorLine.superTrend];
    final b = cur.indicators[IndicatorLine.superTrend];
    if (a == null || b == null || !a.isFinite || !b.isFinite) return;
    final bullish = cur.close >= b;
    if ((last.close >= a) != bullish || lastX == curX) return;
    final color =
        bullish ? chartColors.superTrendUpColor : chartColors.superTrendDnColor;
    final lastMid = (last.open + last.close) / 2;
    final curMid = (cur.open + cur.close) / 2;
    final band = Path()
      ..moveTo(lastX, getY(a))
      ..lineTo(curX, getY(b))
      ..lineTo(curX, getY(curMid))
      ..lineTo(lastX, getY(lastMid))
      ..close();
    canvas.drawPath(band, Paint()..color = color.withValues(alpha: 0.14));
    drawLine(a, b, canvas, lastX, curX, color, lineWidth: _indicatorWidth);
  }

  void _drawCloud(KLineEntity last, KLineEntity cur, double lastX, double curX,
      Canvas canvas) {
    final a = last.indicators[IndicatorLine.senkouA],
        b = last.indicators[IndicatorLine.senkouB];
    final c = cur.indicators[IndicatorLine.senkouA],
        d = cur.indicators[IndicatorLine.senkouB];
    if (a == null || b == null || c == null || d == null) return;
    final path = Path()
      ..moveTo(lastX, getY(a))
      ..lineTo(curX, getY(c))
      ..lineTo(curX, getY(d))
      ..lineTo(lastX, getY(b))
      ..close();
    canvas.drawPath(
        path,
        Paint()
          ..color = (c >= d ? chartColors.upColor : chartColors.dnColor)
              .withValues(alpha: 0.12));
  }
}
