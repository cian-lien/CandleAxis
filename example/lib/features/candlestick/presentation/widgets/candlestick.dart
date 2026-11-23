import 'dart:async';
import 'dart:math' as math;
import 'package:candle_axis/candle_axis.dart' hide S;
import 'package:candle_axis/chart_section_border.dart';
import 'package:candle_axis/chart_translations.dart';
import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/formatting/number_format_core.dart';
import '../../../../shared/presentation/widgets/dialog/cut_corner_dialog.dart';
import '../../../../infrastructure/di/service_locator.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/presentation/widgets/sheet/cut_corner_sheet.dart';
import '../../../../shared/presentation/widgets/state/error_state_widget.dart';
import '../../../../themes/colors.dart';
import '../../../../utils/format/number.dart';
import '../../../../utils/toast.dart';
import '../../infrastructure/datasource/candlestick_settings_storage.dart';
import '../../infrastructure/datasource/drawing_storage.dart';
import '../../infrastructure/models/drawing_namespace.dart';
import '../cubit/candlestick/candlestick_cubit.dart';
import '../cubit/candlestick/candlestick_state.dart';
import '../cubit/history/history_candlestick_state.dart';
import '../cubit/selection/selection_params_cubit.dart';
import '../cubit/selection/selection_params_state.dart';
import '../cubits/display/chart_display_cubit.dart';
import '../cubits/display/chart_display_state.dart';
import '../cubits/drawing_persistence_cubit.dart';
import '../pages/fullscreen_candlestick_route.dart';
import '../pages/landscape_candlestick_page.dart';
import '../pages/portrait_fullscreen_candlestick_page.dart';
import 'candlestick_formatters.dart';
import 'candlestick_token_market_header.dart';
import 'chart_overlay_button.dart';
import 'chart_settings_bottom_sheet.dart';
import 'hidden_drawing_prompt_dialog.dart';
import 'indicator_selector.dart';
import 'kline_button_metrics.dart';
import 'kline_share_capture.dart';
import 'portrait_fullscreen_token_identity.dart';
import 'timeframe_selector.dart';

part 'candlestick_build_chart_settings_button_1.dart';
part 'candlestick_chart.dart';
part 'candlestick_average_price_label.dart';
part 'candlestick_landscape.dart';
part 'candlestick_landscape_tools.dart';
part 'candlestick_landscape_header.dart';
part 'candlestick_drawing.dart';
part 'candlestick_drawing_labels.dart';
part 'candlestick_header_market_data.dart';
part 'candlestick_popups.dart';
part 'candlestick_portrait_fullscreen.dart';

class AIGunCandlestick extends StatefulWidget {
  const AIGunCandlestick({
    super.key,
    this.height = 450,
    this.width,
    this.onGestureStateChanged,
    this.onCrosshairQuickTrade,
    this.mcapFactor,
    this.tradeMarkers = const [],
    this.tokenSymbol = '',
    this.avgBuyPrice,
    this.avgSellPrice,
    this.settingsStorage,
    this.displayCubit,
    this.isLandscape = false,
    this.isPortraitFullscreen = false,
    this.initialDrawingMode = false,
    this.drawingsHidden,
    this.viewportHandoff,
  }) : assert(!(isLandscape && isPortraitFullscreen));

  /// 详情页传给全屏会话的画图显隐状态，使「隐藏画图」跨会话保持一致。
  final ValueNotifier<bool>? drawingsHidden;

  /// 详情页传给全屏会话的水平缩放 / 滚动位置，进出全屏时视口不跳回默认。
  final ValueNotifier<ViewportSnapshot?>? viewportHandoff;
  final bool isLandscape;

  /// 竖屏全屏会话：不旋转，隐藏详情页外框，图表铺满剩余高度并可直接画图。
  final bool isPortraitFullscreen;

  /// 横屏首次构建时是否直接展开画图菜单栏。
  final bool initialDrawingMode;
  final ChartDisplayCubit? displayCubit;

  final double height;
  final double? width;

  /// 手势状态变化回调，用于与父级滚动视图协调
  final ChartGestureStateCallback? onGestureStateChanged;

  /// 点击十字标签时回调（参数=十字横线指向的价格），
  /// 宿主侧用于打开快速交易弹窗并预填限价
  final void Function(double price)? onCrosshairQuickTrade;

  /// 市值缩放系数 = marketCap / price，null 表示不支持切换
  final double? mcapFactor;

