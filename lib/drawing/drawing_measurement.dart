import '../entity/k_line_entity.dart';
import 'drawing_models.dart';
import 'measure_candle_anchors.dart';

/// Prices use the drawn endpoints; time snaps to the nearest candle (milliseconds).
/// [bars] is the candle index difference, excluding the starting endpoint.
/// Missing candles affect elapsed time, but do not add nonexistent bars.
class DrawingMeasurement {
  const DrawingMeasurement(
      {required this.change,
      required this.changePercent,
      required this.bars,
      required this.duration});
  final double change;
  final double? changePercent;
  final int bars;
  final Duration duration;

  static DrawingMeasurement calculate(
      List<DrawingAnchor> anchors, List<KLineEntity> candles) {
    final a = anchors[0], b = anchors[1];
    final axis = MeasureCandleAnchors(candles);
    final first = axis.nearestIndex(a.time), last = axis.nearestIndex(b.time);
    final elapsed = candles.isEmpty
        ? 0
        : ((candles[last].time ?? 0) - (candles[first].time ?? 0)).abs();
    final change = b.price - a.price;
    return DrawingMeasurement(
        change: change,
        changePercent: a.price == 0 ? null : change / a.price * 100,
        bars: (last - first).abs(),
        duration: Duration(milliseconds: elapsed));
  }
}
