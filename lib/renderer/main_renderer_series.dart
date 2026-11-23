part of 'main_renderer.dart';

extension MainRendererSeries on MainRenderer {
  /// Batch each indicator layer. Contours remain separate across
  /// missing values and trend reversals; no market candles are synthesized.
  void drawSeries(List<KLineEntity> data, int start, int stop,
      double pointWidth, Size size, Canvas canvas,
      {MainSeriesCache? cache, List<KLineEntity>? historySource}) {
    if (start > stop) return;
    if (isLine) {
      for (var i = start; i <= stop; i++) {
        final x = i * pointWidth + pointWidth / 2;
        drawChart(data[i == 0 ? 0 : i - 1], data[i],
            i == 0 ? x : x - pointWidth, x, size, canvas);
      }
      return;
    }
    for (var i = start; i <= stop; i++) {
      drawCandle(data[i], canvas, i * pointWidth + pointWidth / 2);
    }
    for (final state in stateLi) {
      if (state == MainState.VWAP && stateLi.contains(MainState.AVL)) continue;
      if (cache != null &&
          identical(data, historySource) &&
          identical(data, chartData) &&
          state != MainState.SAR) {
        cache._draw(this, state, data, start, stop, pointWidth, canvas);
      } else {
        // Animated tail values and SAR's fixed screen-space radii must not
        // be replayed through a price-space transform.
        _drawBatchedIndicator(state, data, start, stop, pointWidth, canvas);
      }
    }
  }
}
