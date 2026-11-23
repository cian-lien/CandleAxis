part of 'candlestick.dart';

/// 竖屏全屏关闭时带回的后续动作：切到横屏全屏（先出栈竖屏再开横屏，
/// 这样横屏退出后回到详情页而非竖屏全屏）。
enum _PortraitFullscreenHandoff { openLandscape }

extension _AIGunPortraitFullscreen on _AIGunCandlestickState {
  /// 图表设置「竖屏全屏K线」控制的统一全屏入口。
  Future<void> _openFullscreen() async {
    if (_preferPortraitFullscreen) {
      await _openPortraitFullscreen();
    } else {
      await _openLandscape();
    }
  }

  /// 竖屏全屏左下角：关闭竖屏全屏并打开横屏（Bitget 角控）。
  void _switchPortraitFullscreenToLandscape() {
    if (!widget.isPortraitFullscreen) return;
    Navigator.of(context).pop(_PortraitFullscreenHandoff.openLandscape);
  }

  /// 竖屏全屏：不改系统方向，推一条带可见过渡的全屏路由，
  /// 与横屏共享同一行情 / 选择参数 Cubit 与画图存档。
  Future<void> _openPortraitFullscreen() async {
    if (_openingPortraitFullscreen || _openingLandscape) return;
    _openingPortraitFullscreen = true;
    _landscapeInput.value = widget;
    final selection = context.read<SelectionParamsCubit>();
    _PortraitFullscreenHandoff? handoff;
    try {
      handoff = await Navigator.of(context, rootNavigator: true)
          .push<_PortraitFullscreenHandoff>(
            FullscreenCandlestickRoute<_PortraitFullscreenHandoff>(
              pageBuilder: (_, _, _) => MultiBlocProvider(
                providers: [
                  BlocProvider<CandlestickCubit>.value(
                    value: _candlestickCubit,
                  ),
                  BlocProvider<SelectionParamsCubit>.value(value: selection),
                ],
                child: PortraitFullscreenTokenIdentity.inheritTokenInfo(
                  context,
                  PortraitFullscreenCandlestickPage(
                    child: ValueListenableBuilder<AIGunCandlestick?>(
                      valueListenable: _landscapeInput,
                      builder: (_, input, _) {
                        final current = input!;
                        return AIGunCandlestick(
                          isPortraitFullscreen: true,
                          drawingsHidden: _drawingsHidden,
                          viewportHandoff: _viewport,
                          displayCubit: _displayCubit,
                          settingsStorage: _settingsStorage,
                          mcapFactor: current.mcapFactor,
                          tokenSymbol: current.tokenSymbol,
                          tradeMarkers: current.tradeMarkers,
                          avgBuyPrice: current.avgBuyPrice,
                          avgSellPrice: current.avgSellPrice,
                          onCrosshairQuickTrade: current.onCrosshairQuickTrade,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
    } finally {
      _openingPortraitFullscreen = false;
      _restoreEmbeddedViewport();
      // 全屏会话可能改动了画图存档，详情页重新读取以保持一致。
      if (mounted) unawaited(_drawingPersistence?.reload());
    }
    if (handoff == _PortraitFullscreenHandoff.openLandscape && mounted) {
      await _openLandscape();
    }
  }

  Widget _buildPortraitFullscreen(
    BuildContext context,
    CandlestickState candles,
    SelectionParamsState selection,
  ) => Column(
    children: [
      _buildPortraitFullscreenHeader(context, candles),
      ChartSectionBorder(
        key: const Key('candlestick-portrait-fullscreen-timeframe-border'),
        color: _chartColors(context).gridColor,
        child: SizedBox(
          key: const Key('candlestick-portrait-fullscreen-timeframes'),
          height: 40,
          child: Row(
            children: [
              const SizedBox(width: 8),
              Expanded(child: TimeframeSelector(source: candles.source)),
              _buildChartTypeToggle(context),
              8.horizontalSpace,
              _buildChartSettingsButton(context),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      ChartSectionBorder(
        key: const Key('candlestick-portrait-fullscreen-tools-border'),
        color: _chartColors(context).gridColor,
        top: false,
        child: _buildPortraitDrawingTools(context, candles),
      ),
      _drawingStatus(context),
      Expanded(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                // 与横屏一致：包内画布 = 主图 × (1 + 0.2 × 区块数)。
                final sections =
                    (selection.volHidden ? 0 : 1) +
                    selection.secondaryStates.length;
                final baseHeight =
                    (constraints.maxHeight / (1 + sections * 0.2)).clamp(
                      1.0,
                      double.infinity,
                    );
                const loader = Center(
                  child: CupertinoActivityIndicator(radius: 12),
                );
                return ClipRect(
                  child: SizedBox.expand(
                    child: candles.status.when(
                      initial: () => loader,
                      loading: () => loader,
                      error: (_) => Center(
                        child: ErrorStateWidget(
                          onRetry: _candlestickCubit.refresh,
                        ),
                      ),
                      success: (_) => candles.kLineEntities.isEmpty
                          ? Center(child: Text(S.of(context).chartNoCandles))
                          : _buildChart(
                              context,
                              candles,
                              selection,
                              baseHeight,
                            ),
                    ),
                  ),
                );
              },
            ),
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
        ),
      ),
      ChartSectionBorder(
        key: const Key('candlestick-portrait-fullscreen-indicator-border'),
        color: _chartColors(context).gridColor,
        top: false,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: IndicatorSelector(),
        ),
      ),
    ],
  );

  Widget _buildPortraitFullscreenHeader(
    BuildContext context,
    CandlestickState candles,
  ) => ListenableBuilder(
    listenable: _drawingUi.header,
    builder: (context, _) => CandlestickTokenMarketHeader(
      key: const Key('candlestick-portrait-fullscreen-header'),
      symbol: widget.tokenSymbol,
      identity: PortraitFullscreenTokenIdentity(symbol: widget.tokenSymbol),
      latestPrice: candles.kLineEntities.lastOrNull?.close,
      statistics: _headerMeasuring
          ? _buildRangeStatistics(context, candles)
          : null,
      actions: [
        IconButton(
          key: const Key('candlestick-share-kline-portrait'),
          tooltip: S.of(context).chartShareKline,
          style: KlineButtonMetrics.circleStyle,
          onPressed: () => KlineShareCapture.share(context),
          icon: Icon(
            LucideIcons.share2,
            size: KlineButtonMetrics.iconSize,
            color: AppColors.textPrimary(context),
          ),
        ),
        IconButton(
          key: const Key('candlestick-close-portrait-fullscreen'),
          tooltip: S.of(context).chartClosePortraitFullscreen,
          style: KlineButtonMetrics.circleStyle,
          onPressed: () => PortraitFullscreenCandlestickPage.close(context),
          icon: Icon(
            LucideIcons.x,
            size: KlineButtonMetrics.compactGlyphSize,
            color: AppColors.textSecondary(context),
          ),
        ),
      ],
    ),
  );

  /// 横排画图工具栏：分类工具 + 吸附 / 橡皮擦 / 显隐 / 撤销重做清空 / 区间统计。
  Widget _buildPortraitDrawingTools(
    BuildContext context,
    CandlestickState candles,
  ) {
    final controller = _drawingController!;
    final labels = _drawingLabels(context);
    final foreground = AppColors.textSecondary(context);
    const active = AppColors.primary;
    Widget button({
      required String key,
      required String tooltip,
      required Widget icon,
      required VoidCallback? onPressed,
    }) => IconButton(
      key: Key('candlestick-portrait-drawing-$key'),
      tooltip: tooltip,
      style: KlineButtonMetrics.circleStyle,
      onPressed: onPressed,
      icon: icon,
    );
    Color tint(bool selected, {bool enabled = true}) => !enabled
        ? foreground.withValues(alpha: .35)
        : selected
        ? active
        : foreground;
    return ListenableBuilder(
      listenable: _drawingUi.tools,
      builder: (context, _) {
        final statistics = controller.mode == DrawingMode.statistics;
        final erasing = controller.mode == DrawingMode.erase;
        return SizedBox(
          key: const Key('candlestick-portrait-drawing-tools'),
          height: 44,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              spacing: 8,
              children: [
                for (final category in DrawingToolCategory.values)
                  _portraitCategoryButton(
                    context,
                    controller,
                    labels,
                    category,
                    foreground,
                  ),
                SizedBox(
                  height: 20,
                  child: VerticalDivider(
                    width: 9,
                    color: AppColors.borderSecondary(context),
                  ),
                ),
                button(
                  key: 'snap',
                  tooltip: labels.snap,
                  icon: _portraitDrawingIcon(
                    DrawingUtilityIcon(
                      erase: false,
                      color: tint(controller.snapping),
                    ),
                  ),
                  onPressed: () => controller.snapping = !controller.snapping,
                ),
                button(
                  key: 'erase',
                  tooltip: labels.erase,
                  icon: _portraitDrawingIcon(
                    DrawingUtilityIcon(erase: true, color: tint(erasing)),
                  ),
                  onPressed: erasing
                      ? controller.browse
                      : controller.enterEraseMode,
                ),
                button(
                  key: 'visibility',
                  tooltip: controller.hidden ? labels.show : labels.hide,
                  icon: Icon(
                    controller.hidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: KlineButtonMetrics.landscapeIconSize,
                    color: tint(controller.hidden),
                  ),
                  onPressed: controller.toggleHidden,
                ),
                button(
                  key: 'undo',
                  tooltip: labels.undo,
                  icon: Icon(
                    LucideIcons.undo2,
                    size: KlineButtonMetrics.landscapeIconSize,
                    color: tint(false, enabled: controller.canUndo),
                  ),
                  onPressed: controller.canUndo ? controller.undo : null,
                ),
                button(
                  key: 'redo',
                  tooltip: labels.redo,
                  icon: Icon(
                    LucideIcons.redo2,
                    size: KlineButtonMetrics.landscapeIconSize,
                    color: tint(false, enabled: controller.canRedo),
                  ),
                  onPressed: controller.canRedo ? controller.redo : null,
                ),
                button(
                  key: 'clear',
                  tooltip: labels.clear,
                  icon: Icon(
                    LucideIcons.trash2,
                    size: KlineButtonMetrics.landscapeIconSize,
                    color: tint(
                      false,
                      enabled: controller.completedObjects.isNotEmpty,
                    ),
                  ),
                  onPressed: controller.completedObjects.isEmpty
                      ? null
                      : () async {
                          final accepted = await _confirmDrawingClear(
                            context,
                            message: labels.clearConfirmation,
                            cancelLabel: labels.cancel,
                            confirmLabel: labels.confirm,
                          );
                          if (accepted == true) controller.clear();
                        },
                ),
                button(
                  key: 'statistics',
                  tooltip: statistics
                      ? labels.exitStatistics
                      : labels.statistics,
                  icon: Icon(
                    LucideIcons.betweenHorizontalStart,
                    size: KlineButtonMetrics.landscapeIconSize,
                    color: tint(
                      statistics,
                      enabled: candles.kLineEntities.isNotEmpty,
                    ),
                  ),
                  onPressed: candles.kLineEntities.isEmpty
                      ? null
                      : statistics
                      ? controller.exitStatistics
                      : controller.enterStatistics,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 单工具分类点击即用；多工具分类经 [DrawingPopupScope] 弹出锚定菜单。
  /// 再次点击当前正在绘制的分类则退出绘制。
  Widget _portraitCategoryButton(
    BuildContext context,
    ChartDrawingController controller,
    DrawingLabels labels,
    DrawingToolCategory category,
    Color foreground,
  ) {
    final selected = controller.tool?.category == category;
    final tool = selected ? controller.tool! : category.tools.first;
    final color = selected ? AppColors.primary : foreground;
    final key = Key('candlestick-portrait-drawing-category-${category.name}');
    if (category.isDirect || selected) {
      return IconButton(
        key: key,
        tooltip: labels.forCategory(category),
        style: KlineButtonMetrics.circleStyle,
        onPressed: selected
            ? controller.browse
            : () => controller.selectTool(category.tools.first),
        icon: _portraitDrawingIcon(DrawingToolIcon(tool: tool, color: color)),
      );
    }
    return DrawingMenuButton<DrawingTool>(
      key: key,
      tooltip: labels.forCategory(category),
      padding: EdgeInsets.zero,
      style: KlineButtonMetrics.circleStyle,
      icon: _portraitDrawingIcon(DrawingToolIcon(tool: tool, color: color)),
      onSelected: controller.selectTool,
      itemBuilder: (context) => [
        for (final item in category.tools)
          CheckedPopupMenuItem(
            value: item,
            checked: controller.tool == item,
            child: Text(labels.forTool(item)),
          ),
      ],
    );
  }

  /// 包内画图符号固定按 22 绘制，缩放到统一图标尺寸。
  Widget _portraitDrawingIcon(Widget icon) => SizedBox.square(
    dimension: KlineButtonMetrics.landscapeIconSize,
    child: FittedBox(child: icon),
  );
}
