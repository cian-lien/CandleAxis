part of '../renderer/chart_painter.dart';

extension _ChartDrawingLayer on ChartPainter {
  Object _drawingKey(Size size) =>
      (size, datas, scaleX, scrollX, viewportAnimation);

  void paintDrawingMagnifierImpl(Canvas canvas, Size size) {
    if (datas == null || datas!.isEmpty) return;
    canvas.save();
    canvas.clipRect(mMainRect);
    // Clipping hides subcharts but does not avoid building their geometry.
    drawGridImpl(canvas, mainOnly: true);
    drawChart(canvas, size, mainOnly: true);
    canvas.restore();
  }

  void _updateDrawingCoordinates() {
    final controller = drawingController;
    if (controller == null ||
        datas == null ||
        datas!.isEmpty ||
        mMainRect.isEmpty) {
      return;
    }
    final top = getMainY(mMainRenderer.maxValue);
    final scale = mMainRenderer.scaleY;
    final map = DrawingCoordinates(
        candles: drawingDatas ?? datas!,
        plot: mMainRect,
        pointWidth: mPointWidth,
        scaleX: scaleX,
        translateX: mTranslateX,
        minPrice: mMainRenderer.maxValue - (mMainRect.bottom - top) / scale,
        maxPrice: mMainRenderer.maxValue + (top - mMainRect.top) / scale,
        factor: valueType == ChartValueType.marketCap ? mcapFactor : 1);
    controller.lastCoordinates = map;
  }

  void _drawDrawingObjects(Canvas canvas) {
    final controller = drawingController;
    final map = controller?.lastCoordinates;
    if (controller == null || map == null || datas?.isNotEmpty != true) return;
    DrawingCanvas.draw(canvas, controller, map,
        textCache: textCache,
        geometryCache: _drawingGeometryCache,
        priceFormatter: formatPrice,
        dateFormatter: getDate,
        anchorSurface: chartColors.bgColor);
  }
}

/// Pointer previews repaint this boundary without traversing candle/subchart
/// geometry. Viewport/data animation ticks still refresh both layers.
class ChartDrawingPainter extends CustomPainter {
  ChartDrawingPainter(this.chart, {Listenable? viewportChanges})
      : super(
            repaint:
                Listenable.merge([viewportChanges, chart.drawingController]));
  final ChartPainter chart;

  @override
  void paint(Canvas canvas, Size size) {
    if (chart.datas?.isNotEmpty != true) return;
    // Flutter may repaint a child boundary before its parent. Synchronize
    // geometry on viewport/data changes, but reuse it for pointer previews.
    if (chart._drawingGeometryKey != chart._drawingKey(size)) {
      chart.prepareChart(size);
    }
    chart._drawDrawingObjects(canvas);
    // Readouts retain their topmost position without repainting series.
    chart.drawTextImpl(canvas, chart.datas!.last, 5);
  }

  @override
  bool shouldRepaint(ChartDrawingPainter oldDelegate) =>
      oldDelegate.chart != chart;
}