  /// 需要叠加在 K 线上的买入/卖出点（token-trades 接口）。
  final List<TradeMarkerEntity> tradeMarkers;
  final String tokenSymbol;

  /// 平均买入价（USD，token-pnl 接口），null 或 <= 0 时不绘制参考线。
  final double? avgBuyPrice;

  /// 平均卖出价（USD，token-pnl 接口），null 或 <= 0 时不绘制参考线。
  final double? avgSellPrice;

  @visibleForTesting
  final CandlestickSettingsStorage? settingsStorage;

  @override
  State<AIGunCandlestick> createState() => _AIGunCandlestickState();
}

class _AIGunCandlestickState extends State<AIGunCandlestick>
    with WidgetsBindingObserver {
  void _updateView(VoidCallback update) => setState(update);

  static const Duration _chartHeightTransitionDuration = Duration(
    milliseconds: 240,
  );
  static const bool _showDateAxis = true;

  late CandlestickCubit _candlestickCubit;
  late final ChartDisplayCubit _displayCubit;
  StreamSubscription<ChartDisplayState>? _displaySub;
  final ValueNotifier<AIGunCandlestick?> _landscapeInput = ValueNotifier(null);

  /// 横屏工具栏两种形态：普通菜单栏与画图菜单栏。
  late final ValueNotifier<bool> _landscapeDrawing = ValueNotifier(
    widget.initialDrawingMode,
  );

  /// 画图显隐；详情页自己持有，全屏会话借用详情页的同一份。
  late final ValueNotifier<bool> _drawingsHidden =
      widget.drawingsHidden ?? ValueNotifier(false);

  /// 水平视口；详情页自己持有，全屏会话借用同一份。
  late final ValueNotifier<ViewportSnapshot?> _viewport =
      widget.viewportHandoff ?? ValueNotifier(null);

  /// 已处理过的 [ChartDrawingController.toolSelectionSerial]。
  int _toolSelectionSerial = 0;

  /// 「画图已隐藏」确认弹窗是否已打开，避免重复弹窗。
  bool _hiddenPromptOpen = false;

  /// 文本输入框是否已打开，避免重复弹窗。
  bool _textPromptOpen = false;
  bool _openingLandscape = false;
  bool _openingPortraitFullscreen = false;

  /// 嵌在详情页里的竖屏图表；只有它负责轮询生命周期与全屏入口。
  bool get _isEmbedded => !widget.isLandscape && !widget.isPortraitFullscreen;
  ChartDrawingController? _drawingController;
  final _drawingUi = _DrawingUiSignals();
  DrawingPersistenceCubit? _drawingPersistence;
  StreamSubscription? _drawingPersistenceSub;
  StreamSubscription<SelectionParamsState>? _drawingSelectionSub;
  String? _drawingNamespace;
  String? _drawingTimeframe;
  CandlestickSettingsStorage? _settingsStorage;
  late bool _isInitialed = false;

  /// 默认显示市值（当 mcapFactor 可用时）
  ChartValueType _valueType = ChartValueType.marketCap;
  bool _isTrendLine = false;
  bool _showTradeMarkers = true;
  bool _showAvgPriceLines = true;
  bool _preferPortraitFullscreen = false;
  double _chartHeightScale = 1.0;
  late Color _riseColor = ChartColors().upColor;
  late Color _fallColor = ChartColors().dnColor;
  CandleBodyStyle _riseCandleBodyStyle = CandleBodyStyle.filled;
  CandleBodyStyle _fallCandleBodyStyle = CandleBodyStyle.filled;

  final ChartStyle chartStyle = ChartStyle()
    ..topPadding = 5
    ..bottomPadding = 5
    ..gridRows = 3
    ..priceAxisLabelCount = 8;

  ChartColors _chartColors(BuildContext context) => ChartColors(
    bgColor: AppColors.background(context),
    kLineColor: AppColors.primary,
    upColor: _riseColor,
    dnColor: _fallColor,
    lineFillColor: AppColors.primary.withValues(alpha: 0.14),
    lineFillInsideColor: AppColors.transparent,
    defaultTextColor: AppColors.textTertiary(context),
    nowPriceUpColor: _riseColor,
    nowPriceDnColor: _fallColor,
    nowPriceTextColor: AppColors.textPrimary(context),
    nowPriceColor: AppColors.textPrimary(context),
    nowPriceLineColor: AppColors.textTertiary(context),
    tradeOverlayOnColor: AppColors.onPrimary,
    selectBorderColor: AppColors.border(context),
    selectFillColor: AppColors.card(context),
    gridColor: AppColors.borderSecondary(context).withValues(alpha: 0.7),
    infoWindowNormalColor: AppColors.textPrimary(context),
    infoWindowTitleColor: AppColors.textSecondary(context),
    infoWindowUpColor: _riseColor,
    infoWindowDnColor: _fallColor,
    hCrossColor: AppColors.textSecondary(context),
    vCrossColor: AppColors.textSecondary(context),
    crossTextColor: AppColors.textPrimary(context),
    maxColor: AppColors.textPrimary(context),
    minColor: AppColors.textPrimary(context),
  );

  /// 计算未缩放的图表高度，与 BaseDimension 的分配逻辑保持一致。
  ///
  /// - 主图指标（MA/BOLL/SAR）不参与容器高度：其数值标签悬浮在主图顶部，
  ///   切换指标时蜡烛区与整卡高度都不变。
  /// - VOL 与副图按包内真实需求 72px（= 包内 mBaseHeight 360 × 0.2）整额
  ///   供给，主图蜡烛区高度恒定，增减 VOL/副图只改变容器整体高度。
  double _calculateUnscaledChartHeight(SelectionParamsState state) {
    // 固定区 = 主图蜡烛区 228 + 上下 padding 10 + 可选日期行 12 + 日期行间距 6。
    final dateAxisHeight = _showDateAxis ? chartStyle.dateRowHeight + 6 : 0.0;
    final fixedHeight = 238 + dateAxisHeight;
    // VOL 或单个副图的包内需求高度（360 × 0.2）。
    const chartSectionHeight = 72.0;

    final volHeight = state.volHidden ? 0.0 : chartSectionHeight;
    final secondaryHeight = state.secondaryStates.length * chartSectionHeight;
    return fixedHeight + volHeight + secondaryHeight;
  }

  @override
  void initState() {
    super.initState();
    _settingsStorage = widget.settingsStorage ?? _registeredSettingsStorage();
    _displayCubit = widget.displayCubit ?? ChartDisplayCubit(_settingsStorage);
    _applyDisplaySettings(_displayCubit.state.settings);
    _displaySub = _displayCubit.stream.listen((state) {
      if (mounted) setState(() => _applyDisplaySettings(state.settings));
    });
    if (_isEmbedded) WidgetsBinding.instance.addObserver(this);
    _drawingsHidden.addListener(_syncDrawingsHidden);
  }

  bool get _inFullscreen => _openingLandscape || _openingPortraitFullscreen;

  /// A push completes at pop, before the reverse transition reveals this
  /// chart. Apply the shared viewport once instead of rebuilding while hidden.
  void _restoreEmbeddedViewport() {
    if (mounted) setState(() {});
  }

  /// 只有当前可交互的图表写入共享视口：全屏会话期间详情页图表不写，避免
  /// 两种宽度下的滚动上限互相收口。
  void _reportViewport(ViewportSnapshot viewport) {
    if (_isEmbedded && _inFullscreen) return;
    _viewport.value = viewport;
  }

  void _syncDrawingsHidden() {
    final controller = _drawingController;
    if (controller != null && controller.hidden != _drawingsHidden.value) {
      controller.setHidden(_drawingsHidden.value);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _candlestickCubit = BlocProvider.of<CandlestickCubit>(context);
    _attachDrawingSession();
  }

  @override
  void didUpdateWidget(AIGunCandlestick oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_inFullscreen) {
      // The fullscreen listener belongs to a separate navigator subtree.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _inFullscreen) _landscapeInput.value = widget;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _candlestickCubit.startPolling();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _candlestickCubit.stopPolling();
    }
  }

  @override
  void dispose() {
    _drawingController?.removeListener(_onDrawingChanged);
    _drawingUi.dispose();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_displaySub?.cancel());
    if (widget.displayCubit == null) unawaited(_displayCubit.close());
    _landscapeInput.dispose();
    _landscapeDrawing.dispose();
    _drawingsHidden.removeListener(_syncDrawingsHidden);
    if (widget.drawingsHidden == null) _drawingsHidden.dispose();
    if (widget.viewportHandoff == null) _viewport.dispose();
    unawaited(_drawingPersistenceSub?.cancel());
    unawaited(_drawingSelectionSub?.cancel());
    final persistence = _drawingPersistence;
    final controller = _drawingController;
    if (persistence != null) {
      unawaited(persistence.close().whenComplete(() => controller?.dispose()));
    } else {
      controller?.dispose();
    }
    if (_isEmbedded) _candlestickCubit.stopPolling();
    super.dispose();
  }

  CandlestickSettingsStorage? _registeredSettingsStorage() {
    if (!getIt.isRegistered<CandlestickSettingsStorage>()) return null;
    return getIt<CandlestickSettingsStorage>();
  }

  void _applyDisplaySettings(CandlestickDisplaySettings settings) {
    _valueType = settings.valueType;
    _isTrendLine = settings.isTrendLine;
    _showTradeMarkers = settings.showTradeMarkers;
    _showAvgPriceLines = settings.showAvgPriceLines;
    _preferPortraitFullscreen = settings.preferPortraitFullscreen;
    _chartHeightScale = settings.chartHeightScale;
    _riseColor = settings.riseColor;
    _fallColor = settings.fallColor;
    _riseCandleBodyStyle = settings.riseCandleBodyStyle;
    _fallCandleBodyStyle = settings.fallCandleBodyStyle;
  }

  CandlestickDisplaySettings get _displaySettings => CandlestickDisplaySettings(
    valueType: _valueType,
    isTrendLine: _isTrendLine,
    showTradeMarkers: _showTradeMarkers,
    showAvgPriceLines: _showAvgPriceLines,
    preferPortraitFullscreen: _preferPortraitFullscreen,
    chartHeightScale: _chartHeightScale,
    riseColor: _riseColor,
    fallColor: _fallColor,
    riseCandleBodyStyle: _riseCandleBodyStyle,
    fallCandleBodyStyle: _fallCandleBodyStyle,
  );

  void _persistDisplaySettings() {
    _displayCubit.update(_displaySettings);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CandlestickCubit, CandlestickState>(
      builder: (context, candlestickState) =>
          BlocBuilder<SelectionParamsCubit, SelectionParamsState>(
            builder: (context, state) {
              if (!_isEmbedded) {
                final fullscreen = DrawingPopupScope(
                  showMenu: _showDrawingMenu,
                  confirm: _confirmDrawingClear,
                  child: KlineShareCapture(
                    builder: (context) => widget.isLandscape
                        ? _buildLandscape(context, candlestickState, state)
                        : _buildPortraitFullscreen(
                            context,
                            candlestickState,
                            state,
                          ),
                  ),
                );
                return widget.isLandscape
                    ? SideSheetScope(child: fullscreen)
                    : fullscreen;
              }
              final chartHeight = _calculateUnscaledChartHeight(state);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (_isInitialed)
                    ChartSectionBorder(
                      key: const Key('candlestick-portrait-timeframe-divider'),
                      color: _chartColors(context).gridColor,
                      top: false,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 8.h,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TimeframeSelector(
                                source: candlestickState.source,
                              ),
                            ),
                            6.horizontalSpace,
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildChartTypeToggle(context),
                                8.horizontalSpace,
                                _buildDrawingEntry(context),
                                8.horizontalSpace,
                                _buildChartSettingsButton(context),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 只为增减副图过渡；高度缩放直接跟随滑块，不参与补间。
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: chartHeight),
                    duration: _chartHeightTransitionDuration,
                    curve: Curves.easeInOutCubic,
                    builder: (context, height, _) => SizedBox(
                      height: height * _chartHeightScale,
                      child: candlestickState.status.when(
                        initial: () =>
                            const Center(child: CircularProgressIndicator()),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (message) => Center(
                          child: ErrorStateWidget(
                            message: message,
                            onRetry: _candlestickCubit.refresh,
                          ),
                        ),
                        success: (_) {
                          // 空数据时不显示组件
                          if (candlestickState.kLineEntities.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          if (!_isInitialed) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) setState(() => _isInitialed = true);
                            });
                          }
                          return _buildChart(
                            context,
                            candlestickState,
                            state,
                            360 * _chartHeightScale * height / chartHeight,
                          );
                        },
                      ),
                    ),
                  ),
                  ChartSectionBorder(
                    color: _chartColors(context).gridColor,
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: const IndicatorSelector(),
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }

  double? get _validMcapFactor =>
      widget.mcapFactor != null &&
          widget.mcapFactor!.isFinite &&
          widget.mcapFactor! > 0
      ? widget.mcapFactor
      : null;

  /// 当 mcapFactor 不可用时回退到价格模式
  ChartValueType get _effectiveValueType {
    if (_validMcapFactor == null) {
      return ChartValueType.price;
    }
    return _valueType;
  }
}
