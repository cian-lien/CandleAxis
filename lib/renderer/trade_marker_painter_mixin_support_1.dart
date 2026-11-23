part of 'trade_marker_painter_mixin.dart';

abstract class _PlotLabelSpec {
  _PlotLabelSpec({required this.y});
  double y;
  double get boxHeight;
  double get labelTop => y - boxHeight / 2;
  set labelTop(double top) => y = top + boxHeight / 2;
}

class _AvgPriceLineSpec extends _PlotLabelSpec {
  _AvgPriceLineSpec({
    required super.y,
    required this.paint,
    required this.labelParts,
  });

  final Paint paint;
  final _AvgLabelParts? labelParts;

  bool get hasLabel => labelParts != null;

  double get boxWidth => labelParts?.width ?? 0;

  @override
  double get boxHeight => labelParts?.height ?? 0;
}

class _AvgLabelParts {
  const _AvgLabelParts(
      {required this.titlePainter, required this.valuePainter});

  final TextPainter titlePainter;
  final TextPainter? valuePainter;

  double get titleWidth =>
      titlePainter.width + TradeMarkerPainterMixin._avgLabelPaddingH * 2;

  double get valueWidth => valuePainter == null
      ? 0
      : valuePainter!.width + TradeMarkerPainterMixin._avgLabelPaddingH * 2;

  double get width => titleWidth + (valuePainter == null ? 0 : valueWidth);

  double get height =>
      math.max(titlePainter.height, valuePainter?.height ?? 0) +
      TradeMarkerPainterMixin._avgLabelPaddingV * 2;
}
