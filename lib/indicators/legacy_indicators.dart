part of 'indicator_calculator.dart';

void _legacy(List<KLineEntity> d, List<double?> close, List<int> periods,
    int bollN, double bollK,
    [IndicatorCalculationCache? cache]) {
  final averages = periods.map((n) => _sma(close, n, cache: cache)).toList();
  final boll = _sma(close, bollN, cache: cache);
  final volume = d.map((c) => _validVolume(c) ? c.vol : null).toList();
  final vol5 = _sma(volume, 5, cache: cache),
      vol10 = _sma(volume, 10, cache: cache);
  final ema12 = _ema(close, 12, cache: cache),
      ema26 = _ema(close, 26, cache: cache);
  final dif = List<double?>.generate(
      d.length,
      (i) =>
          ema12[i] == null || ema26[i] == null ? null : ema12[i]! - ema26[i]!);
  final dea = _ema(dif, 9, cache: cache);
  final gains = List<double?>.filled(d.length, null),
      losses = List<double?>.filled(d.length, null);
  for (var i = 1; i < d.length; i++) {
    if (close[i] != null && close[i - 1] != null) {
      final delta = close[i]! - close[i - 1]!;
      gains[i] = max(delta, 0);
      losses[i] = max(-delta, 0);
    }
  }
  final gain = _ema(gains, 14, wilder: true, cache: cache),
      loss = _ema(losses, 14, wilder: true, cache: cache);
  final start = cache?.start ?? 0;
  var k = start == 0 ? 50.0 : d[start - 1].k ?? 50.0;
  var dd = start == 0 ? 50.0 : d[start - 1].d ?? 50.0;
  for (var i = start; i < d.length; i++) {
    final c = d[i];
    // The legacy public MA list retains its zero sentinel for compatibility.
    // Renderers interpret it as unavailable; typed new values use null.
    c.maValueList = [for (final values in averages) values[i] ?? 0];
    c.BOLLMA = c.mb = boll[i];
    c.up = c.dn = null;
    if (boll[i] != null) {
      var sum = 0.0;
      for (var j = i - bollN + 1; j <= i; j++) {
        final delta = close[j]! - boll[i]!;
        sum += delta * delta;
      }
      final sigma = sqrt(sum / bollN);
      c.up = boll[i]! + bollK * sigma;
      c.dn = boll[i]! - bollK * sigma;
    }
    c.MA5Volume = vol5[i];
    c.MA10Volume = vol10[i];
    c.dif = dif[i];
    c.dea = dea[i];
    c.macd = dif[i] == null || dea[i] == null ? null : 2 * (dif[i]! - dea[i]!);
    c.rsi = gain[i] == null || loss[i] == null
        ? null
        : gain[i] == 0 && loss[i] == 0
            ? 50
            : loss[i] == 0
                ? 100
                : 100 * gain[i]! / (gain[i]! + loss[i]!);
    c.k = c.d = c.j = c.r = c.cci = null;
    if (i >= 8 && _validPriceWindow(d, i - 8, i)) {
      var hi = d[i - 8].high, lo = d[i - 8].low;
      for (var j = i - 7; j <= i; j++) {
        hi = max(hi, d[j].high);
        lo = min(lo, d[j].low);
      }
      final rsv = hi == lo ? 50.0 : 100 * (c.close - lo) / (hi - lo);
      k = (2 * k + rsv) / 3;
      dd = (2 * dd + k) / 3;
      c.k = k;
      c.d = dd;
      c.j = 3 * k - 2 * dd;
    } else {
      k = dd = 50;
    }
    if (i >= 13 && _validPriceWindow(d, i - 13, i)) {
      var hi = d[i - 13].high, lo = d[i - 13].low;
      double typical(int j) => (d[j].high + d[j].low + d[j].close) / 3;
      var total = typical(i - 13);
      for (var j = i - 12; j <= i; j++) {
        hi = max(hi, d[j].high);
        lo = min(lo, d[j].low);
        total += typical(j);
      }
      c.r = hi == lo ? null : -100 * (hi - c.close) / (hi - lo);
      final mean = total / 14;
      var absoluteDeviation = (typical(i - 13) - mean).abs();
      for (var j = i - 12; j <= i; j++) {
        absoluteDeviation += (typical(j) - mean).abs();
      }
      final deviation = absoluteDeviation / 14;
      c.cci = deviation == 0 ? 0 : (typical(i) - mean) / (0.015 * deviation);
    }
  }
  _sar(d);
}

void _sar(List<KLineEntity> d) {
  for (final c in d) {
    c.sar = null;
  }
  var start = 0;
  while (start < d.length) {
    while (start < d.length && !_validPrice(d[start])) {
      start++;
    }
    var end = start;
    while (end < d.length && _validPrice(d[end])) {
      end++;
    }
    if (end - start >= 2) {
      _sarSegment(d.sublist(start, end));
    }
    start = end;
  }
}

void _sarSegment(List<KLineEntity> d) {
  for (final c in d) {
    c.sar = null;
  }
  if (d.length < 2) return;
  var rising = d[1].close >= d[0].close;
  var ep = rising ? max(d[0].high, d[1].high) : min(d[0].low, d[1].low);
  var sar = rising ? min(d[0].low, d[1].low) : max(d[0].high, d[1].high);
  var acceleration = 0.02;
  if (_validPrice(d[0]) && _validPrice(d[1])) d[1].sar = sar;
  for (var i = 2; i < d.length; i++) {
    if (!_validPrice(d[i]) ||
        !_validPrice(d[i - 1]) ||
        !_validPrice(d[i - 2])) {
      continue;
    }
    sar += acceleration * (ep - sar);
    if (rising) {
      sar = min(sar, min(d[i - 1].low, d[i - 2].low));
      if (d[i].low < sar) {
        rising = false;
        sar = ep;
        ep = d[i].low;
        acceleration = 0.02;
      } else if (d[i].high > ep) {
        ep = d[i].high;
        acceleration = min(0.2, acceleration + 0.02);
      }
    } else {
      sar = max(sar, max(d[i - 1].high, d[i - 2].high));
      if (d[i].high > sar) {
        rising = true;
        sar = ep;
        ep = d[i].high;
        acceleration = 0.02;
      } else if (d[i].low < ep) {
        ep = d[i].low;
        acceleration = min(0.2, acceleration + 0.02);
      }
    }
    d[i].sar = sar;
  }
}
