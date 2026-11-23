part of 'candlestick.dart';

/// 横屏右栏宽度。
const double _landscapeRailWidth = 44;

/// 右栏每格高度，与包内 [DrawingTools] 的格子一致；按钮本身取 [KlineButtonMetrics]。
const double _landscapeRailCellHeight = 36;

/// 图表与右栏之间的留白，取代原来的分隔线。
const double _landscapeRailGap = 8;

extension _AIGunLandscapeTools on _AIGunCandlestickState {
  Widget _buildLandscapeTools(
    BuildContext context,
    SelectionParamsState selection,
    CandlestickState candles,
  ) {
    final cubit = context.read<SelectionParamsCubit>();
    final controller = _drawingController!;
    return SizedBox(
      key: const Key('candlestick-landscape-tools'),
      width: _landscapeRailWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 图表切换固定在右栏最顶部，不随下方工具滚动。
          SizedBox(
            key: const Key('candlestick-landscape-chart-toggle-cell'),
            width: _landscapeRailWidth,
            height: _landscapeRailCellHeight,
            child: Center(child: _buildChartTypeToggle(context)),
          ),
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: _landscapeDrawing,
              builder: (context, drawing, _) => drawing
                  ? _buildDrawingRail(context, controller, selection, cubit)
                  : _buildNormalRail(
                      context,
                      controller,
                      selection,
                      cubit,
                      candles,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// 普通菜单栏：画图入口、全部主图/副图指标、区间统计。
  Widget _buildNormalRail(
    BuildContext context,
    ChartDrawingController controller,
    SelectionParamsState selection,
    SelectionParamsCubit cubit,
    CandlestickState candles,
  ) {
    return Column(
      children: [
        SizedBox(
          height: _landscapeRailCellHeight,
          child: Center(child: _buildDrawingEntry(context)),
        ),
        Expanded(
          child: ChartSectionBorder(
            color: _chartColors(context).gridColor,
            child: _RailScrollFade(
              child: SingleChildScrollView(
                key: const Key('candlestick-landscape-indicators'),
                child: Column(
                  children: _landscapeIndicatorButtons(
                    context,
                    selection,
                    cubit,
                  ),
                ),
              ),
            ),
          ),
        ),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => SizedBox(
            height: _landscapeRailCellHeight,
            child: Center(
              child: IconButton(
                key: const Key('candlestick-landscape-statistics'),
                style: KlineButtonMetrics.circleStyle,
                tooltip: controller.mode == DrawingMode.statistics
                    ? S.of(context).chartDrawingExitStatistics
                    : S.of(context).chartDrawingStatistics,
                onPressed: candles.kLineEntities.isEmpty
                    ? null
                    : () {
                        if (controller.mode == DrawingMode.statistics) {
                          controller.exitStatistics();
                        } else {
                          controller.enterStatistics();
                        }
                      },
                icon: Icon(
                  LucideIcons.betweenHorizontalStart,
                  size: KlineButtonMetrics.landscapeIconSize,
                  color: controller.mode == DrawingMode.statistics
                      ? AppColors.primary
                      : AppColors.textSecondary(context),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 画图菜单栏：分类工具、绘制功能键，底部返回回到普通菜单栏。
  Widget _buildDrawingRail(
    BuildContext context,
    ChartDrawingController controller,
    SelectionParamsState selection,
    SelectionParamsCubit cubit,
  ) {
    return Center(
      child: DrawingTools(
        controller: controller,
        labels: _drawingLabels(context),
        itemWidth: _landscapeRailWidth,
        iconSize: KlineButtonMetrics.landscapeIconSize,
        buttonStyle: KlineButtonMetrics.circleStyle,
        foregroundColor: AppColors.textSecondary(context),
        activeColor: AppColors.primary,
        showStatisticsButton: false,
        scrollAreaBuilder: (context, child) => _RailScrollFade(child: child),
        onBack: () => _setLandscapeDrawing(false),
      ),
    );
  }

  void _setLandscapeDrawing(bool value) {
    if (_landscapeDrawing.value == value) return;
    _landscapeDrawing.value = value;
    // 切回普通菜单栏时结束绘制，避免手势仍被绘图占用。
    if (!value) _drawingController?.browse();
  }

  /// 横屏副图单选；竖屏仍可叠加多个副图。
  List<Widget> _landscapeIndicatorButtons(
    BuildContext context,
    SelectionParamsState selection,
    SelectionParamsCubit cubit,
  ) => [
    for (final indicator in MainState.values)
      _railIndicatorButton(
        context,
        key: 'main-${indicator.name}',
        label: indicator.name,
        selected: selection.mainStates.contains(indicator),
        onPressed: () => cubit.toggleMainState(indicator),
      ),
    Divider(
      height: 9,
      indent: 10,
      endIndent: 10,
      color: AppColors.borderSecondary(context),
    ),
    _railIndicatorButton(
      context,
      key: 'vol',
      label: 'VOL',
      selected: !selection.volHidden,
      onPressed: cubit.toggleVolHidden,
    ),
    for (final indicator in SecondaryState.values)
      _railIndicatorButton(
        context,
        key: 'secondary-${indicator.name}',
        label: indicator.name,
        selected: selection.secondaryStates.contains(indicator),
        onPressed: () => cubit.updateSecondaryStates(
          selection.secondaryStates.contains(indicator) ? {} : {indicator},
        ),
      ),
  ];

  Widget _railIndicatorButton(
    BuildContext context, {
    required String key,
    required String label,
    required bool selected,
    required VoidCallback onPressed,
  }) => SizedBox(
    width: _landscapeRailWidth,
    height: 32,
    child: TextButton(
      key: Key('candlestick-landscape-indicator-$key'),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        shape: const CircleBorder(),
        foregroundColor: selected
            ? AppColors.textPrimary(context)
            : AppColors.textSecondary(context),
        textStyle: TextStyle(
          fontSize: 12,
          height: 1.2,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      onPressed: onPressed,
      child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1)),
    ),
  );
}

/// 右栏可滚动区的上下渐隐遮罩：还有内容可滚时，在对应边缘叠一层
/// 背景色→透明的渐变，提示可继续滚动。
class _RailScrollFade extends StatefulWidget {
  const _RailScrollFade({required this.child});

  final Widget child;

  @override
  State<_RailScrollFade> createState() => _RailScrollFadeState();
}

class _RailScrollFadeState extends State<_RailScrollFade> {
  static const double _fadeExtent = 18;

  /// 每个遮罩只覆盖对应的滚动区，不覆盖固定按钮。
  final Map<BuildContext, (bool, bool)> _edges = {};

  bool _onMetrics(BuildContext? scrollable, ScrollMetrics metrics) {
    if (scrollable == null || metrics.axis != Axis.vertical) return false;
    final next = (metrics.extentBefore > 0.5, metrics.extentAfter > 0.5);
    if (_edges[scrollable] != next) setState(() => _edges[scrollable] = next);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final top = _edges.values.any((e) => e.$1);
    final bottom = _edges.values.any((e) => e.$2);
    final background = AppColors.background(context);
    Widget fade({required bool atTop}) => IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: atTop ? Alignment.topCenter : Alignment.bottomCenter,
            end: atTop ? Alignment.bottomCenter : Alignment.topCenter,
            colors: [background, background.withValues(alpha: 0)],
          ),
        ),
      ),
    );
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => _onMetrics(n.context, n.metrics),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => _onMetrics(n.context, n.metrics),
        child: Stack(
          children: [
            widget.child,
            if (top)
              Positioned(
                key: const Key('candlestick-rail-fade-top'),
                top: 0,
                left: 0,
                right: 0,
                height: _fadeExtent,
                child: fade(atTop: true),
              ),
            if (bottom)
              Positioned(
                key: const Key('candlestick-rail-fade-bottom'),
                bottom: 0,
                left: 0,
                right: 0,
                height: _fadeExtent,
                child: fade(atTop: false),
              ),
          ],
        ),
      ),
    );
  }
}
