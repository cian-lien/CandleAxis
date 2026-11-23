part of 'candlestick_widget.dart';

const double _mainPlotControlHeight = 36;
const double _mainPlotControlBottomInset = 8;

/// 覆盖层构建：painter 装配、图表 Stack、价格轴手势条带、缩放重置按钮、
/// 信息弹窗与边界加载指示器。
extension _CandlestickOverlays on _CandlestickWidgetState {
  ChartPainter _buildChartPainter(BaseDimension baseDimension) {
    return ChartPainter(
      widget.chartStyle,
      widget.chartColors,
      baseDimension: baseDimension,
      lines: lines, // 趋势线列表
      sink: mInfoWindowStream.sink, // 信息弹窗数据流
      xFrontPadding: widget.xFrontPadding,
      xBackPadding: widget.xBackPadding,
      isTrendLine: widget.isTrendLine, // 是否启用趋势线
      selectY: mSelectY, // 选中的 Y 坐标（趋势线用）
      crossY: _crossY, // 十字横线自由 Y（锁定拖动/长按跟手指）
      datas: _displayDatas,
      scaleX: mScaleX,
      scrollX: mScrollX,
      selectX: mSelectX,
      isLongPass:
          isLongPress && !(widget.drawingController?.blocksBrowsing ?? false),
      isOnTap: isOnTap && !(widget.drawingController?.blocksBrowsing ?? false),
      isTapShowInfoDialog: widget.isTapShowInfoDialog,
      mainStateLi: widget.mainStateLi,
      volHidden: widget.volHidden,
      secondaryStateLi: widget.secondaryStateLi,
      isLine: widget.isLine || _isAutoLine,
      hideGrid: widget.hideGrid,
      hidePriceAxis: widget.hidePriceAxis,
      showNowPrice: widget.showNowPrice,
      showDateAxis: widget.showDateAxis,
      fixedLength: widget.fixedLength,
      maDayList: widget.maDayList,
      verticalTextAlignment: widget.verticalTextAlignment,
      priceFormatter: widget.priceFormatter,
      nowPriceAlignment: widget.nowPriceAlignment,
      crossPriceAlignment: widget.crossPriceAlignment,
      isCrossLocked: _isCrossLocked &&
          !(widget.drawingController?.blocksBrowsing ?? false), // 十字线锁定状态
      valueType: widget.valueType,
      mcapFactor: widget.mcapFactor,
      mcapFormatter: widget.mcapFormatter,
      amountFormatter: widget.amountFormatter,
      tradeMarkers: widget.tradeMarkers,
      showTradeMarkers: widget.showTradeMarkers,
      avgBuyPrice: widget.avgBuyPrice,
      avgSellPrice: widget.avgSellPrice,
      avgBuyLabel: widget.avgBuyLabel,
      avgSellLabel: widget.avgSellLabel,
      showAvgPriceLines: widget.showAvgPriceLines,
      verticalScale: mVerticalScale,
      viewportAnimation: _viewportTransitionController.value,
      priceRangeTransition: _priceRangeTransition,
      manualPriceRange: _axisDragRange,
      // Range targets use final data, independent of the 180ms candle morph.
      rangeDatas: widget.datas,
      watermarkText: widget.watermarkText,
      watermarkPicture: widget.watermarkPicture,
      watermarkCache: _watermarkCache,
      pixelRatio: MediaQuery.devicePixelRatioOf(context),
      watermarkColor: widget.watermarkColor,
      // Keep the watermark above the whole overlay slot, with an 8px gap.
      watermarkBottomInset: widget.mainPlotBottomLeft == null
          ? 6
          : _mainPlotControlBottomInset + _mainPlotControlHeight + 8,
      // Move the marker one screen pixel for each pixel of chart movement,
      // then stop at its 70px resting inset.
      nowPricePositionProgress: (mScrollX * mScaleX / 60.0).clamp(0.0, 1.0),
      endpointPulse: _endpointPulseController,
      repaint: _chartPaintTick,
      textCache: _textCache,
      drawingController: widget.drawingController,
      separateDrawingLayer: true,
      drawingDatas: widget.datas,
      indicatorTextFormatter: widget.chartTranslations.indicatorTextFormatter,
    );
  }

