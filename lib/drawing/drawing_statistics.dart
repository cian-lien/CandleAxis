import 'dart:math' as math;
import '../entity/k_line_entity.dart';

class DrawingRangeStatistics {
  const DrawingRangeStatistics(
      {required this.startTime,
      required this.endTime,
      required this.count,
      required this.startValue,
      required this.endValue,
      required this.high,
      required this.low,
      required this.volume,
      this.amount,
      this.includesUnclosed = false});
  final int? startTime, endTime;
  final int count;
  final double? startValue, endValue, high, low, volume, amount;
  final bool includesUnclosed;
  double? get change =>
      startValue == null || endValue == null ? null : endValue! - startValue!;
  double? get changePercent => startValue == null || startValue == 0
      ? null
      : change! / startValue! * 100;

  /// Host explicitly supplies reliable quote amounts. KLineEntity.amount is
  /// deliberately not assumed to be quote USD volume without a source contract.
  static DrawingRangeStatistics calculate(
      List<KLineEntity> candles, int start, int end,
      {bool latestClosed = false,
      double? Function(KLineEntity)? reliableQuoteAmount}) {
    final unique = <int, KLineEntity>{};
    for (final c in candles) {
      if (c.time != null &&
          [c.open, c.close, c.high, c.low].every((p) => p.isFinite)) {
        unique[c.time!] = c;
      }
    }
    final selected = unique.values
        .where((c) =>
            c.time! >= math.min(start, end) && c.time! <= math.max(start, end))
        .toList()
      ..sort((a, b) => a.time!.compareTo(b.time!));
    if (selected.isEmpty) {
      return const DrawingRangeStatistics(
          startTime: null,
          endTime: null,
          count: 0,
          startValue: null,
          endValue: null,
          high: null,
          low: null,
          volume: null);
    }
    var volume = 0.0, amount = 0.0;
    bool validVolume = true, validAmount = reliableQuoteAmount != null;
    for (final c in selected) {
      if (!c.volumeValid || !c.vol.isFinite || c.vol < 0) {
        validVolume = false;
      } else {
        volume += c.vol;
      }
      final quote = reliableQuoteAmount?.call(c);
      if (quote == null || !quote.isFinite || quote < 0) {
        validAmount = false;
      } else {
        amount += quote;
      }
    }
    return DrawingRangeStatistics(
        startTime: selected.first.time,
        endTime: selected.last.time,
        count: selected.length,
        startValue: selected.first.open,
        endValue: selected.last.close,
        high: selected.map((c) => c.high).reduce(math.max),
        low: selected.map((c) => c.low).reduce(math.min),
        volume: validVolume ? volume : null,
        amount: validAmount ? amount : null,
        includesUnclosed: !latestClosed &&
            candles.isNotEmpty &&
            selected.any((c) => c.time == candles.last.time));
  }

  DrawingRangeStatistics scaled(double factor) {
    if (!factor.isFinite || factor <= 0) {
      throw ArgumentError.value(factor, 'factor');
    }
    return DrawingRangeStatistics(
        startTime: startTime,
        endTime: endTime,
        count: count,
        startValue: startValue == null ? null : startValue! * factor,
        endValue: endValue == null ? null : endValue! * factor,
        high: high == null ? null : high! * factor,
        low: low == null ? null : low! * factor,
        volume: volume,
        amount: amount,
        includesUnclosed: includesUnclosed);
  }
}
