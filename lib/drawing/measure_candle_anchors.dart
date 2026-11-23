import '../entity/k_line_entity.dart';
import 'drawing_models.dart';

/// Measure endpoints persist candle timestamps; movement uses candle indices,
/// never elapsed milliseconds (which have uneven spacing across data gaps).
class MeasureCandleAnchors {
  const MeasureCandleAnchors(this.candles);
  final List<KLineEntity> candles;

  int nearestIndex(int time) {
    if (candles.isEmpty) return 0;
    var low = 0, high = candles.length - 1;
    while (high - low > 1) {
      final mid = (low + high) ~/ 2;
      if ((candles[mid].time ?? 0) <= time) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return (time - (candles[low].time ?? 0)).abs() <=
            (time - (candles[high].time ?? 0)).abs()
        ? low
        : high;
  }

  List<DrawingAnchor> translate(List<DrawingAnchor> anchors,
      {required int bars, required double priceDelta}) {
    if (candles.isEmpty || anchors.isEmpty) return anchors;
    final indices = [for (final anchor in anchors) nearestIndex(anchor.time)];
    var first = indices.first, last = indices.first;
    for (final index in indices.skip(1)) {
      if (index < first) first = index;
      if (index > last) last = index;
    }
    // Clamp one shared delta so reaching either end cannot resize the box.
    final delta = bars.clamp(-first, candles.length - 1 - last);
    return [
      for (var i = 0; i < anchors.length; i++)
        DrawingAnchor(
            time: candles[indices[i] + delta].time ?? 0,
            price: anchors[i].price + priceDelta)
    ];
  }
}
