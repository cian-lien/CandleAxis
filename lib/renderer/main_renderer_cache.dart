part of 'main_renderer.dart';

/// Owned by one painter/input/configuration revision, like secondary paths.
/// Entries retain a small number of visible windows, not the entire history.
class MainSeriesCache {
  List<KLineEntity>? _source;
  final _entries = <Object, _MainPathEntry>{};
  int get length => _entries.length;

  void _draw(MainRenderer renderer, MainState state, List<KLineEntity> data,
      int start, int stop, double step, Canvas canvas) {
    if (!identical(_source, data)) {
      _source = data;
      _entries.clear();
    }
    final key = (state, start, stop, step, renderer.scaleX);
    var entry = _entries.remove(key);
    if (entry == null) {
      final capture = _MainPathCanvas();
      renderer._drawBatchedIndicator(state, data, start, stop, step, capture);
      entry = _MainPathEntry(capture.commands, renderer.minValue,
          renderer.getY(renderer.minValue), renderer.scaleY);
    }
    _entries[key] = entry;
    // Four overlays consume four entries per visible window. Keep enough
    // windows for a round-trip pan at minimum zoom without rebuilding them.
    if (_entries.length > 256) _entries.remove(_entries.keys.first);
    final ratio = renderer.scaleY / entry.scaleY;
    final offset = renderer.getY(entry.price) - entry.y * ratio;
    final matrix = ratio == 1 && offset == 0
        ? null
        : (Float64List(16)
          ..[0] = 1
          ..[5] = ratio
          ..[10] = 1
          ..[13] = offset
          ..[15] = 1);
    for (final command in entry.commands) {
      // Transform geometry, not the canvas: stroke widths stay unchanged
      // during the animated price-axis transition.
      canvas.drawPath(
          matrix == null ? command.$1 : command.$1.transform(matrix),
          command.$2);
    }
  }
}

class _MainPathEntry {
  _MainPathEntry(this.commands, this.price, this.y, this.scaleY);
  final List<(Path, Paint)> commands;
  final double price, y, scaleY;
}

class _MainPathCanvas implements Canvas {
  final commands = <(Path, Paint)>[];
  @override
  void drawPath(Path path, Paint paint) => commands.add((
        path,
        Paint()
          ..color = paint.color
          ..style = paint.style
          ..strokeWidth = paint.strokeWidth
      ));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Only indicator paths can be cached');
}
