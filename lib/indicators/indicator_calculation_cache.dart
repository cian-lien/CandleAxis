part of 'indicator_calculator.dart';

/// Worker-owned checkpoint. Reuse only with isolated lists; the unchanged
/// prefix belongs to this calculator, never to callers on the UI isolate.
class IndicatorCalculationCache {
  List<KLineEntity>? _previous;
  Object? _configuration;
  bool _eligible = false;
  int start = 0, _cursor = 0;
  final _series = <List<double?>>[];

  void prepare(List<KLineEntity> data, IndicatorContext context,
      List<int> periods, int bollPeriod, double multiplier) {
    final configuration = (
      context.interval,
      context.lastCandleClosed,
      context.quoteAmountReliable,
      periods.join(','),
      bollPeriod,
      multiplier
    );
    var eligible = !context.quoteAmountReliable && data.isNotEmpty;
    for (var i = 0; eligible && i < data.length; i++) {
      final time = data[i].time;
      eligible = time != null && (i == 0 || time > data[i - 1].time!);
    }
    start = 0;
    _cursor = 0;
    final previous = _previous;
    if (eligible &&
        _eligible &&
        configuration == _configuration &&
        previous != null) {
      final limit = min(data.length, previous.length);
      while (start < limit && _sameInput(data[start], previous[start])) {
        start++;
      }
      // Appending/shortening changes the implicit closed state of the old/new
      // last candle, even if all explicit input fields remain identical.
      start = min(start, max(0, limit - 1));
      for (var i = 0; i < start; i++) {
        data[i] = previous[i];
      }
    }
    _eligible = eligible;
    _configuration = configuration;
    _previous = data;
  }

  List<double?> next(int length) {
    final slot = _cursor++;
    if (slot == _series.length) {
      _series.add(List<double?>.filled(length, null));
    } else if (_series[slot].length != length) {
      final old = _series[slot];
      _series[slot] = List<double?>.filled(length, null)
        ..setRange(0, min(start, old.length), old);
    }
    return _series[slot];
  }

  bool _sameInput(KLineEntity a, KLineEntity b) =>
      a.time == b.time &&
      _sameNumber(a.open, b.open) &&
      _sameNumber(a.high, b.high) &&
      _sameNumber(a.low, b.low) &&
      _sameNumber(a.close, b.close) &&
      _sameNumber(a.vol, b.vol) &&
      _sameNumber(a.amount, b.amount) &&
      _sameNumber(a.change, b.change) &&
      _sameNumber(a.ratio, b.ratio) &&
      a.volumeValid == b.volumeValid &&
      a.isClosed == b.isClosed &&
      _sameNumber(a.openMcap, b.openMcap) &&
      _sameNumber(a.highMcap, b.highMcap) &&
      _sameNumber(a.lowMcap, b.lowMcap) &&
      _sameNumber(a.closeMcap, b.closeMcap);

  bool _sameNumber(double? a, double? b) =>
      a == b && (a != 0 || a!.isNegative == b!.isNegative);
}
