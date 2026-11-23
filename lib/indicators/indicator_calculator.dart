import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';
import '../entity/k_line_entity.dart';
import 'indicator_values.dart';

part 'main_indicators.dart';
part 'secondary_indicators.dart';
part 'legacy_indicators.dart';
part 'indicator_buffer.dart';
part 'indicator_calculation_cache.dart';

/// Explicit candle interval is needed for reliable UTC session completeness.
class IndicatorContext {
  const IndicatorContext(
      {this.interval,
      this.lastCandleClosed = false,
      this.quoteAmountReliable = false});
  final Duration? interval;
  final bool lastCandleClosed;
  final bool quoteAmountReliable;
}

class IndicatorCalculator {
  /// Volume diagnostics can update averages without discarding price context.
  static void calculateVolumeMA(List<KLineEntity> data) {
    final volume = data.map((c) => _validVolume(c) ? c.vol : null).toList();
    final fast = _sma(volume, 5), slow = _sma(volume, 10);
    for (var i = 0; i < data.length; i++) {
      data[i].MA5Volume = fast[i];
      data[i].MA10Volume = slow[i];
    }
  }

  static void calculate(
    List<KLineEntity> candles, {
    IndicatorContext context = const IndicatorContext(),
    List<int> maPeriods = const [5, 10, 20],
    int bollPeriod = 20,
    double bollMultiplier = 2,
    IndicatorCalculationCache? cache,
  }) {
    cache?.prepare(candles, context, maPeriods, bollPeriod, bollMultiplier);
    final start = cache?.start ?? 0;
    for (var index = start; index < candles.length; index++) {
      final c = candles[index];
      c.indicators = c.time == null
          ? const IndicatorValues({}, unavailableReason: 'invalidTimestamp')
          : const IndicatorValues({});
      if (c.time == null) {
        c.maValueList = null;
        c.sar = c.BOLLMA = c.mb = c.up = c.dn = null;
        c.MA5Volume = c.MA10Volume = null;
        c.macd = c.dif = c.dea = null;
        c.k = c.d = c.j = c.rsi = c.r = c.cci = null;
      }
    }
    // Do not rearrange the caller's list or manufacture missing candles. Latest
    // duplicate timestamp wins for calculations, then shares values with peers.
    final byTime = <int, KLineEntity>{};
    for (final c in candles) {
      if (c.time != null) byTime[c.time!] = c;
    }
    final data = byTime.values.toList()
      ..sort((a, b) => a.time!.compareTo(b.time!));
    final output = List<Map<IndicatorLine, double?>>.generate(data.length,
        (i) => i < start ? data[i].indicators.values : _IndicatorBuffer());
    final close = data.map((c) => _validPrice(c) ? c.close : null).toList();
    _legacy(data, close, maPeriods, bollPeriod, bollMultiplier, cache);
    _main(data, close, output, context, cache);
    _secondary(data, close, output, cache);
    for (var i = start; i < data.length; i++) {
      data[i].indicators = IndicatorValues(UnmodifiableMapView(output[i]),
          unavailableReason: data[i].indicators.unavailableReason,
          sessionAverageEstimated: data[i].indicators.sessionAverageEstimated);
    }
    for (final c in candles) {
      final source = byTime[c.time];
      if (source != null && !identical(c, source)) {
        final snapshot = source.snapshot();
        c.indicators = snapshot.indicators;
        c.maValueList = snapshot.maValueList;
        c.mb = source.mb;
        c.up = source.up;
        c.dn = source.dn;
        c.sar = source.sar;
        c.MA5Volume = source.MA5Volume;
        c.MA10Volume = source.MA10Volume;
        c.macd = source.macd;
        c.dif = source.dif;
        c.dea = source.dea;
        c.k = source.k;
        c.d = source.d;
        c.j = source.j;
        c.rsi = source.rsi;
        c.r = source.r;
        c.cci = source.cci;
      }
    }
  }
}

bool _validPrice(KLineEntity c) =>
    // This guard runs inside rolling windows: allocating a list here creates
    // hundreds of thousands of short-lived objects per history calculation.
    c.open.isFinite &&
    c.open >= 0 &&
    c.close.isFinite &&
    c.close >= 0 &&
    c.high.isFinite &&
    c.high >= 0 &&
    c.low.isFinite &&
    c.low >= 0 &&
    c.high >= c.low;
bool _validVolume(KLineEntity c) =>
    c.volumeValid && c.vol.isFinite && c.vol >= 0;

double? _sum(List<double?> values, int i, int n) {
  if (n <= 0 || i < n - 1) return null;
  var result = 0.0;
  for (var j = i - n + 1; j <= i; j++) {
    final v = values[j];
    if (v == null || !v.isFinite) return null;
    result += v;
  }
  return result;
}

List<double?> _sma(List<double?> v, int n, {IndicatorCalculationCache? cache}) {
  final out = cache?.next(v.length) ?? List<double?>.filled(v.length, null);
  for (var i = cache?.start ?? 0; i < v.length; i++) {
    final s = _sum(v, i, n);
    out[i] = s == null ? null : s / n;
  }
  return out;
}

List<double?> _ema(List<double?> v, int n,
    {bool wilder = false, IndicatorCalculationCache? cache}) {
  final out = cache?.next(v.length) ?? List<double?>.filled(v.length, null);
  final start = cache?.start ?? 0;
  double? previous = start == 0 ? null : out[start - 1];
  for (var i = start; i < v.length; i++) {
    if (v[i] == null) {
      previous = out[i] = null;
      continue;
    }
    if (previous == null) {
      final s = _sum(v, i, n);
      if (s != null) previous = s / n;
    } else {
      previous += (v[i]! - previous) * (wilder ? 1 / n : 2 / (n + 1));
    }
    out[i] = previous;
  }
  return out;
}

List<double?> _midpoint(List<KLineEntity> data, int n,
    {IndicatorCalculationCache? cache}) {
  final out =
      cache?.next(data.length) ?? List<double?>.filled(data.length, null);
  for (var i = cache?.start ?? 0; i < data.length; i++) {
    out[i] = null;
    if (i < n - 1) continue;
    var hi = -double.infinity, lo = double.infinity;
    var valid = true;
    for (var j = i - n + 1; j <= i; j++) {
      if (!_validPrice(data[j])) {
        valid = false;
        break;
      }
      hi = max(hi, data[j].high);
      lo = min(lo, data[j].low);
    }
    if (valid) out[i] = (hi + lo) / 2;
  }
  return out;
}

void _put(List<Map<IndicatorLine, double?>> out, IndicatorLine line,
    List<double?> values) {
  for (var i = 0; i < out.length; i++) {
    if (out[i] is! _IndicatorBuffer) continue;
    final v = values[i];
    out[i][line] = v != null && v.isFinite ? v : null;
  }
}

// Window validation avoids allocating sublists in each rolling calculation.
bool _validPriceWindow(List<KLineEntity> data, int start, int stop) {
  for (var i = start; i <= stop; i++) {
    if (!_validPrice(data[i])) return false;
  }
  return true;
}
