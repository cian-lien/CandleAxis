part of 'candlestick_widget.dart';

/// 边界加载编排：滚动至两端时的防抖触发、错误处理与加载状态复位。
extension _CandlestickBoundary on _CandlestickWidgetState {
  Future<void> _triggerBoundaryCallback(bool isLeft) async {
    if (widget.onReachBoundary == null) return;

    if (_isLoadingAtLeft == isLeft) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastBoundaryTriggerTime != null) {
      final elapsed = now - _lastBoundaryTriggerTime!;
      if (elapsed < widget.debounceDelay) return;
    }

    _isLoadingAtLeft = isLeft;
    _loadingError = null; // 清除之前的错误
    _lastBoundaryTriggerTime = now;
    notifyChanged();

    try {
      await Future.value(widget.onReachBoundary!(isLeft));

      resetLoadingState();
    } catch (error) {
      _loadingError = error;
      notifyChanged();

      if (widget.loadingErrorBuilder == null) {
        resetLoadingState();
      }
    }
  }

  void resetLoadingState() {
    if (_isLoadingAtLeft != null || _loadingError != null) {
      _isLoadingAtLeft = null;
      _loadingError = null;
      notifyChanged();
    }
  }
}
