import 'package:flutter/material.dart';

import '../chart_types.dart';
import '../entity/k_line_entity.dart';
import '../entity/macd_entity.dart';
import '../indicators/indicator_presentation.dart';
import '../indicators/indicator_values.dart';
import 'base_chart_renderer.dart';

class SecondaryRenderer extends BaseChartRenderer<MACDEntity> {
  SecondaryRenderer(
      Rect mainRect,
      double maxValue,
      double minValue,
      double topPadding,
      this.state,
      int fixedLength,
      this.chartStyle,
      this.chartColors,
      this.scaleX,
      [PriceFormatter? priceFormatter,
      this.valueType = ChartValueType.price,
      this.mcapFactor = 1,
      this.mcapFormatter])
      : super(
            chartRect: mainRect,
            maxValue: maxValue,
            minValue: minValue,
            topPadding: topPadding,
            fixedLength: fixedLength,
            gridColor: chartColors.gridColor,
            priceFormatter: priceFormatter);
  SecondaryState state;
  final ChartStyle chartStyle;
  final ChartColors chartColors;
  final double scaleX;
  final ChartValueType valueType;
  final double mcapFactor;
  final PriceFormatter? mcapFormatter;
  double get mMACDWidth => chartStyle.macdWidth;

  double _calculateSecondaryIndicatorWidth() {
    if (!chartStyle.enableDynamicSecondaryIndicatorWidth) {
      return chartStyle.secondaryIndicatorBaseWidth;
    }
    final width = chartStyle.secondaryIndicatorBaseWidth / scaleX;
    final cap = chartStyle.secondaryIndicatorMaxWidth < mMACDWidth
        ? chartStyle.secondaryIndicatorMaxWidth
        : mMACDWidth;
    return width > cap ? cap : width;
  }

  Color _color(int i) => switch (i) {
        0 => chartColors.kColor,
        1 => chartColors.dColor,
        2 => chartColors.jColor,
        _ => chartColors.macdColor,
      };

  /// One stroke path per series, with independent subpaths preserving caps and
  /// missing-value gaps. Impeller expands drawRawPoints(lines) into individual
  /// DrawLine calls, so batching points alone does not reduce raster work.
  void drawSeries(List<KLineEntity> data, int start, int stop,
      double pointWidth, Canvas canvas,
      {SecondarySeriesCache? cache, List<KLineEntity>? historySource}) {
    if (start > stop) return;
    final count = secondaryIndicatorLineCount(state);
    // History stays fixed during a last-candle animation. A replacement painter
    // (including in-place host updates) owns a fresh cache.
    final historyStop = stop < data.length - 1 ? stop : stop - 1;
    final key =
        (state, start, historyStop, pointWidth, chartRect, maxValue, minValue);
    final reuse = historySource != null &&
        cache != null &&
        identical(cache.source, historySource) &&
        cache.key == key;
    final paths = reuse
        ? cache.paths
        : _linePaths(data, start, historyStop, pointWidth, count);
    if (historySource != null && cache != null && !reuse) {
      cache
        ..source = historySource
        ..key = key
        ..paths = paths;
    }
    if (state == SecondaryState.MACD) {
      for (var index = start; index <= stop; index++) {
        final value = data[index].macd;
        if (value == null || !value.isFinite) continue;
        final x = index * pointWidth + pointWidth / 2;
        final y = getY(value), zero = getY(0);
        canvas.drawRect(
            Rect.fromLTRB(x - mMACDWidth / 2, y < zero ? y : zero,
                x + mMACDWidth / 2, y > zero ? y : zero),
            chartPaint
              ..color = value >= 0 ? chartColors.upColor : chartColors.dnColor);
      }
    }
    final tail = stop > historyStop
        ? _linePaths(data, stop, stop, pointWidth, count)
        : null;
    final linePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = _calculateSecondaryIndicatorWidth();
    for (var line = 0; line < paths.length; line++) {
      final paint = linePaint..color = _color(line);
      final path = paths[line];
      if (path != null) canvas.drawPath(path, paint);
      final last = tail?[line];
      if (last != null) canvas.drawPath(last, paint);
    }
  }

