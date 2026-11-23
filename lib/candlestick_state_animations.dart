part of 'candlestick_widget.dart';

/// 动画与过渡：viewport 范围过渡、蜡烛过渡、端点脉冲、
/// 惯性滚动与回位动画。
extension _CandlestickAnimations on _CandlestickWidgetState {
  /// Runs the endpoint pulse only while the line chart is visible.
  void _syncEndpointPulse() {
    final shouldRun = widget.isLine || _isAutoLine;
    if (shouldRun) {
      if (!_endpointPulseController.isAnimating) {
        _endpointPulseController.repeat();
      }
    } else if (_endpointPulseController.isAnimating) {
      _endpointPulseController.stop();
    }
  }

  List<KLineEntity>? get _displayDatas {
    final previous = _previousDatas;
    final current = widget.datas;
    final controller = _candleTransitionController;
    if (previous == null ||
        current == null ||
        controller == null ||
        previous.length != current.length ||
        controller.isCompleted) {
      return current;
    }

    if (current.isEmpty) return current;
    final oldCandle = previous.last;
    final newCandle = current.last;
    final t = Curves.easeOut.transform(controller.value);
    // 指标字段（MA/BOLL/SAR、MACD/KDJ/RSI 等）随 OHLC 一起插值，
    // 避免动画期间副图/主图指标线末段消失和刻度跳变。
    final interpolated = KLineEntity.lerp(oldCandle, newCandle, t);
    return _AnimatedCandleList(current, interpolated);
  }

  void _stopAnimation({bool needNotify = true}) {
    if (_controller != null && _controller!.isAnimating) {
      _controller!.stop();
      _onDragChanged(false);
      if (needNotify) {
        _repaintChart();
      }
    }
  }

  /// Bounds are discovered during paint. Start or extend the shared clock
  /// after paint; active clocks keep running when a new target arrives.
  void _handleViewportExtremaChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_priceRangeTransition.awaitingRestart) return;
      final running = _viewportTransitionController.isAnimating;
      _priceRangeTransition.markRestarted(resetClock: !running);
      if (!running) {
        _viewportTransitionController.animateWith(_PriceRangeClock(
          secondsPerTransition: _CandlestickWidgetState
                  ._viewportTransitionDuration.inMicroseconds /
              Duration.microsecondsPerSecond,
          endTime: () => _priceRangeTransition.endTime,
        ));
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _interruptPriceRange() {
    _viewportTransitionController.stop();
    _priceRangeTransition.interrupt();
  }

  void _beginPriceAxisDrag() {
    _interruptPriceRange();
    _isPriceAxisDragging = true;
    _axisDragBaseRange = _priceRangeTransition.current;
    final auto = painterForTest?.autoPriceRange;
    final current = _axisDragBaseRange;
    if (auto != null && current != null) {
      mVerticalScale = (auto.span / current.span).clamp(0.2, 1.0);
    }
    _axisDragBaseScale = mVerticalScale;
  }

  void _endPriceAxisDrag() {
    _isPriceAxisDragging = false;
    _axisDragRange = _axisDragBaseRange = null;
    // Keep the user scale after release; only [_resetPriceScale] restores
    // the default. Clearing the drag range lets auto extrema apply the
    // sticky [mVerticalScale] again.
    _priceRangeTransition.resume();
    notifyChanged();
  }

  void _resetPriceScale() {
    _isPriceAxisDragging = false;
    _axisDragRange = _axisDragBaseRange = null;
    mVerticalScale = _CandlestickWidgetState._defaultVerticalScale;
    _priceRangeTransition.resume();
    notifyChanged();
  }

  void _onDragChanged(bool isOnDrag) {
    isDrag = isOnDrag;
    if (widget.isOnDrag != null) {
      widget.isOnDrag!(isDrag);
    }
  }

  void _onFling(double x) {
    _controller?.dispose();
    _controller = AnimationController(
        duration: Duration(milliseconds: widget.flingTime), vsync: this);

    aniX = null;
    aniX = Tween<double>(
      begin: mScrollX,
      end: (x * widget.flingRatio * widget.panSensitivity) + mScrollX,
    ).animate(
        CurvedAnimation(parent: _controller!.view, curve: widget.flingCurve));

    aniX!.addListener(() {
      mScrollX = aniX!.value;
      _priceRangeTransition.resume();

      if (mScrollX <= 0) {
        mScrollX = 0;
        _triggerBoundaryCallback(false); // false = 加载最新数据

        if (widget.onLoadMore != null) {
          widget.onLoadMore!(false);
        }
        _stopAnimation();
      } else if (mScrollX >= ChartPainter.maxScrollX) {
        mScrollX = ChartPainter.maxScrollX;
        _triggerBoundaryCallback(true); // true = 加载历史数据

        if (widget.onLoadMore != null) {
          widget.onLoadMore!(true);
        }
        _stopAnimation();
      }

      _repaintChart(); // 每帧只重绘图表
    });

    aniX!.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _onDragChanged(false);
        _repaintChart();
      }
    });

    _controller!.forward();
  }

  void _animateToLatestPrice() {
    if (ChartPainter.maxScrollX <= 0 || mScrollX <= 0.01) return;
    _latestPriceController?.dispose();
    final controller = _latestPriceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    late final Animation<double> animation;
    animation = Tween<double>(begin: mScrollX, end: 0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
    )..addListener(() {
        mScrollX = animation.value;
        _repaintChart();
      });
    controller.forward().whenComplete(() {
      if (identical(_latestPriceController, controller)) {
        _latestPriceController = null;
        controller.dispose();
      }
    });
  }

  /// 最后一根 K 线更新时的 180ms OHLC/指标插值过渡。
  void _startCandleTransition(List<KLineEntity> oldData) {
    // Interpolation reads only the previous length and last candle; unchanged
    // history needs no deep copy on every realtime update.
    _previousDatas = List<KLineEntity>.unmodifiable(
      [...oldData.take(oldData.length - 1), oldData.last.snapshot()],
    );
    _candleTransitionController?.dispose();
    final controller = _candleTransitionController = AnimationController(
      vsync: this,
      duration: _CandlestickWidgetState._candleTransitionDuration,
    );
    controller.addListener(() {
      if (mounted) _repaintChart();
    });
    controller.forward().whenComplete(() {
      if (mounted && identical(_candleTransitionController, controller)) {
        _previousDatas = null;
        _repaintChart();
      }
    });
  }
}

/// Only the final candle morphs. Keep history as a read-only view instead of
/// copying the whole list on every animation frame.
class _AnimatedCandleList extends ListBase<KLineEntity> {
  _AnimatedCandleList(this.source, this.lastCandle);
  final List<KLineEntity> source;
  final KLineEntity lastCandle;
  @override
  int get length => source.length;
  @override
  KLineEntity operator [](int index) =>
      index == length - 1 ? lastCandle : source[index];
  @override
  set length(int value) => throw UnsupportedError('Read-only candle view');
  @override
  void operator []=(int index, KLineEntity value) =>
      throw UnsupportedError('Read-only candle view');
}

/// A linear clock that can extend to accommodate new targets without restarting
/// its ticker. PriceRangeTransition applies the ease-out to each fixed segment.
class _PriceRangeClock extends Simulation {
  _PriceRangeClock({required this.secondsPerTransition, required this.endTime});
  final double secondsPerTransition;
  final double Function() endTime;

  @override
  double x(double time) => time / secondsPerTransition;
  @override
  double dx(double time) => 1 / secondsPerTransition;
  @override
  bool isDone(double time) => x(time) >= endTime();
}