  Widget _buildChartStack(BaseDimension baseDimension, ChartPainter painter) {
    // 与 painter 的主图底边公式一致，在布局阶段定位，避免 paint 通知重建。
    final mainPlotBottomY = ((baseDimension.mDisplayHeight.clamp(
          0.0,
          mHeight,
        )) -
        widget.chartStyle.bottomPadding -
        baseDimension.mVolumeHeight -
        baseDimension.totalSecondaryHeight -
        (widget.showDateAxis ? widget.chartStyle.dateRowHeight + 6 : 0));
    final mainPlotControlTop = (mainPlotBottomY -
            (_mainPlotControlBottomInset + _mainPlotControlHeight))
        .clamp(0.0, double.infinity)
        .toDouble();
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          reverseDuration: const Duration(milliseconds: 160),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: Alignment.topCenter,
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          ),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: RepaintBoundary(
            key: ValueKey<bool>(widget.isLine || _isAutoLine),
            child: CustomPaint(
              size: Size(double.infinity, baseDimension.mDisplayHeight),
              painter: painter,
              // Pointer previews dirty only this child boundary, leaving the
              // base chart's recorded drawing commands intact.
              child: widget.drawingController == null
                  ? null
                  : IgnorePointer(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          size: Size(
                              double.infinity, baseDimension.mDisplayHeight),
                          painter: ChartDrawingPainter(painter,
                              viewportChanges: _chartPaintTick),
                        ),
                      ),
                    ),
            ),
          ),
        ),
        if (!(widget.drawingController?.blocksBrowsing ?? false))
          _buildPriceAxisGestureStrip(),
        if (mVerticalScale != _CandlestickWidgetState._defaultVerticalScale)
          _buildPriceScaleResetButton(mainPlotBottomY),
        if (widget.mainPlotBottomLeft != null)
          Positioned(
            left: 8,
            top: mainPlotControlTop,
            height: _mainPlotControlHeight,
            child: widget.mainPlotBottomLeft!,
          ),
        if (widget.mainPlotBottomCenter != null)
          Positioned(
            left: 0,
            right: 0,
            top: mainPlotControlTop,
            height: _mainPlotControlHeight,
            child: Center(child: widget.mainPlotBottomCenter!),
          ),
        if (widget.showInfoDialog) _buildInfoDialog(),
        if (widget.drawingController != null &&
            (widget.drawingInteractive ||
                widget.drawingController!.visibleObjects
                    .any((object) => object.tool == DrawingTool.measure)))
          Positioned.fill(
              child: DrawingOverlay(
                  controller: widget.drawingController!,
                  viewportChanges: _chartPaintTick,
                  measurementOnly: !widget.drawingInteractive,
                  labels: widget.drawingLabels,
                  showToolbar: widget.showDrawingToolbar,
                  showStatisticsPanel: widget.showDrawingStatisticsPanel,
                  showHint: widget.showDrawingHint,
                  rawData: widget.datas ?? const [],
                  latestClosed: widget.latestCandleClosed,
                  isMarketCap: widget.valueType == ChartValueType.marketCap,
                  factor: widget.mcapFactor,
                  priceFormatter: (value) =>
                      painter.formatPrice(value, precision: widget.fixedLength),
                  amountFormatter: widget.amountFormatter,
                  dateFormatter: painter.getDate,
                  paintChart: painter.paintDrawingMagnifier,
                  chartSize: Size(mWidth, baseDimension.mDisplayHeight))),
        if (_isLoadingAtLeft != null && widget.loadingIndicatorBuilder != null)
          _buildLoadingIndicator(),
      ],
    );
  }

  /// 价格轴条带：竖直拖动压缩/放大主图 Y 轴。
  Widget _buildPriceAxisGestureStrip() {
    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      width: _CandlestickWidgetState._priceAxisHitWidth,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) => _beginPriceAxisDrag(),
        onVerticalDragUpdate: (details) {
          final deltaY = details.primaryDelta ?? 0;
          if (deltaY == 0) return;
          // Keep vertical scaling within the configured range:
          // compress to 20% of the default; never enlarge past the
          // default itself — beyond 1.0 the Y range would narrow below
          // the viewport data extrema and candles overflow the plot.
          // Dragging down compresses the candles; dragging up
          // enlarges them.
          mVerticalScale = (mVerticalScale * (1.0 - deltaY * 0.012))
              .clamp(0.2, 1.0)
              .toDouble();
          _axisDragRange = _axisDragBaseRange?.scaled(
            mVerticalScale / _axisDragBaseScale,
          );
          notifyChanged();
        },
        onVerticalDragEnd: (_) => _endPriceAxisDrag(),
        onVerticalDragCancel: _endPriceAxisDrag,
      ),
    );
  }

  Widget _buildPriceScaleResetButton(double mainPlotBottomY) {
    final hostBuilder = widget.priceScaleResetButtonBuilder;
    if (hostBuilder != null) {
      return Positioned(
        // 与默认按钮同一锚点（底边在主图底边上方 8px、条带内水平居中），
        // 槽位高度同 mainPlotBottomLeft 的 36px，宿主按钮贴槽底对齐。
        right: 0,
        width: _CandlestickWidgetState._priceAxisHitWidth,
        top: mainPlotBottomY - 8 - 36,
        height: 36,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: hostBuilder(context, _resetPriceScale),
        ),
      );
    }
    return Positioned(
      // 主图右下角：在 56px 价格轴条带内水平居中，钉在主图
      // 底边上方 8px，布局阶段计算位置，随高度和副图即时跟随。
      // 用 top 定位：画布顶
      // 恒与本 Stack 顶对齐，不受 host tight 约束留白影响。
      // 位于轴手势条带之后，tap 优先命中按钮。
      right: 0,
      width: _CandlestickWidgetState._priceAxisHitWidth,
      top: mainPlotBottomY - 8 - 20,
      child: Center(
        child: Material(
          color: widget.chartColors.selectFillColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: BorderSide(
              color: widget.chartColors.nowPriceColor,
              width: 1,
            ),
          ),
          child: SizedBox(
            width: 20,
            height: 20,
            child: InkWell(
              borderRadius: BorderRadius.circular(5),
              onTap: _resetPriceScale,
              child: Center(
                child: Text(
                  'A',
                  style: TextStyle(
                    color: widget.chartColors.nowPriceTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    if (_isLoadingAtLeft == null) {
      return const SizedBox.shrink();
    }

    Widget content;

    if (_loadingError != null && widget.loadingErrorBuilder != null) {
      final loadingDirection = _isLoadingAtLeft!;
      content = widget.loadingErrorBuilder!(
        loadingDirection,
        _loadingError!,
        () {
          resetLoadingState();
          _triggerBoundaryCallback(loadingDirection);
        },
      );
    } else if (widget.loadingIndicatorBuilder != null) {
      content = widget.loadingIndicatorBuilder!(_isLoadingAtLeft!);
    } else {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 0,
      left: _isLoadingAtLeft! ? 0 : null,
      right: _isLoadingAtLeft! ? null : 0,
      child: content,
    );
  }

  Widget _buildInfoDialog() {
    return StreamBuilder<InfoWindowEntity?>(
      stream: mInfoWindowStream.stream,
      builder: (context, snapshot) {
        if ((widget.drawingController?.blocksBrowsing ?? false) ||
            (!isLongPress && !isOnTap && !_isCrossLocked) ||
            widget.isLine == true ||
            !snapshot.hasData ||
            snapshot.data?.kLineEntity == null) {
          _lockedInfoWindow = null;
          return SizedBox();
        }

        final infoWindow = _stableInfoWindow(snapshot.data!);
        KLineEntity entity = infoWindow.kLineEntity;
        final dialogWidth = mWidth / 3;

        if (infoWindow.isLeft) {
          return Positioned(
            top: 25,
            left: 10.0,
            child: PopupInfoView(
              entity: entity,
              width: dialogWidth,
              chartColors: widget.chartColors,
              chartStyle: widget.chartStyle,
              chartTranslations: widget.chartTranslations,
              materialInfoDialog: widget.materialInfoDialog,
              timeFormat: widget.timeFormat,
              fixedLength: widget.fixedLength,
              priceFormatter: widget.priceFormatter,
              valueType: widget.valueType,
              mcapFactor: widget.mcapFactor,
              mcapFormatter: widget.mcapFormatter,
              amountFormatter: widget.amountFormatter,
              popupValueFormatters: widget.popupValueFormatters,
              trades: infoWindow.trades,
              tokenSymbol: widget.tokenSymbol,
              usdFormatter: widget.usdFormatter,
              tradeHistorySheetBuilder: widget.tradeHistorySheetBuilder,
            ),
          );
        }
        return Positioned(
          top: 25,
          right: 80.0,
          child: PopupInfoView(
            entity: entity,
            width: dialogWidth,
            chartColors: widget.chartColors,
            chartStyle: widget.chartStyle,
            chartTranslations: widget.chartTranslations,
            materialInfoDialog: widget.materialInfoDialog,
            timeFormat: widget.timeFormat,
            fixedLength: widget.fixedLength,
            priceFormatter: widget.priceFormatter,
            valueType: widget.valueType,
            mcapFactor: widget.mcapFactor,
            mcapFormatter: widget.mcapFormatter,
            amountFormatter: widget.amountFormatter,
            popupValueFormatters: widget.popupValueFormatters,
            trades: infoWindow.trades,
            tokenSymbol: widget.tokenSymbol,
            usdFormatter: widget.usdFormatter,
            tradeHistorySheetBuilder: widget.tradeHistorySheetBuilder,
          ),
        );
      },
    );
  }

  InfoWindowEntity _stableInfoWindow(InfoWindowEntity next) {
    final locked = _lockedInfoWindow;
    final datas = widget.datas;
    final isLatestCandle = datas != null &&
        datas.isNotEmpty &&
        datas.last.time == next.kLineEntity.time;
    if (locked != null && locked.kLineEntity.time == next.kLineEntity.time) {
      if (isLatestCandle) {
        _lockedInfoWindow = InfoWindowEntity(
          datas.last.snapshot(),
          isLeft: next.isLeft,
          trades: List<TradeMarkerEntity>.of(next.trades),
        );
        return _lockedInfoWindow!;
      }
      _lockedInfoWindow = InfoWindowEntity(
        locked.kLineEntity,
        isLeft: next.isLeft,
        trades: locked.trades,
      );
      return _lockedInfoWindow!;
    }

    _lockedInfoWindow = InfoWindowEntity(
      next.kLineEntity.snapshot(),
      isLeft: next.isLeft,
      trades: List<TradeMarkerEntity>.of(next.trades),
    );
    return _lockedInfoWindow!;
  }
}
