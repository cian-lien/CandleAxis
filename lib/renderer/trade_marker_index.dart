import '../entity/k_line_entity.dart';
import '../entity/trade_marker_entity.dart';

/// Timestamp membership does not change when the viewport or candle prices
/// animate. Keep groups until timestamps or immutable marker objects change.
class TradeMarkerIndex {
  List<int?> _times = const [];
  List<TradeMarkerEntity> _markers = const [];
  final Map<int, List<TradeMarkerEntity>> groups = {};

  void update(List<KLineEntity> data, List<TradeMarkerEntity> markers) {
    if (_matches(data, markers)) return;
    _times = [for (final candle in data) candle.time];
    _markers = List.of(markers);
    groups.clear();
    final indices = [
      for (var i = 0; i < _times.length; i++)
        if (_times[i] != null) i,
    ];
    var sorted = true;
    for (var i = 1; i < indices.length; i++) {
      if (_times[indices[i]]! < _times[indices[i - 1]]!) sorted = false;
    }
    for (final marker in markers) {
      int? index;
      if (sorted) {
        var lo = 0, hi = indices.length;
        while (lo < hi) {
          final middle = (lo + hi) >> 1;
          if (_times[indices[middle]]! <= marker.time) {
            lo = middle + 1;
          } else {
            hi = middle;
          }
        }
        if (lo > 0) index = indices[lo - 1];
      } else {
        // Preserve the legacy first-future-timestamp boundary for unsorted
        // host input; do not silently rearrange candles.
        for (final i in indices) {
          if (_times[i]! > marker.time) break;
          index = i;
        }
      }
      if (index != null) groups.putIfAbsent(index, () => []).add(marker);
    }
  }

  bool _matches(List<KLineEntity> data, List<TradeMarkerEntity> markers) {
    if (data.length != _times.length || markers.length != _markers.length) {
      return false;
    }
    for (var i = 0; i < data.length; i++) {
      if (data[i].time != _times[i]) return false;
    }
    for (var i = 0; i < markers.length; i++) {
      if (!identical(markers[i], _markers[i])) return false;
    }
    return true;
  }
}
