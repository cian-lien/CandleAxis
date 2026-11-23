part of 'candlestick_widget.dart';

/// Claims horizontal chart pans before an ancestor PageView while allowing
/// vertical drags to remain available to ancestor scroll views. When the
/// crosshair is tap-locked, vertical drags move the horizontal cross line
/// instead of being handed to ancestor scroll views.
class _ChartScaleGestureRecognizer extends ScaleGestureRecognizer {
  /// Evaluated while a single pointer moves; when it returns true a vertical
  /// drag beyond the touch slop is claimed by the chart.
  bool Function()? shouldAcceptVerticalDrag;

  final Map<int, Offset> _pointerStartPositions = <int, Offset>{};

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerDownEvent) {
      _pointerStartPositions[event.pointer] = event.localPosition;
    } else if (event is PointerMoveEvent &&
        _pointerStartPositions.length == 1) {
      final startPosition = _pointerStartPositions[event.pointer];
      if (startPosition != null) {
        final delta = event.localPosition - startPosition;
        final touchSlop = gestureSettings?.touchSlop ?? kTouchSlop;
        if (delta.dx.abs() > touchSlop && delta.dx.abs() > delta.dy.abs()) {
          resolve(GestureDisposition.accepted);
        } else if (delta.dy.abs() > touchSlop &&
            (shouldAcceptVerticalDrag?.call() ?? false)) {
          resolve(GestureDisposition.accepted);
        }
      }
    }

    super.handleEvent(event);

    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _pointerStartPositions.remove(event.pointer);
    }
  }

  @override
  void rejectGesture(int pointer) {
    _pointerStartPositions.remove(pointer);
    super.rejectGesture(pointer);
  }
}

/// 手势交互：指针记账、手势仲裁（缩放/点按/长按）与惯性滚动。
extension _CandlestickGestures on _CandlestickWidgetState {
  /// 更新手势状态并通知回调
  void _updateGestureState(ChartGestureState newState) {
    if (_currentGestureState != newState) {
      _currentGestureState = newState;
      widget.onGestureStateChanged?.call(newState);
    }
  }

  /// 十字线扫过蜡烛时的轻震动：吸附索引变化即触发一次。
  void _crossHapticOnIndexChange(ChartPainter painter, double selectX) {
    final index = painter.calculateSelectedX(selectX);
    if (_lastCrossHapticIndex != index) {
      _lastCrossHapticIndex = index;
      HapticFeedback.lightImpact();
    }
  }

  ChartDrawingController? get _interactiveDrawingController =>
      widget.drawingInteractive ? widget.drawingController : null;

