part of 'indicator_calculator.dart';

void _main(List<KLineEntity> d, List<double?> close,
    List<Map<IndicatorLine, double?>> o, IndicatorContext context,
    [IndicatorCalculationCache? cache]) {
  for (final entry in {
    IndicatorLine.ema5: 5,
    IndicatorLine.ema10: 10,
    IndicatorLine.ema20: 20
  }.entries) {
    _put(o, entry.key, _ema(close, entry.value, cache: cache));
  }
  final tenkan = _midpoint(d, 9, cache: cache),
      kijun = _midpoint(d, 26, cache: cache),
      spanB = _midpoint(d, 52, cache: cache);
  _put(o, IndicatorLine.tenkan, tenkan);
  _put(o, IndicatorLine.kijun, kijun);
  _put(o, IndicatorLine.senkouB, spanB);
  _put(o, IndicatorLine.chikou, close);
  _put(
      o,
      IndicatorLine.senkouA,
      List.generate(
          d.length,
          (i) => tenkan[i] == null || kijun[i] == null
              ? null
              : (tenkan[i]! + kijun[i]!) / 2));
  _superTrend(d, o, cache);
  _resist(d, o, context);
  _sessionAverage(d, o, context);
}

void _superTrend(List<KLineEntity> d, List<Map<IndicatorLine, double?>> o,
    [IndicatorCalculationCache? cache]) {
  final tr = List<double?>.generate(d.length, (i) {
    if (!_validPrice(d[i])) return null;
    if (i == 0) return d[i].high - d[i].low;
    if (!_validPrice(d[i - 1])) return null;
    return max(
        d[i].high - d[i].low,
        max((d[i].high - d[i - 1].close).abs(),
            (d[i].low - d[i - 1].close).abs()));
  });
  final atr = _ema(tr, 10, wilder: true, cache: cache);
  double? upper, lower, trend;
  for (var i = 0; i < d.length; i++) {
    if (atr[i] == null) {
      upper = lower = trend = null;
      continue;
    }
    final middle = (d[i].high + d[i].low) / 2;
    final basicUpper = middle + 3 * atr[i]!, basicLower = middle - 3 * atr[i]!;
    if (trend == null) {
      upper = basicUpper;
      lower = basicLower;
      trend = upper;
    } else {
      final prevUpper = upper!, prevLower = lower!;
      upper = basicUpper < prevUpper || d[i - 1].close > prevUpper
          ? basicUpper
          : prevUpper;
      lower = basicLower > prevLower || d[i - 1].close < prevLower
          ? basicLower
          : prevLower;
      trend = trend == prevUpper
          ? (d[i].close > upper ? lower : upper)
          : (d[i].close < lower ? upper : lower);
    }
    if (o[i] is _IndicatorBuffer) o[i][IndicatorLine.superTrend] = trend;
  }
}

void _resist(List<KLineEntity> d, List<Map<IndicatorLine, double?>> o,
    IndicatorContext context) {
  double? resistance, support;
  for (var t = 0; t < d.length; t++) {
    final i = t - 2;
    final rightClosed =
        (d[t].isClosed ?? (t < d.length - 1 || context.lastCandleClosed)) &&
            (t < 1 || (d[t - 1].isClosed ?? true));
    if (i >= 2 && rightClosed && _validPriceWindow(d, i - 2, t)) {
      final c = d[i];
      if (c.high >= d[i - 1].high &&
          c.high >= d[i - 2].high &&
          c.high > d[i + 1].high &&
          c.high > d[i + 2].high) {
        resistance = c.high;
      }
      if (c.low <= d[i - 1].low &&
          c.low <= d[i - 2].low &&
          c.low < d[i + 1].low &&
          c.low < d[i + 2].low) {
        support = c.low;
      }
    }
    if (o[t] is _IndicatorBuffer) {
      o[t][IndicatorLine.resistance] = resistance;
      o[t][IndicatorLine.support] = support;
    }
  }
}

void _sessionAverage(List<KLineEntity> d, List<Map<IndicatorLine, double?>> o,
    IndicatorContext context) {
  if (d.isEmpty) return;
  final interval = context.interval?.inMilliseconds;
  const dayMs = 86400000;
  int? day, previousTime;
  var complete = false;
  var totalVolume = 0.0, totalAmount = 0.0;
  var exact = false;
  var invalid = false;
  for (var i = 0; i < d.length; i++) {
    final c = d[i], time = c.time!;
    final currentDay = time ~/ dayMs;
    if (day != currentDay) {
      day = currentDay;
      complete = interval != null &&
          interval > 0 &&
          interval < dayMs &&
          time % dayMs == 0;
      totalVolume = totalAmount = 0;
      invalid = false;
      // A session uses one source for its entire cumulative average.
      exact = context.quoteAmountReliable &&
          d.where((v) => v.time! ~/ dayMs == day).every(
              (v) => v.amount != null && v.amount!.isFinite && v.amount! >= 0);
    } else if (interval == null ||
        previousTime == null ||
        time - previousTime != interval) {
      complete = false;
    }
    previousTime = time;
    if (!_validPrice(c) || !_validVolume(c)) invalid = true;
    if (!invalid && complete) {
      totalVolume += c.vol;
      totalAmount += exact ? c.amount! : (c.high + c.low + c.close) / 3 * c.vol;
    }
    final reason = interval == null
        ? 'intervalUnknown'
        : interval >= dayMs
            ? 'intradayOnly'
            : !complete
                ? 'incompleteUtcSession'
                : invalid
                    ? 'invalidVolumeOrPrice'
                    : totalVolume == 0
                        ? 'zeroCumulativeVolume'
                        : null;
    final average = reason == null ? totalAmount / totalVolume : null;
    if (o[i] is! _IndicatorBuffer) continue;
    o[i][IndicatorLine.avl] = average;
    o[i][IndicatorLine.vwap] = average;
    c.indicators = IndicatorValues(const {},
        unavailableReason: reason, sessionAverageEstimated: !exact);
  }
}
