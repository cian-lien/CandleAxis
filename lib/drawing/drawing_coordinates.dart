import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../entity/k_line_entity.dart';
import 'drawing_models.dart';

/// Same horizontal index spacing as the candle painter, with continuous time
/// interpolation across actual data gaps. Prices always remain unscaled.
class DrawingCoordinates {
  DrawingCoordinates(
      {required List<KLineEntity> candles,
      required this.plot,
      required this.pointWidth,
      required this.scaleX,
      required this.translateX,
      required this.minPrice,
      required this.maxPrice,
      this.factor = 1})
      : candles = List.unmodifiable(candles);
  final List<KLineEntity> candles;
  final Rect plot;
  final double pointWidth, scaleX, translateX, minPrice, maxPrice, factor;
  bool get isUsable =>
      candles.isNotEmpty &&
      plot.width > 0 &&
      plot.height > 0 &&
      maxPrice > minPrice &&
      maxPrice.isFinite &&
      minPrice.isFinite &&
      scaleX > 0 &&
      factor.isFinite &&
      factor > 0;
  double _timeAt(int index) => (candles[index].time ?? 0).toDouble();
  double _indexForTime(int time) {
    if (candles.length == 1) return (time - _timeAt(0)) / 60000;
    int low = 0, high = candles.length - 1;
    while (high - low > 1) {
      final mid = (high + low) ~/ 2;
      if (_timeAt(mid) <= time) {
        low = mid;
      } else {
        high = mid;
      }
    }
    final span = _timeAt(high) - _timeAt(low);
    return low + (time - _timeAt(low)) / (span > 0 ? span : 60000);
  }

  int _timeForIndex(double index) {
    if (candles.length == 1) return (_timeAt(0) + index * 60000).round();
    final low = index.floor().clamp(0, candles.length - 2);
    final span = _timeAt(low + 1) - _timeAt(low);
    return (_timeAt(low) + (index - low) * (span > 0 ? span : 60000)).round();
  }

  Offset toScreen(DrawingAnchor anchor) => Offset(
      ((_indexForTime(anchor.time) + .5) * pointWidth + translateX) * scaleX,
      priceToY(anchor.price));
  double priceToY(double price) =>
      plot.top + (maxPrice - price) / (maxPrice - minPrice) * plot.height;
  DrawingAnchor fromScreen(Offset point) => DrawingAnchor(
      time: _timeForIndex((point.dx / scaleX - translateX) / pointWidth - .5),
      price: maxPrice -
          (point.dy - plot.top) / plot.height * (maxPrice - minPrice));
  DrawingAnchor snap(Offset point, {double threshold = 14}) {
    final free = fromScreen(point);
    final first =
        (((point.dx - threshold) / scaleX - translateX) / pointWidth - .5)
            .ceil()
            .clamp(0, candles.length - 1);
    final last =
        (((point.dx + threshold) / scaleX - translateX) / pointWidth - .5)
            .floor()
            .clamp(0, candles.length - 1);
    DrawingAnchor result = free;
    double nearest = threshold;
    // Search only centers inside the horizontal threshold, then rank OHLC
    // by full screen distance. The closest candle in X need not win in Y.
    for (var index = first; index <= last; index++) {
      final candle = candles[index];
      for (final price in [
        candle.open,
        candle.high,
        candle.low,
        candle.close
      ]) {
        if (!price.isFinite) continue;
        final candidate = DrawingAnchor(time: candle.time ?? 0, price: price);
        final distance = (toScreen(candidate) - point).distance;
        if (distance <= nearest) {
          nearest = distance;
          result = candidate;
        }
      }
    }
    return result;
  }

  int nearestTime(double x) {
    final index = ((x / scaleX - translateX) / pointWidth - .5)
        .round()
        .clamp(0, candles.length - 1);
    return candles[index].time ?? 0;
  }

  List<int> get visibleTimes => [
        for (final c in candles)
          if (c.time != null &&
              toScreen(DrawingAnchor(time: c.time!, price: minPrice)).dx >=
                  plot.left &&
              toScreen(DrawingAnchor(time: c.time!, price: minPrice)).dx <=
                  plot.right)
            c.time!
      ];
  Offset clamp(Offset p) => Offset(
      p.dx.clamp(plot.left, plot.right), p.dy.clamp(plot.top, plot.bottom));
}

double distanceToSegment(Offset p, Offset a, Offset b) {
  final delta = b - a;
  final length = delta.distanceSquared;
  if (length == 0) return (p - a).distance;
  final t = ((p - a).dx * delta.dx + (p - a).dy * delta.dy) / length;
  return (p - (a + delta * t.clamp(0.0, 1.0))).distance;
}

/// Clip all line types using the same parametric representation, including
/// vertical rays and rays pointing left. No slope division is necessary.
(Offset, Offset)? clipDrawingLine(Offset a, Offset b, Rect rect,
    {bool extendStart = false, bool extendEnd = false}) {
  final d = b - a;
  if (d.distanceSquared == 0) return null;
  double t0 = extendStart ? -double.infinity : 0;
  double t1 = extendEnd ? double.infinity : 1;
  for (final axis in [
    (a.dx, d.dx, rect.left, rect.right),
    (a.dy, d.dy, rect.top, rect.bottom)
  ]) {
    if (axis.$2.abs() < 1e-12) {
      if (axis.$1 < axis.$3 || axis.$1 > axis.$4) return null;
    } else {
      final one = (axis.$3 - axis.$1) / axis.$2;
      final two = (axis.$4 - axis.$1) / axis.$2;
      t0 = math.max(t0, math.min(one, two));
      t1 = math.min(t1, math.max(one, two));
      if (t1 < t0) return null;
    }
  }
  return (a + d * t0, a + d * t1);
}
