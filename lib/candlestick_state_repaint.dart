part of 'candlestick_widget.dart';

extension _CandlestickRepaint on _CandlestickWidgetState {
  /// Pan and the shared Y clock can tick in the same frame. Both invalidate
  /// only CustomPaint, so Flutter coalesces them into one chart paint while
  /// preserving the 300ms easing during the gesture.
  void _repaintChart() {
    final painter = painterForTest;
    if (painter == null) return;
    painter
      ..datas = _displayDatas
      ..scrollX = mScrollX
      ..scaleX = mScaleX
      ..viewportAnimation = _viewportTransitionController.value
      ..nowPricePositionProgress = (mScrollX * mScaleX / 60).clamp(0.0, 1.0);
    _chartPaintTick.value++;
    _scheduleViewportReport();
  }
}
