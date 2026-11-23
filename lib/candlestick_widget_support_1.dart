part of 'candlestick_widget.dart';

class _CandlestickWidgetState extends State<CandlestickWidget>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Duration _candleTransitionDuration = Duration(milliseconds: 180);
  static const Duration _viewportTransitionDuration =
      Duration(milliseconds: 300);
  static const Curve _viewportTransitionCurve = Curves.easeOutCubic;

  static const double _defaultVerticalScale = 1.0;

  final ValueNotifier<int> _chartPaintTick = ValueNotifier<int>(0);
  final ChartTextCache _textCache = ChartTextCache();
  final ChartWatermarkCache _watermarkCache = ChartWatermarkCache();
  (bool, bool)? _drawingBuildState;
  (bool, bool) get _drawingStructure => (
        widget.drawingController?.blocksBrowsing ?? false,
        !widget.drawingInteractive &&
            (widget.drawingController?.visibleObjects
                    .any((object) => object.tool == DrawingTool.measure) ??
                false),
      );

  /// Default horizontal zoom; pinch range still allows zooming further
  /// out (down to 0.3) or in (up to 2.25).
  static const double _defaultScaleX = 0.68;
  static const double _priceAxisHitWidth = 56.0;
  final StreamController<InfoWindowEntity?> mInfoWindowStream =
      StreamController<InfoWindowEntity?>();
  InfoWindowEntity? _lockedInfoWindow;

  @visibleForTesting
  InfoWindowEntity? get infoWindowForTest => _lockedInfoWindow;

  // Default horizontal zoom; pinch range still allows zooming further
  // out (down to 0.3) or in (up to 2.25).
  double mScaleX = _defaultScaleX;
  double mVerticalScale = _defaultVerticalScale;

  double mScrollX = 0.0;

  double mSelectX = 0.0;

  double mHeight = 0, mWidth = 0;

  AnimationController? _controller;
  AnimationController? _candleTransitionController;
  late final AnimationController _viewportTransitionController;

  /// Repeating pulse for the line-mode endpoint dot. Only runs while the
  /// line chart is visible so candle mode pays no continuous repaint cost.
  late final AnimationController _endpointPulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  late final PriceRangeTransition _priceRangeTransition = PriceRangeTransition(
    onRetarget: _handleViewportExtremaChanged,
    curve: _viewportTransitionCurve,
  );
  PriceRange? _axisDragBaseRange, _axisDragRange;
  double _axisDragBaseScale = 1;
  bool _isPriceAxisDragging = false;

  List<KLineEntity>? _previousDatas;

  Animation<double>? aniX;
  AnimationController? _latestPriceController;

  bool _isAutoLine = false;

  List<TrendLine> lines = [];

  double? changeinXposition;

  double? changeinYposition;

  double mSelectY = 0.0;

  /// 十字线横线的自由 Y 坐标（局部坐标）。null 表示横线钉在所选 K 线收盘价；
  /// 非 null 表示跟随手指（tap 锁定/拖动/长按都会设置）。与趋势线的 mSelectY
  /// 分开维护，避免两套坐标语义互相污染。
  double? _crossY;

  /// Raw crosshair horizontal-line Y for tests.
  @visibleForTesting
  double? get crossY => _crossY;

  /// 最近一次 build 创建的 painter，供测试断言绘制几何信息。
  @visibleForTesting
  ChartPainter? painterForTest;

  int? _lockedCandleTime;

  @visibleForTesting
  int? get lockedCandleTimeForTest => _lockedCandleTime;

  @visibleForTesting
  int? get selectedCandleTimeForTest {
    final painter = painterForTest;
    if (painter == null || widget.datas == null || widget.datas!.isEmpty) {
      return null;
    }
    return painter.getItem(painter.calculateSelectedX(mSelectX)).time;
  }

  /// 十字线轻震动去重：仅在吸附蜡烛索引变化的那次移动事件触发一次
  /// lightImpact；同蜡烛内微移与初始落点/点按锁定不震动。
  int? _lastCrossHapticIndex;

  bool waitingForOtherPairofCords = false;

  bool enableCordRecord = false;

  double getMinScrollX() {
    return mScaleX;
  }

  int _pointerCount = 0;

  int _lastPointerCount = 0;

  double _scaleBase = 1.0;

  double _scaleXBase = 1.0;

  int _anchorIndex = 0;

  double _anchorScreenX = 0.0;

  bool isScale = false, isDrag = false, isLongPress = false, isOnTap = false;

  bool _isCrossLocked = false;

  // A tap-locked crosshair should track a single finger instead of panning
  // the viewport. This is reset when the gesture ends or becomes a pinch.
  bool _isCrosshairDragging = false;

  double _boundaryOverscroll = 0.0;

  bool? _isLoadingAtLeft;

  Object? _loadingError;

  int? _lastBoundaryTriggerTime;

  /// 当前手势状态
  ChartGestureState _currentGestureState = ChartGestureState.idle;

  bool _wasBackgrounded = false;

  /// 初始触摸位置，用于判断滑动方向
  Offset? _initialPointerPosition;

  /// 是否已经确定了滑动方向
  bool _dragDirectionDetermined = false;

  @override
  void initState() {
    super.initState();
    widget.drawingController?.addListener(_drawingChanged);
    widget.drawingController
        ?.updateDisplayBasis((widget.valueType, widget.mcapFactor));
    WidgetsBinding.instance.addObserver(this);
    _adoptViewport(widget.viewport);
    _viewportTransitionController = AnimationController.unbounded(vsync: this);
    _viewportTransitionController.addListener(() {
      if (mounted) _repaintChart();
    });
    _syncEndpointPulse();
  }

  @override
  void dispose() {
    widget.drawingController?.removeListener(_drawingChanged);
    widget.drawingController?.cancelInteraction();
    WidgetsBinding.instance.removeObserver(this);
    mInfoWindowStream.sink.close();
    mInfoWindowStream.close();
    _controller?.dispose();
    _latestPriceController?.dispose();
    _candleTransitionController?.dispose();
    _viewportTransitionController.dispose();
    _endpointPulseController.dispose();
    _chartPaintTick.dispose();
    _textCache.dispose();
    _watermarkCache.dispose();
    super.dispose();
  }

  void _clearLockedCandleTime() {
    if (_lockedCandleTime == null) return;
    _lockedCandleTime = null;
    widget.onLockedCandleTimeChanged?.call(null);
  }

  void _unlockCrosshair() {
    _isCrossLocked = false;
    _isCrosshairDragging = false;
    _crossY = null;
    isOnTap = false;
    isLongPress = false;
    _clearLockedCandleTime();
    mInfoWindowStream.sink.add(null);
  }

  void _syncLockedCandleTime(ChartPainter painter) {
    if (widget.datas == null || widget.datas!.isEmpty) {
      _clearLockedCandleTime();
      return;
    }
    final nextTime = painter.getItem(painter.calculateSelectedX(mSelectX)).time;
    if (_lockedCandleTime == nextTime) return;
    _lockedCandleTime = nextTime;
    widget.onLockedCandleTimeChanged?.call(nextTime);
  }

  void _restoreLockedCandleAnchor(List<KLineEntity> datas) {
    final lockedTime = _lockedCandleTime;
    if (lockedTime == null) return;
    final index = datas.indexWhere((item) => item.time == lockedTime);
    if (index < 0) {
      _unlockCrosshair();
      return;
    }
    mSelectX = _screenXForIndex(index, datas.length);
  }

  double _screenXForIndex(int index, int dataLength) {
    final pointWidth = widget.chartStyle.pointWidth;
    final dataLen = dataLength * pointWidth;
    final minTranslateX = -dataLen +
        mWidth / mScaleX -
        pointWidth / 2 -
        widget.xFrontPadding / mScaleX;
    final effectiveMinTranslateX = minTranslateX >= 0 ? 0.0 : minTranslateX;
    final translateX = mScrollX + effectiveMinTranslateX;
    return (index * pointWidth + pointWidth / 2 + translateX) * mScaleX;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      // 仅失焦（转屏、下拉通知栏、系统弹窗）不算进入后台：中断手势，
      // 但回来时保留用户的滚动位置。
      widget.drawingController?.cancelInteraction();
      return;
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      widget.drawingController?.cancelInteraction();
      _wasBackgrounded = true;
      return;
    }

    if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      // maxScrollX is calculated by the painter during paint, so defer the
      // reset until the next frame to use the current viewport bounds.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _stopAnimation(needNotify: false);
        _latestPriceController?.dispose();
        _latestPriceController = null;
        _isCrossLocked = false;
        _isCrosshairDragging = false;
        _crossY = null;
        isOnTap = false;
        isLongPress = false;
        mSelectX = 0.0;
        _clearLockedCandleTime();
        // The latest candle is rendered at the right edge of the viewport.
        mScrollX = 0.0;
        _priceRangeTransition.resume();
        notifyChanged();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _drawingBuildState = _drawingStructure;
    final gestureSettings = MediaQuery.maybeGestureSettingsOf(context);

    if (widget.datas != null && widget.datas!.isEmpty) {
      mScrollX = mSelectX = 0.0;
      mScaleX = _defaultScaleX;
      mVerticalScale = _defaultVerticalScale;
    }

    final BaseDimension baseDimension = BaseDimension(
      mBaseHeight: widget.mBaseHeight,
      volHidden: widget.volHidden,
      secondaryStateLi: widget.secondaryStateLi,
      mainStateLi: widget.mainStateLi,
    );

    final painter = _buildChartPainter(baseDimension);
    painterForTest = painter;
    _scheduleViewportReport();

    return LayoutBuilder(
      builder: (context, constraints) {
        mHeight = constraints.maxHeight;
        mWidth = constraints.maxWidth;

        return _buildChartGestures(
          painter: painter,
          gestureSettings: gestureSettings,
          child: _buildChartStack(baseDimension, painter),
        );
      },
    );
  }

  @override
  void didUpdateWidget(covariant CandlestickWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.drawingController != widget.drawingController) {
      oldWidget.drawingController?.removeListener(_drawingChanged);
      widget.drawingController?.addListener(_drawingChanged);
    }
    widget.drawingController
        ?.updateDisplayBasis((widget.valueType, widget.mcapFactor));
    _syncEndpointPulse();
    if (!identical(oldWidget.viewport, widget.viewport)) {
      _adoptViewport(widget.viewport);
    }
    final oldData = oldWidget.datas;
    final newData = widget.datas;
    if (oldData == null ||
        oldData.isEmpty ||
        newData == null ||
        newData.isEmpty) {
      _priceRangeTransition.clear();
      _viewportTransitionController.stop();
      _axisDragRange = _axisDragBaseRange = null;
      _isPriceAxisDragging = false;
      mVerticalScale = _defaultVerticalScale;
    }
    if (!identical(oldData, newData)) {
      _previousDatas = null;
      _candleTransitionController?.stop();
    }
    if (oldData == null ||
        newData == null ||
        oldData.isEmpty ||
        newData.isEmpty ||
        oldData.length != newData.length) {
      if (newData != null && newData.isNotEmpty) {
        _restoreLockedCandleAnchor(newData);
      }
      _previousDatas = null;
      return;
    }
    _restoreLockedCandleAnchor(newData);
    final oldLast = oldData.last;
    final newLast = newData.last;
    if (oldLast.time != newLast.time || oldLast == newLast) return;

    _startCandleTransition(oldData);
  }

  void _drawingChanged() {
    if (!mounted) return;
    final structure = _drawingStructure;
    if (structure == _drawingBuildState) return;
    _drawingBuildState = structure;
    if (structure.$1) _unlockCrosshair();
    // The painter and DrawingOverlay listen directly to previews. Rebuilding
    // here would discard chart geometry caches on every anchor movement.
    setState(() {});
  }

  void notifyChanged() => setState(() {});

  /// Visual progress of the Y-axis range transition (curve already applied,
  /// matching what the painter consumes). Exposed so tests can verify the
  /// 300ms ease-out timing.
  @visibleForTesting
  double get viewportAnimationProgress =>
      _priceRangeTransition.progressAt(_viewportTransitionController.value);

  /// Whether the line-mode endpoint dot's pulse is currently running.
  @visibleForTesting
  bool get endpointPulseAnimating => _endpointPulseController.isAnimating;

  ViewportSnapshot? _reportedViewport;
  bool _viewportReportPending = false;

  /// 采用宿主交来的水平视口（自己上报出去的那份不再回灌）。
  void _adoptViewport(ViewportSnapshot? viewport) {
    if (viewport == null || identical(viewport, _reportedViewport)) return;
    _stopAnimation(needNotify: false);
    mScaleX = viewport.scaleX;
    mScrollX = viewport.scrollX;
    _reportedViewport = viewport;
    // 宽度可能与交出视口的图表不同（如横竖屏切换），布局后按本实例的
    // 滚动上限收口。
    WidgetsBinding.instance.addPostFrameCallback((_) => _clampSeededScroll());
  }

  void _clampSeededScroll() {
    final datas = widget.datas;
    if (!mounted || datas == null || datas.isEmpty || mWidth <= 0) return;
    final pointWidth = widget.chartStyle.pointWidth;
    final minTranslateX = -datas.length * pointWidth +
        mWidth / mScaleX -
        pointWidth / 2 -
        widget.xFrontPadding / mScaleX;
    final max = (minTranslateX >= 0 ? 0.0 : minTranslateX).abs() +
        widget.xBackPadding / mScaleX -
        pointWidth / 2;
    if (mScrollX > max) setState(() => mScrollX = math.max(0.0, max));
  }

  /// 每帧结束后上报变化过的水平视口，宿主据此在图表实例间交接。
  void _scheduleViewportReport() {
    if (widget.onViewportChanged == null || _viewportReportPending) return;
    _viewportReportPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewportReportPending = false;
      final callback = widget.onViewportChanged;
      if (!mounted || callback == null) return;
      final last = _reportedViewport;
      if (last != null && last.scrollX == mScrollX && last.scaleX == mScaleX) {
        return;
      }
      callback(_reportedViewport = createViewportSnapshot());
    });
  }

  ViewportSnapshot createViewportSnapshot() {
    return ViewportSnapshot(
      dataLength: widget.datas?.length ?? 0,
      scrollX: mScrollX,
      scaleX: mScaleX,
    );
  }

  ///

  void restoreViewport(ViewportSnapshot snapshot, int newDataCount) {
    if (widget.datas == null || widget.datas!.isEmpty) return;

    final newScrollX = snapshot.scrollX + newDataCount;

    setState(() {
      mScaleX = snapshot.scaleX;

      mScrollX = newScrollX.clamp(0.0, ChartPainter.maxScrollX).toDouble();
    });
  }
}
