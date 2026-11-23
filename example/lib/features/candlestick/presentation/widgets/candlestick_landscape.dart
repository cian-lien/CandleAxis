part of 'candlestick.dart';

extension _AIGunLandscape on _AIGunCandlestickState {
  /// [startDrawing] 为真时横屏直接进入画图菜单栏（竖屏画图按钮的入口）。
  Future<void> _openLandscape({bool startDrawing = false}) async {
    if (_openingLandscape) return;
    _openingLandscape = true;
    _landscapeInput.value = widget;
    final selection = context.read<SelectionParamsCubit>();
    try {
      // 系统原生转向后显示横向图表，复用行情和当前视口。
      await LandscapeCandlestickPage.open(
        context,
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<CandlestickCubit>.value(value: _candlestickCubit),
            BlocProvider<SelectionParamsCubit>.value(value: selection),
          ],
          child: PortraitFullscreenTokenIdentity.inheritTokenInfo(
            context,
            ValueListenableBuilder<AIGunCandlestick?>(
              valueListenable: _landscapeInput,
              builder: (_, input, _) {
                final current = input!;
                return AIGunCandlestick(
                  isLandscape: true,
                  initialDrawingMode: startDrawing,
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
      );
    } finally {
      _openingLandscape = false;
      _restoreEmbeddedViewport();
      // 横屏会话可能改动了画图存档，竖屏重新读取以保持一致。
      if (mounted) unawaited(_drawingPersistence?.reload());
    }
  }

  Widget _buildLandscape(
    BuildContext context,
    CandlestickState candles,
    SelectionParamsState selection,
  ) => _buildLandscapeContent(
    context,
    candles,
    // 共享竖屏的选择记录，横屏只展示最近选中的副图。
    selection.secondaryStates.length > 1
        ? selection.copyWith(secondaryStates: {selection.secondaryStates.last})
        : selection,
  );

  Widget _buildLandscapeContent(
    BuildContext context,
    CandlestickState candles,
    SelectionParamsState selection,
  ) => Column(
    children: [
      Stack(
        children: [
          ListenableBuilder(
            listenable: _drawingUi.header,
            builder: (context, _) => _buildLandscapeHeader(context, candles),
          ),
          // 画图说明横幅与下方图表居中对齐，排除右侧工具栏的宽度。
          Positioned(
            top: 0,
            left: 0,
            right: _landscapeRailWidth + _landscapeRailGap,
            child: Center(
              child: DrawingHintBanner(
                controller: _drawingController!,
                labels: _drawingLabels(context),
                backgroundColor: AppColors.card(context),
                foregroundColor: AppColors.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
      _drawingStatus(context),
      Expanded(
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        key: const Key('candlestick-landscape-timeframes'),
                        height: 36,
                        width: double.infinity,
                        child: TimeframeSelector(
                          source: candles.source,
                          compact: true,
                          extraVisibleCount: 4,
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // 包内画布 = 主图 × (1 + 0.2 × 区块数)；主图指标标签悬浮
                            // 在主图内部，不占高度。
                            final sections =
                                (selection.volHidden ? 0 : 1) +
                                selection.secondaryStates.length;
                            final baseHeight =
                                (constraints.maxHeight / (1 + sections * 0.2))
                                    .clamp(1.0, double.infinity);
                            const loader = Center(
                              key: Key('candlestick-landscape-loading'),
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
                                      ? Center(
                                          child: Text(
                                            S.of(context).chartNoCandles,
                                          ),
                                        )
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: _landscapeRailGap),
                _buildLandscapeTools(context, selection, candles),
              ],
            ),
            Positioned(
              top: _landscapeRailCellHeight - 1,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Divider(
                  key: const Key('candlestick-landscape-chart-divider'),
                  height: 1,
                  thickness: 1,
                  color: AppColors.borderSecondary(context),
                ),
              ),
            ),
            // 模式类工具（橡皮擦、区间统计等）的短提示，居中盖在图表区上方。
            Positioned.fill(
              right: _landscapeRailWidth + _landscapeRailGap,
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
    ],
  );
}
