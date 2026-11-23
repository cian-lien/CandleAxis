import 'dart:ui';

/// Centers a measurement label below its box, falling back to above.
/// Returns null if neither side can contain the whole label within [plot];
/// clamping vertically into the box would obscure its axis lines and arrows.
Rect? computeMeasureLabelRect({
  required Rect box,
  required Rect plot,
  required Size labelSize,
  double gap = 8,
}) {
  if (plot.isEmpty ||
      labelSize.isEmpty ||
      labelSize.width > plot.width ||
      labelSize.height > plot.height) {
    return null;
  }
  final left = (box.center.dx - labelSize.width / 2)
      .clamp(plot.left, plot.right - labelSize.width);
  final below = box.bottom + gap;
  if (below >= plot.top && below + labelSize.height <= plot.bottom) {
    return Rect.fromLTWH(left, below, labelSize.width, labelSize.height);
  }
  final above = box.top - gap - labelSize.height;
  if (above >= plot.top && above + labelSize.height <= plot.bottom) {
    return Rect.fromLTWH(left, above, labelSize.width, labelSize.height);
  }
  return null;
}