  Widget _buildChartGestures({
    required ChartPainter painter,
    required DeviceGestureSettings? gestureSettings,
    required Widget child,
  }) {
    return Listener(
      onPointerDown: (event) {
        // Pointer bookkeeping only affects gesture arbitration. Avoid
        // rebuilding the chart for every pointer-down event.
        _pointerCount++;
        _interruptPriceRange();
        final map = _interactiveDrawingController?.lastCoordinates;
        if (map != null) {
          _interactiveDrawingController?.pointerDown(
              event.pointer, event.localPosition, map);
        }
        // 记录初始触摸位置
        if (_pointerCount == 1) {
          _initialPointerPosition = event.localPosition;
          _dragDirectionDetermined = false;
          _updateGestureState(ChartGestureState.pending);
        }
        // 双指时立即通知缩放状态
        if (_pointerCount >= 2) {
          _updateGestureState(ChartGestureState.scaling);
        }
      },
      onPointerMove: (event) => _interactiveDrawingController?.pointerMove(
          event.pointer, event.localPosition),
      onPointerUp: (event) {
        _interactiveDrawingController?.pointerUp(event.pointer);
        _pointerCount--;
        if (_pointerCount <= 0) {
          _pointerCount = 0;
          _initialPointerPosition = null;
          _dragDirectionDetermined = false;
          _updateGestureState(ChartGestureState.idle);
          if (!_isPriceAxisDragging) {
            _priceRangeTransition.resume();
            _repaintChart();
          }
        }
      },
      onPointerCancel: (event) {
        _interactiveDrawingController?.pointerUp(event.pointer,
            cancelled: true);
        _pointerCount--;
        if (_pointerCount <= 0) {
          _pointerCount = 0;
          _initialPointerPosition = null;
          _dragDirectionDetermined = false;
          _updateGestureState(ChartGestureState.idle);
          if (!_isPriceAxisDragging) {
            _priceRangeTransition.resume();
            _repaintChart();
          }
        }
      },
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque, // 确保空白区域也能接收事件
        gestures: <Type, GestureRecognizerFactory>{
          _ChartScaleGestureRecognizer:
              _buildScaleRecognizer(painter, gestureSettings),
          TapGestureRecognizer: _buildTapRecognizer(painter),
          LongPressGestureRecognizer: _buildLongPressRecognizer(painter),
        },
        child: child,
      ), // RawGestureDetector 结束
    ); // Listener 结束
  }

  GestureRecognizerFactoryWithHandlers<_ChartScaleGestureRecognizer>
      _buildScaleRecognizer(
    ChartPainter painter,
    DeviceGestureSettings? gestureSettings,
  ) {
    return GestureRecognizerFactoryWithHandlers<_ChartScaleGestureRecognizer>(
      _ChartScaleGestureRecognizer.new,
      (_ChartScaleGestureRecognizer instance) {
        instance
          ..gestureSettings = gestureSettings
          // 锁定十字线后，纯竖直拖动也要归图表处理（移动横线），
          // 否则会被祖先滚动视图抢走，横线永远无法上下移动。
          ..shouldAcceptVerticalDrag = () {
            return (widget.drawingController?.blocksBrowsing ?? false) ||
                (_isCrossLocked && !widget.isTrendLine);
          }
          ..onStart = (details) {
            isOnTap = false;
            _stopAnimation(); // 停止惯性滚动

            _isCrosshairDragging =
                _isCrossLocked && _pointerCount == 1 && !widget.isTrendLine;

            _lastPointerCount = _pointerCount;

            _scaleBase = 1.0; // 手势开始时总是 1.0
            _scaleXBase = mScaleX;

            _anchorScreenX = details.localFocalPoint.dx;
            _anchorIndex = painter.calculateSelectedX(_anchorScreenX);

            _boundaryOverscroll = 0.0; // 重置边界滑动累积
            _onDragChanged(true); // 通知拖拽状态改变
          }
          ..onUpdate = (details) {
            if (isLongPress) return;
            if (_pointerCount < 2 &&
                (widget.drawingController?.pointerBlocksPan ?? false)) {
              return;
            }

            if (_pointerCount != _lastPointerCount) {
              _scaleBase = details.scale;
              _scaleXBase = mScaleX;
              _anchorScreenX = details.localFocalPoint.dx;
              _anchorIndex = painter.calculateSelectedX(_anchorScreenX);
              _lastPointerCount = _pointerCount;
            }

            final isPinching = _pointerCount >= 2;

            // Keep the selected candle and the horizontal cross
            // line under a single finger while the crosshair is
            // locked. A second pointer hands the gesture back to
            // the normal pinch-zoom path.
            if (_isCrosshairDragging && !isPinching) {
              mSelectX =
                  details.localFocalPoint.dx.clamp(0.0, mWidth).toDouble();
              _crossY = details.localFocalPoint.dy;
              _crossHapticOnIndexChange(painter, mSelectX);
              _syncLockedCandleTime(painter);
              isOnTap = true;
              notifyChanged();
              return;
            }

            var rebuild = false;
            if (_isCrosshairDragging && isPinching) {
              rebuild = true;
              _isCrosshairDragging = false;
              _isCrossLocked = false;
              _crossY = null;
              isOnTap = false;
              _clearLockedCandleTime();
              mInfoWindowStream.sink.add(null);
            }

            if (_isCrossLocked) {
              rebuild = true;
              _isCrossLocked = false;
              _crossY = null;
              isOnTap = false;
              _clearLockedCandleTime();
              mInfoWindowStream.sink.add(null);
            }

            if (!isPinching) {
              // 单指拖动：检测滑动方向
              if (!_dragDirectionDetermined &&
                  _initialPointerPosition != null) {
                final delta =
                    details.localFocalPoint - _initialPointerPosition!;
                const threshold = 10.0; // 方向判断阈值

                if (delta.distance > threshold) {
                  _dragDirectionDetermined = true;
                  // 判断是水平还是垂直滑动
                  if (delta.dx.abs() > delta.dy.abs()) {
                    // 水平滑动 - 图表处理，阻止父级滚动
                    _updateGestureState(ChartGestureState.horizontalDragging);
                  } else {
                    // 垂直滑动 - 允许父级滚动
                    _updateGestureState(ChartGestureState.verticalDragging);
                  }
                }
              }

              final dx = details.focalPointDelta.dx;

              final delta = (dx / mScaleX) * widget.panSensitivity;

              mScrollX = (mScrollX + delta)
                  .clamp(0.0, ChartPainter.maxScrollX)
                  .toDouble();

              // Panning changes the visible high/low range; keep the
              // Y-axis transition running so it eases into the new
              // range instead of jumping.
              _priceRangeTransition.resume();

              if (widget.onReachBoundary != null) {
                if (mScrollX <= 0 && dx < 0) {
                  _boundaryOverscroll += dx.abs();
                  if (_boundaryOverscroll > widget.boundaryThreshold) {
                    _triggerBoundaryCallback(false);
                    _boundaryOverscroll = 0.0;
                  }
                } else if (mScrollX >= ChartPainter.maxScrollX &&
                    ChartPainter.maxScrollX > 0 &&
                    dx > 0) {
                  _boundaryOverscroll += dx.abs();
                  if (_boundaryOverscroll > widget.boundaryThreshold) {
                    _triggerBoundaryCallback(true);
                    _boundaryOverscroll = 0.0;
                  }
                } else {
                  _boundaryOverscroll = 0.0;
                }
              }

              isScale = false;
            } else {
              isScale = true;

              final relativeScale = details.scale / _scaleBase;
              final newScaleX = (_scaleXBase * relativeScale).clamp(0.3, 2.25);

              if (widget.autoSwitchToLine) {
                rebuild = rebuild ||
                    _isAutoLine != (newScaleX <= widget.lineThreshold);
                _isAutoLine = newScaleX <= widget.lineThreshold;
                _syncEndpointPulse();
              }

              //

              //

              final anchorLogicX = painter.getX(_anchorIndex);

              // => mTranslateX = screenX / scaleX - logicX
              final newTranslateX = _anchorScreenX / newScaleX - anchorLogicX;

              // mTranslateX = scrollX + getMinTranslateX()
              // => scrollX = mTranslateX - getMinTranslateX()
              final dataLen = painter.mDataLen;
              final pointWidth = painter.mPointWidth;

              final minTranslateX = -dataLen +
                  mWidth / newScaleX -
                  pointWidth / 2 -
                  widget.xFrontPadding / newScaleX;
              final effectiveMinTranslateX =
                  minTranslateX >= 0 ? 0.0 : minTranslateX;

              mScrollX = (newTranslateX - effectiveMinTranslateX)
                  .clamp(0.0, ChartPainter.maxScrollX)
                  .toDouble();

              mScaleX = newScaleX;

              // Pinch zoom also changes the visible high/low range.
              _priceRangeTransition.resume();
            }

            rebuild ? notifyChanged() : _repaintChart();
          }
          ..onEnd = (details) {
            isScale = false;
            _onDragChanged(false);

            // The final pointer position may hand the visible
            // high/low slot to another candle. Let that extrema
            // change settle on release instead of snapping.
            _priceRangeTransition.resume();

            final wasCrosshairDragging = _isCrosshairDragging;
            _isCrosshairDragging = false;
            if (!(widget.drawingController?.pointerConsumed ?? false) &&
                !wasCrosshairDragging &&
                _pointerCount == 0 &&
                _lastPointerCount == 1) {
              final box = context.findRenderObject()! as RenderBox;
              final velocity =
                  box.globalToLocal(details.velocity.pixelsPerSecond) -
                      box.globalToLocal(Offset.zero);
              _onFling(velocity.dx);
            }
          };
      },
    );
  }

  GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>
      _buildTapRecognizer(ChartPainter painter) {
    return GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
      TapGestureRecognizer.new,
      (TapGestureRecognizer instance) {
        instance.onTapUp = (details) {
          if ((widget.drawingController?.pointerConsumed ?? false) ||
              (widget.drawingController?.blocksBrowsing ?? false)) {
            return;
          }
          if (!widget.isTrendLine) {
            // 十字标签（加号+数据区）优先：回调宿主打开快速交易，
            // 且不改变十字锁定状态。未提供回调时标签不是按钮，
            // 点击走普通锁定/解锁逻辑。
            final quickTradePrice = widget.onCrosshairQuickTrade == null
                ? null
                : painter.quickTradePriceForHit(details.localPosition);
            if (quickTradePrice != null) {
              widget.onCrosshairQuickTrade?.call(quickTradePrice);
              return;
            }
            if (painter.isNowPriceButtonHit(details.localPosition)) {
              _animateToLatestPrice();
              return;
            }
          }
          if (!widget.isTrendLine &&
              (_isCrossLocked || painter.isInMainRect(details.localPosition))) {
            if (_isCrossLocked) {
              _isCrossLocked = false;
              _crossY = null;
              isOnTap = false;
              _clearLockedCandleTime();
              mInfoWindowStream.sink.add(null); // 清空信息弹窗
            } else {
              _isCrossLocked = true;
              isOnTap = true;
              mSelectX = details.localPosition.dx;
              // 点击在哪里，横线就停在哪里（不再钉在收盘价）。
              _crossY = details.localPosition.dy;
              // 以锁定瞬间的吸附索引为震动基准：首次移动未跨蜡烛不震动。
              _lastCrossHapticIndex = painter.calculateSelectedX(mSelectX);
              _syncLockedCandleTime(painter);
            }
            notifyChanged();
          }

          if (widget.isTrendLine && !isLongPress && enableCordRecord) {
            enableCordRecord = false;
            Offset p1 = Offset(getTrendLineX(), mSelectY);

            if (!waitingForOtherPairofCords) {
              lines.add(TrendLine(
                  p1, Offset(-1, -1), trendLineMax!, trendLineScale!));
            }

            if (waitingForOtherPairofCords) {
              var a = lines.last;
              lines.removeLast();
              lines.add(TrendLine(a.p1, p1, trendLineMax!, trendLineScale!));
              waitingForOtherPairofCords = false;
            } else {
              waitingForOtherPairofCords = true;
            }
            notifyChanged();
          }
        };
      },
    );
  }

  GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>
      _buildLongPressRecognizer(ChartPainter painter) {
    return GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
      LongPressGestureRecognizer.new,
      (LongPressGestureRecognizer instance) {
        instance
          ..onLongPressStart = (details) {
            if (widget.drawingController?.blocksBrowsing ?? false) return;
            isOnTap = false;
            isLongPress = true;

            if ((mSelectX != details.localPosition.dx ||
                    mSelectY != details.globalPosition.dy) &&
                !widget.isTrendLine) {
              mSelectX = details.localPosition.dx;
              _crossY = details.localPosition.dy;
              // 以长按落点的吸附索引为震动基准：首次移动未跨蜡烛不震动。
              _lastCrossHapticIndex = painter.calculateSelectedX(mSelectX);
              _syncLockedCandleTime(painter);
              notifyChanged();
            }

            if (widget.isTrendLine && changeinXposition == null) {
              mSelectX = changeinXposition = details.localPosition.dx;
              mSelectY = changeinYposition = details.globalPosition.dy;
              notifyChanged();
            }
            if (widget.isTrendLine && changeinXposition != null) {
              changeinXposition = details.localPosition.dx;
              changeinYposition = details.globalPosition.dy;
              notifyChanged();
            }
          }
          ..onLongPressMoveUpdate = (details) {
            if (widget.drawingController?.blocksBrowsing ?? false) return;
            if ((mSelectX != details.localPosition.dx ||
                    mSelectY != details.globalPosition.dy) &&
                !widget.isTrendLine) {
              mSelectX = details.localPosition.dx;
              mSelectY = details.localPosition.dy;
              _crossY = details.localPosition.dy;
              _crossHapticOnIndexChange(painter, mSelectX);
              _syncLockedCandleTime(painter);
              notifyChanged();
            }

            if (widget.isTrendLine) {
              mSelectX =
                  mSelectX + (details.localPosition.dx - changeinXposition!);
              changeinXposition = details.localPosition.dx;
              mSelectY =
                  mSelectY + (details.globalPosition.dy - changeinYposition!);
              changeinYposition = details.globalPosition.dy;
              notifyChanged();
            }
          }
          ..onLongPressEnd = (details) {
            if (widget.drawingController?.blocksBrowsing ?? false) return;
            isLongPress = false;
            enableCordRecord = true; // 启用趋势线坐标记录

            if (!widget.isTrendLine) {
              _isCrossLocked = true;
              isOnTap = true; // 保持 isOnTap 为 true 以显示十字线
              _syncLockedCandleTime(painter);
            } else {
              _clearLockedCandleTime();
              mInfoWindowStream.sink.add(null); // 趋势线模式清空信息弹窗
            }
            notifyChanged();
          };
      },
    );
  }
}
