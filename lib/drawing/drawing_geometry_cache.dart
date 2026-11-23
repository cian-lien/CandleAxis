import '../renderer/chart_text_cache.dart';
import 'drawing_coordinates.dart';
import 'drawing_geometry.dart';
import 'drawing_models.dart';

/// Reuses immutable drawings within one viewport snapshot. No paragraph is
/// retained here: text layouts remain owned by the chart's paragraph cache.
class DrawingGeometryCache {
  DrawingGeometryCache({this.capacity = 128}) : assert(capacity > 0);
  final int capacity;
  final _entries = <String, DrawingGeometry>{};
  DrawingCoordinates? _coordinates;
  ChartTextCache? _textCache;

  DrawingGeometry resolve(DrawingObject object, DrawingCoordinates coordinates,
      {ChartTextCache? textCache}) {
    if (!identical(_coordinates, coordinates) ||
        !identical(_textCache, textCache)) {
      _entries.clear();
      _coordinates = coordinates;
      _textCache = textCache;
    }
    // One slot per drawing: successive edit previews cannot accumulate paths.
    final cached = _entries.remove(object.id);
    if (cached != null && identical(cached.object, object)) {
      _entries[object.id] = cached;
      return cached;
    }
    final geometry = DrawingGeometry(object, coordinates, textCache: textCache);
    if (_entries.length >= capacity) _entries.remove(_entries.keys.first);
    _entries[object.id] = geometry;
    return geometry;
  }
}
