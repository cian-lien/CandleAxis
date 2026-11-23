import 'dart:ui';

/// A full axis line from [start] to [tip], with an open chevron at [tip].
typedef MeasureArrow = ({
  Offset start,
  Offset tip,
  Offset wing1,
  Offset wing2,
});

/// Center arrows in screen coordinates, preserving the anchor order.
/// Positive screen Y points down (decreasing price). Small boxes hide both
/// axes so the chevrons have room to stay inside the measurement fill.
({MeasureArrow horizontal, MeasureArrow vertical})? computeMeasureArrows(
    Offset start, Offset end) {
  const arrowSize = 6.0;
  const minimumExtent = 2 * arrowSize + 4;
  final box = Rect.fromPoints(start, end);
  if (box.width < minimumExtent || box.height < minimumExtent) return null;
  final center = box.center;
  final horizontalTip = Offset(end.dx, center.dy);
  final verticalTip = Offset(center.dx, end.dy);
  final dx = end.dx < start.dx ? arrowSize : -arrowSize;
  final dy = end.dy < start.dy ? arrowSize : -arrowSize;
  return (
    horizontal: (
      start: Offset(start.dx, center.dy),
      tip: horizontalTip,
      wing1: horizontalTip + Offset(dx, -arrowSize / 2),
      wing2: horizontalTip + Offset(dx, arrowSize / 2),
    ),
    vertical: (
      start: Offset(center.dx, start.dy),
      tip: verticalTip,
      wing1: verticalTip + Offset(-arrowSize / 2, dy),
      wing2: verticalTip + Offset(arrowSize / 2, dy),
    ),
  );
}
