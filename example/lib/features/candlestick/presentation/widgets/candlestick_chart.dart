part of 'candlestick.dart';

extension _AIGunCandlestickChart on _AIGunCandlestickState {
  Widget _buildChart(
    BuildContext context,
    CandlestickState candlestickState,
    SelectionParamsState state,
    double baseHeight,
  ) {
    chartStyle
      ..riseCandleBodyStyle = _riseCandleBodyStyle
      ..fallCandleBodyStyle = _fallCandleBodyStyle;
    final chart = RepaintBoundary(
      child: ValueListenableBuilder<ChartWatermarkPicture?>(
        valueListenable: candlestickWatermark(),
        builder: (context, watermark, _) => _buildChartWidget(
          context,
          candlestickState,
          state,
          baseHeight,
          watermark,
        ),
      ),
    );
    if (!_isEmbedded) return chart;
    return Stack(
      children: [
        Positioned.fill(child: chart),
        Positioned.fill(
          child: Center(
            child: DrawingModeNotice(
              controller: _drawingController!,
              labels: _drawingLabels(context),
              backgroundColor: AppColors.foreground(
                context,
              ).withValues(alpha: .85),
              foregroundColor: AppColors.onForeground(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartWidget(
    BuildContext context,
    CandlestickState candlestickState,
    SelectionParamsState state,
    double baseHeight,
    ChartWatermarkPicture? watermark,
  ) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return CandlestickWidget(
      candlestickState.kLineEntities,
      chartStyle,
      _chartColors(context),
      key: ValueKey(state.selectedTimeframe),
      latestCandleClosed: true,
      mBaseHeight: baseHeight,
      // 竖屏全屏用图表上方的横排画图工具栏，不叠加包内竖排工具条。
      showDrawingToolbar: _isEmbedded,
      showDrawingStatisticsPanel: !widget.isLandscape,
      // 横屏说明横幅放在头部顶部居中，见 _buildLandscape。
      showDrawingHint: !widget.isLandscape,
      mainPlotBottomLeft: _buildMainPlotBottomLeft(context),
      mainPlotBottomCenter: _isEmbedded
          ? _buildDrawingVisibilityToggle(context)
          : null,
      // 竖屏与横屏共用：右下角 A 与左下角按钮同一组件，外观一致。
      priceScaleResetButtonBuilder: (context, onReset) => ChartOverlayButton(
        key: const Key('candlestick-price-scale-reset'),
        text: 'A',
        label: S.of(context).chartPriceScaleAuto,
        onTap: onReset,
      ),
      drawingController: _drawingController,
      // 详情页竖屏只展示画图，编辑在横屏或竖屏全屏完成。
      drawingInteractive: !_isEmbedded,
      drawingLabels: _drawingLabels(context),
      // 图表类型使用 isLine；isTrendLine 是独立的趋势线绘制能力。
      isTrendLine: false,
      isLine: _isTrendLine,
      hideGrid: _isTrendLine,
      showDateAxis: _AIGunCandlestickState._showDateAxis,
      mainStateLi: state.mainStates,
      volHidden: state.volHidden,
      secondaryStateLi: state.secondaryStates,
      autoSwitchToLine: false,
      fixedLength: 2,
      isTapShowInfoDialog: true,
      timeFormat: TimeFormat.YEAR_MONTH_DAY,
      verticalTextAlignment: VerticalTextAlignment.right,
      nowPriceAlignment: NowPriceAlignment.auto,
      crossPriceAlignment: CrossPriceAlignment.right,
      lineThreshold: 0.5,
      onLoadMore: (isMore) {
        // isMore=true 表示到达左边界，需要加载更早的历史数据
        // isMore=false 表示到达右边界，最新数据由轮询处理，无需操作
        if (isMore) {
          BlocProvider.of<CandlestickCubit>(context).loadMore();
        }
      },
      priceFormatter: formatAmount,
      amountFormatter: (value) => formatCompactAmount(value, locale: locale),
      mcapFormatter: marketCapFormatter(locale),
      valueType: _effectiveValueType,
      mcapFactor: _validMcapFactor ?? 1.0,
      tradeMarkers: widget.tradeMarkers,
      tokenSymbol: widget.tokenSymbol,
      usdFormatter: widget.isLandscape
          ? marketCapFormatter(locale)
          : marketCapFormatter(locale, symbol: r'$'),
      popupValueFormatters: widget.isLandscape
          ? PopupValueFormatters(
              marketCap: marketCapFormatter(locale),
              usd: marketCapFormatter(locale),
            )
          : englishPopupValueFormatters,
      tradeHistorySheetBuilder: (sheetContext, content) async {
        await showCutCornerSheet<void>(
          sheetContext,
          builder: (context) => Material(
            key: const Key('candlestick-trade-history-sheet'),
            color: AppColors.background(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.sizeOf(context).height *
                    (SideSheetScope.of(context) ? 1 : .75),
              ),
              child: SafeArea(top: SideSheetScope.of(context), child: content),
            ),
          ),
        );
      },
      showTradeMarkers: _showTradeMarkers,
      avgBuyPrice: widget.avgBuyPrice,
      avgSellPrice: widget.avgSellPrice,
      avgBuyLabel: _avgPriceLabel(
        context,
        _effectiveValueType == ChartValueType.marketCap
            ? S.of(context).chartAvgBuyMarketCapLabel
            : S.of(context).chartAvgBuyLabel,
        widget.avgBuyPrice,
      ),
      avgSellLabel: _avgPriceLabel(
        context,
        _effectiveValueType == ChartValueType.marketCap
            ? S.of(context).chartAvgSellMarketCapLabel
            : S.of(context).chartAvgSellLabel,
        widget.avgSellPrice,
      ),
      showAvgPriceLines: _showAvgPriceLines,
      watermarkPicture: watermark,
      watermarkColor: AppColors.textQuaternary(context).withValues(alpha: 0.24),
      chartTranslations: ChartTranslations(
        indicatorTextFormatter: (key) => switch (key) {
          'invalidTimestamp' => S.of(context).chartIndicatorInvalidTimestamp,
          'intervalUnknown' => S.of(context).chartIndicatorIntervalUnknown,
          'intradayOnly' => S.of(context).chartIndicatorIntradayOnly,
          'incompleteUtcSession' =>
            S.of(context).chartIndicatorIncompleteUtcSession,
          'invalidVolumeOrPrice' =>
            S.of(context).chartIndicatorInvalidVolumeOrPrice,
          'zeroCumulativeVolume' =>
            S.of(context).chartIndicatorZeroCumulativeVolume,
          'estimatedAverage' => S.of(context).chartIndicatorEstimatedAverage,
          'quoteBaseAverage' => S.of(context).chartIndicatorQuoteBaseAverage,
          _ => S.of(context).chartIndicatorUnavailable,
        },
        date: S.of(context).date,
        open: S.of(context).opening,
        high: S.of(context).high,
        low: S.of(context).low,
        close: S.of(context).closing,
        changeAmount: S.of(context).changeAmount,
        change: S.of(context).change,
        amount: S.of(context).amount,
        vol: S.of(context).vol,
        buy: S.of(context).buy,
        sell: S.of(context).sell,
        tradeHistory: S.of(context).transactionHistory,
        buyHistory: S.of(context).chartBuyRecords,
        sellHistory: S.of(context).chartSellRecords,
        buyHistoryLabel: S.of(context).buyIn,
        sellHistoryLabel: S.of(context).sellOut,
        tradeHistoryTime: S.of(context).date,
        tradeHistoryAmount: S.of(context).amount,
        tradeHistoryValue: S.of(context).vol,
        tradeHistoryPrice: S.of(context).chartPrice,
        tradeHistoryMarketCap: S.of(context).chartMarketCap,
      ),
      onGestureStateChanged: _isEmbedded ? widget.onGestureStateChanged : null,
      onCrosshairQuickTrade: widget.onCrosshairQuickTrade,
      viewport: _viewport.value,
      onViewportChanged: _reportViewport,
    );
  }

  /// 竖屏主图底部居中的画图显隐开关；没有画图时不显示。

  /// 详情页：单一全屏入口（设置决定竖/横）。竖屏全屏：切横屏。横屏：退出回详情页。
  /// 角控图标：竖屏进入用上下 ^（chevronsUpDown），横屏进出用右上/左下对角箭头
  /// （maximize2 / minimize2）。包内槽位高 36，用 Align 贴底，避免按钮被撑成 36 高。
  Widget? _buildMainPlotBottomLeft(BuildContext context) {
    final Widget? button;
    if (_isEmbedded) {
      button = ChartOverlayButton(
        key: const Key('candlestick-fullscreen'),
        icon: _preferPortraitFullscreen
            ? LucideIcons.chevronsUpDown
            : LucideIcons.maximize2,
        label: S.of(context).chartFullscreen,
        onTap: _openFullscreen,
      );
    } else if (widget.isPortraitFullscreen) {
      button = ChartOverlayButton(
        key: const Key('candlestick-switch-to-landscape'),
        icon: LucideIcons.maximize2,
        label: S.of(context).chartSwitchToLandscapeFullscreen,
        onTap: _switchPortraitFullscreenToLandscape,
      );
    } else if (widget.isLandscape) {
      button = ChartOverlayButton(
        key: const Key('candlestick-exit-fullscreen-corner'),
        icon: LucideIcons.minimize2,
        label: S.of(context).chartExitFullscreenCorner,
        onTap: () => LandscapeCandlestickPage.close(context),
      );
    } else {
      button = null;
    }
    if (button == null) return null;
    return Align(alignment: Alignment.bottomLeft, child: button);
  }

  Widget? _buildDrawingVisibilityToggle(BuildContext context) {
    final controller = _drawingController;
    if (controller == null) return null;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.completedObjects.isEmpty) {
          return const SizedBox.shrink();
        }
        final hidden = controller.hidden;
        final labels = _drawingLabels(context);
        return SizedBox(
          height: 36,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ChartOverlayButton(
              key: const Key('candlestick-drawing-visibility'),
              icon: hidden
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              label: hidden ? labels.show : labels.hide,
              onTap: controller.toggleHidden,
            ),
          ),
        );
      },
    );
  }

  /// 画图入口：竖屏以画图菜单栏进入横屏，横屏内在两种菜单栏间切换。
  Widget _buildDrawingEntry(BuildContext context) {
    final landscape = widget.isLandscape;
    return Semantics(
      button: true,
      label: S.of(context).chartDrawingTools,
      child: GestureDetector(
        key: const Key('candlestick-drawing-entry'),
        onTap: landscape
            ? () => _setLandscapeDrawing(true)
            : () => _openLandscape(startDrawing: true),
        child: Container(
          padding: EdgeInsets.all(
            landscape
                ? KlineButtonMetrics.landscapePadding
                : KlineButtonMetrics.padding,
          ),
          child: Icon(
            LucideIcons.palette,
            size: landscape
                ? KlineButtonMetrics.landscapeIconSize
                : KlineButtonMetrics.iconSize,
            color: AppColors.textSecondary(context),
          ),
        ),
      ),
    );
  }
}
