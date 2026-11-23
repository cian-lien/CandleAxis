part of 'indicator_calculator.dart';

void _secondary(List<KLineEntity> d, List<double?> close,
    List<Map<IndicatorLine, double?>> o,
    [IndicatorCalculationCache? cache]) {
  final roc = List<double?>.filled(d.length, null),
      mtm = List<double?>.filled(d.length, null);
  final obv = List<double?>.filled(d.length, null),
      emv = List<double?>.filled(d.length, null);
  final positive = List<double?>.filled(d.length, null),
      negative = List<double?>.filled(d.length, null);
  double? cumulative = 0;
  for (var i = 0; i < d.length; i++) {
    if (i >= 12 && close[i] != null && close[i - 12] != null) {
      mtm[i] = close[i]! - close[i - 12]!;
      if (close[i - 12] != 0) roc[i] = 100 * (close[i]! / close[i - 12]! - 1);
    }
    if (!_validVolume(d[i]) || close[i] == null) {
      cumulative = null;
    } else if (i > 0) {
      if (close[i - 1] == null) cumulative = null;
      if (cumulative != null) {
        cumulative += close[i]! > close[i - 1]!
            ? d[i].vol
            : close[i]! < close[i - 1]!
                ? -d[i].vol
                : 0;
      }
    }
    obv[i] = cumulative;
    if (i > 0 &&
        _validPrice(d[i]) &&
        _validPrice(d[i - 1]) &&
        _validVolume(d[i])) {
      final cur = (d[i].high + d[i].low + d[i].close) / 3,
          prev = (d[i - 1].high + d[i - 1].low + d[i - 1].close) / 3;
      positive[i] = cur > prev ? cur * d[i].vol : 0;
      negative[i] = cur < prev ? cur * d[i].vol : 0;
      if (d[i].vol > 0) {
        emv[i] = ((d[i].high + d[i].low - d[i - 1].high - d[i - 1].low) / 2) *
            (d[i].high - d[i].low) /
            d[i].vol;
      }
    }
  }
  _put(o, IndicatorLine.roc, roc);
  _put(o, IndicatorLine.rocMa, _sma(roc, 6, cache: cache));
  _put(o, IndicatorLine.mtm, mtm);
  _put(o, IndicatorLine.mtmMa, _sma(mtm, 6, cache: cache));
  _put(o, IndicatorLine.obv, obv);
  final emvAverage = _sma(emv, 14, cache: cache);
  _put(o, IndicatorLine.emv, emvAverage);
  _put(o, IndicatorLine.emvMa, _sma(emvAverage, 9, cache: cache));
  final fast = _sma(close, 10, cache: cache),
      slow = _sma(close, 50, cache: cache);
  final dma = List<double?>.generate(d.length,
      (i) => fast[i] == null || slow[i] == null ? null : fast[i]! - slow[i]!);
  _put(o, IndicatorLine.dma, dma);
  _put(o, IndicatorLine.ama, _sma(dma, 10, cache: cache));
  final mfi = List<double?>.generate(d.length, (i) {
    final p = _sum(positive, i, 14), n = _sum(negative, i, 14);
    if (p == null || n == null || p + n == 0) return null;
    return 100 * p / (p + n);
  });
  _put(o, IndicatorLine.mfi, mfi);
  final rsi = d.map((c) => c.rsi).toList();
  final stoch = List<double?>.generate(d.length, (i) {
    if (_sum(rsi, i, 14) == null) return null;
    var hi = rsi[i - 13]!, lo = rsi[i - 13]!;
    for (var j = i - 12; j <= i; j++) {
      hi = max(hi, rsi[j]!);
      lo = min(lo, rsi[j]!);
    }
    return hi == lo ? 50.0 : 100 * (rsi[i]! - lo) / (hi - lo);
  });
  final stochK = _sma(stoch, 3, cache: cache);
  _put(o, IndicatorLine.stochK, stochK);
  _put(o, IndicatorLine.stochD, _sma(stochK, 3, cache: cache));
  _dmi(d, o, cache);
}

void _dmi(List<KLineEntity> d, List<Map<IndicatorLine, double?>> o,
    [IndicatorCalculationCache? cache]) {
  final tr = List<double?>.filled(d.length, null),
      plus = List<double?>.filled(d.length, null),
      minus = List<double?>.filled(d.length, null);
  for (var i = 1; i < d.length; i++) {
    if (!_validPrice(d[i]) || !_validPrice(d[i - 1])) continue;
    final c = d[i], p = d[i - 1];
    final u = c.high - p.high, v = p.low - c.low;
    tr[i] = max(
        c.high - c.low, max((c.high - p.close).abs(), (c.low - p.close).abs()));
    plus[i] = u > 0 && u > v ? u : 0;
    minus[i] = v > 0 && v > u ? v : 0;
  }
  final pdi = List<double?>.filled(d.length, null),
      mdi = List<double?>.filled(d.length, null),
      dx = List<double?>.filled(d.length, null);
  for (var i = 0; i < d.length; i++) {
    final total = _sum(tr, i, 14),
        p = _sum(plus, i, 14),
        m = _sum(minus, i, 14);
    if (total == null || total == 0 || p == null || m == null) continue;
    pdi[i] = 100 * p / total;
    mdi[i] = 100 * m / total;
    dx[i] = p + m == 0 ? 0 : 100 * (p - m).abs() / (p + m);
  }
  final adx = _sma(dx, 6, cache: cache);
  _put(o, IndicatorLine.pdi, pdi);
  _put(o, IndicatorLine.mdi, mdi);
  _put(o, IndicatorLine.adx, adx);
  _put(
      o,
      IndicatorLine.adxr,
      List.generate(
          d.length,
          (i) => i < 6 || adx[i] == null || adx[i - 6] == null
              ? null
              : (adx[i]! + adx[i - 6]!) / 2));
}
