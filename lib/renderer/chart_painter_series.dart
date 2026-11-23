part of 'chart_painter.dart';

extension _ChartSeries on ChartPainter {
  /// A new extreme can lie outside the old animated range. Clip main-chart
  /// series together so candles and indicators cannot spill into subcharts.
  void _drawChartSeries(
    Canvas canvas,
    Size size,
    List<BaseChartRenderer> renderers, {
    Rect? clip,
    bool cullToClip = false,
  }) {
    if (renderers.isEmpty || datas == null) return;
    canvas.save();
    if (clip != null) canvas.clipRect(clip);
    canvas.translate(mTranslateX * scaleX, 0);
    canvas.scale(scaleX, 1);
    var start = mStartIndex, stop = mStopIndex;
    if (cullToClip) {
      final visible = canvas.getLocalClipBounds();
      // Include neighbouring segments and Ichimoku's displaced cloud.
      final padding = mainStateLi.contains(MainState.ICHI) ? 28 : 2;
      start = math.max(start, (visible.left / mPointWidth).floor() - padding);
      stop = math.min(stop, (visible.right / mPointWidth).ceil() + padding);
    }
    for (final renderer in renderers) {
      if (renderer is MainRenderer) {
        renderer.drawSeries(datas!, start, stop, mPointWidth, size, canvas,
            cache: _mainSeriesCache, historySource: rangeDatas);
        continue;
      }
      if (renderer is SecondaryRenderer) {
        renderer.drawSeries(
            datas!, mStartIndex, mStopIndex, mPointWidth, canvas,
            historySource: rangeDatas,
            cache: _secondarySeriesCaches.putIfAbsent(
                renderer.state, SecondarySeriesCache.new));
        continue;
      }
      for (var i = mStartIndex; i <= mStopIndex; i++) {
        final current = datas![i];
        final previous = i == 0 ? current : datas![i - 1];
        final x = getX(i);
        final lastX = i == 0 ? x : getX(i - 1);
        renderer.drawChart(previous, current, lastX, x, size, canvas);
      }
    }
    canvas.restore();
  }
}