  List<Path?> _linePaths(List<KLineEntity> data, int start, int stop,
      double pointWidth, int count) {
    final paths = List<Path?>.filled(count, null);
    for (var index = start; index <= stop; index++) {
      final previous = data[index == 0 ? 0 : index - 1], current = data[index];
      final x = index * pointWidth + pointWidth / 2;
      for (var line = state == SecondaryState.MACD ? 1 : 0;
          line < count;
          line++) {
        final a = secondaryIndicatorValue(state, previous, line);
        final b = secondaryIndicatorValue(state, current, line);
        if (a == null || b == null || !a.isFinite || !b.isFinite) continue;
        (paths[line] ??= Path())
          ..moveTo(index == 0 ? x : x - pointWidth, getY(a))
          ..lineTo(x, getY(b));
      }
    }
    return paths;
  }

  @override
  void drawChart(MACDEntity lastPoint, MACDEntity curPoint, double lastX,
      double curX, Size size, Canvas canvas) {
    if (lastPoint is! KLineEntity || curPoint is! KLineEntity) return;
    final previous = secondaryIndicatorSeries(state, lastPoint),
        current = secondaryIndicatorSeries(state, curPoint);
    final width = _calculateSecondaryIndicatorWidth();
    for (var i = 0; i < current.length; i++) {
      if (state == SecondaryState.MACD && i == 0) {
        final v = current[i].value;
        if (v == null || !v.isFinite) continue;
        final y = getY(v), zero = getY(0);
        canvas.drawRect(
            Rect.fromLTRB(curX - mMACDWidth / 2, y < zero ? y : zero,
                curX + mMACDWidth / 2, y > zero ? y : zero),
            chartPaint
              ..color = v >= 0 ? chartColors.upColor : chartColors.dnColor);
      } else {
        drawLine(
            previous[i].value, current[i].value, canvas, lastX, curX, _color(i),
            lineWidth: width);
      }
    }
  }

  String indicatorValueText(IndicatorSeries s) {
    final value = s.displayValue(valueType, mcapFactor);
    if (value == null || !value.isFinite) return '--';
    // Oscillators and volumes never use the host's price or market cap formatter.
    if (s.unit != IndicatorUnit.price) {
      final rounded = value.toStringAsFixed(2);
      return value != 0 && double.parse(rounded) == 0
          ? value.toStringAsExponential(3)
          : rounded;
    }
    return valueType == ChartValueType.marketCap && mcapFormatter != null
        ? mcapFormatter!(value)
        : format(value);
  }

  @override
  void drawText(Canvas canvas, MACDEntity data, double x) {
    if (data is! KLineEntity) return;
    final values = secondaryIndicatorSeries(state, data);
    final tp = layoutText(TextSpan(children: [
      for (var i = 0; i < values.length; i++)
        TextSpan(
            text: '${values[i].label}:${indicatorValueText(values[i])}    ',
            style: getTextStyle(_color(i)))
    ]));
    tp.paint(canvas, Offset(x, chartRect.top - topPadding));
  }

  @override
  void drawVerticalText(dynamic canvas, dynamic textStyle, int gridRows) {
    final unit = switch (state) {
      SecondaryState.MACD ||
      SecondaryState.DMA ||
      SecondaryState.MTM =>
        IndicatorUnit.price,
      SecondaryState.OBV => IndicatorUnit.volume,
      SecondaryState.ROC => IndicatorUnit.percentage,
      SecondaryState.EMV => IndicatorUnit.priceSquaredPerVolume,
      _ => IndicatorUnit.oscillator,
    };
    final maxTp = layoutText(TextSpan(
        text: indicatorValueText(IndicatorSeries('', maxValue, unit: unit)),
        style: textStyle));
    final minTp = layoutText(TextSpan(
        text: indicatorValueText(IndicatorSeries('', minValue, unit: unit)),
        style: textStyle));
    maxTp.paint(canvas,
        Offset(chartRect.width - maxTp.width - 10, chartRect.top - topPadding));
    minTp.paint(
        canvas,
        Offset(chartRect.width - minTp.width - 10,
            chartRect.bottom - minTp.height));
  }

  @override
  void drawGrid(Canvas canvas, int gridRows, int gridColumns) {
    canvas.drawLine(Offset(0, chartRect.bottom),
        Offset(chartRect.width, chartRect.bottom), gridPaint);
    final space = chartRect.width / gridColumns;
    for (var i = 0; i <= gridColumns; i++) {
      canvas.drawLine(Offset(space * i, chartRect.top - topPadding),
          Offset(space * i, chartRect.bottom), gridPaint);
    }
  }
}

/// Owned by one painter/input revision; no app-level or global state.
class SecondarySeriesCache {
  List<KLineEntity>? source;
  Object? key;
  List<Path?> paths = const [];
}
