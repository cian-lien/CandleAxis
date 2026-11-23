import 'dart:collection';

import 'package:flutter/painting.dart';

/// Bounded, chart-owned paragraph cache. Text and style are part of the key,
/// so mutable themes, formatters and interpolated values cannot reuse stale text.
class ChartTextCache {
  ChartTextCache({this.capacity = 512}) : assert(capacity > 0) {
    PaintingBinding.instance.systemFonts.addListener(clear);
  }

  final int capacity;
  final _entries = <(InlineSpan, double, int?, String?), _ParagraphEntry>{};
  final _lru = LinkedList<_ParagraphEntry>();

  TextPainter layout(InlineSpan text,
      {double maxWidth = double.infinity, int? maxLines, String? ellipsis}) {
    final key = (text, maxWidth, maxLines, ellipsis);
    final cached = _entries[key];
    if (cached != null) {
      cached.unlink();
      _lru.add(cached);
      return cached.painter;
    }
    final painter = TextPainter(
        text: text,
        textDirection: TextDirection.ltr,
        maxLines: maxLines,
        ellipsis: ellipsis)
      ..layout(maxWidth: maxWidth);
    final entry = _ParagraphEntry(key, painter);
    _entries[key] = entry;
    _lru.add(entry);
    if (_entries.length > capacity) {
      final oldest = _lru.first..unlink();
      _entries.remove(oldest.key);
      oldest.painter.dispose();
    }
    return painter;
  }

  void clear() {
    for (final entry in _lru) {
      entry.painter.dispose();
    }
    _lru.clear();
    _entries.clear();
  }

  void dispose() {
    PaintingBinding.instance.systemFonts.removeListener(clear);
    clear();
  }
}

final class _ParagraphEntry extends LinkedListEntry<_ParagraphEntry> {
  _ParagraphEntry(this.key, this.painter);
  final (InlineSpan, double, int?, String?) key;
  final TextPainter painter;
}
