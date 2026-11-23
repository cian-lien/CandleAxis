import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chart_translations.dart';
import 'chart_types.dart';
import 'components/popup_info_view.dart';
import 'drawing/drawing.dart';
import 'drawing/drawing_overlay.dart';
import 'entity/index.dart';
import 'renderer/base_dimension.dart';
import 'renderer/chart_text_cache.dart';
import 'renderer/chart_watermark_cache.dart';
import 'renderer/index.dart';

export 'chart_types.dart';

part 'candlestick_state_animations.dart';
part 'candlestick_state_boundary.dart';
part 'candlestick_state_gestures.dart';
part 'candlestick_state_overlays.dart';
part 'candlestick_state_repaint.dart';
part 'candlestick_widget_support_1.dart';

/// Builds the host's price-axis auto-scale (reset) button; [onReset] restores
/// the default vertical scale. The result is bottom-aligned 8px above the main
/// plot and centered in the price-axis strip.
typedef PriceScaleResetButtonBuilder = Widget Function(
  BuildContext context,
  VoidCallback onReset,
);

class CandlestickWidget extends StatefulWidget {
  const CandlestickWidget(
    this.datas,
    this.chartStyle,
    this.chartColors, {
    super.key,
    required this.isTrendLine,
    this.drawingController,
    this.drawingLabels = const DrawingLabels(),
    this.showDrawingToolbar = true,
    this.showDrawingStatisticsPanel = true,
    this.showDrawingHint = true,
    this.mainPlotBottomLeft,
    this.mainPlotBottomCenter,
    this.priceScaleResetButtonBuilder,
    this.drawingInteractive = true,
    this.latestCandleClosed = false,
    this.xFrontPadding = 100,
    this.xBackPadding = 100,
    this.mainStateLi = const <MainState>{},
    this.secondaryStateLi = const <SecondaryState>{},
    // this.onSecondaryTap,
    this.volHidden = false,
    this.isLine = false,
    this.isTapShowInfoDialog = false,
    this.hideGrid = false,
    this.hidePriceAxis = false,
    this.showNowPrice = true,
    this.showInfoDialog = true,
    this.showDateAxis = true,
    this.materialInfoDialog = true,
    this.chartTranslations = const ChartTranslations(),
    this.timeFormat = TimeFormat.YEAR_MONTH_DAY,
    this.onLoadMore,
    this.fixedLength = 2,
    this.maDayList = const [5, 10, 20],
    this.flingTime = 600,
    this.flingRatio = 0.5,
    this.flingCurve = Curves.decelerate,
    this.isOnDrag,
    this.verticalTextAlignment = VerticalTextAlignment.left,
    this.mBaseHeight = 360,
    this.priceFormatter,
    this.nowPriceAlignment,
    this.crossPriceAlignment = CrossPriceAlignment.auto,
    this.onReachBoundary,
    this.autoSwitchToLine = false,
    this.lineThreshold = 0.5,
    this.panSensitivity = 1.0,
    this.loadingIndicatorBuilder,
    this.loadingErrorBuilder,
    this.boundaryThreshold = 50.0,
    this.debounceDelay = 1000,
    this.onGestureStateChanged,
    this.onCrosshairQuickTrade,
    this.valueType = ChartValueType.price,
    this.mcapFactor = 1.0,
    this.mcapFormatter,
    this.amountFormatter,
    this.popupValueFormatters,
    this.watermarkText,
    this.watermarkPicture,
    this.watermarkColor = const Color(0xFFD9DDDE),
    this.tradeMarkers = const [],
    this.tokenSymbol = '',
    this.usdFormatter,
    this.tradeHistorySheetBuilder,
    this.showTradeMarkers = true,
    this.avgBuyPrice,
    this.avgSellPrice,
    this.avgBuyLabel,
    this.avgSellLabel,
    this.showAvgPriceLines = true,
    this.onLockedCandleTimeChanged,
    this.viewport,
    this.onViewportChanged,
  });

  final List<KLineEntity>? datas;

  /// Optional host control anchored inside the main plot, above any subchart.
  final Widget? mainPlotBottomLeft;

  /// Optional host control horizontally centered at the main plot bottom.
  final Widget? mainPlotBottomCenter;

  /// Optional host replacement for the default "A" price-scale reset pill,
  /// shown only while the vertical scale differs from the default.
  final PriceScaleResetButtonBuilder? priceScaleResetButtonBuilder;

  /// When false, [drawingController] objects are painted only: no overlay UI
  /// and no pointer routing, so drawings cannot be selected or edited.
  final bool drawingInteractive;
  final bool showDrawingToolbar;
  final bool showDrawingStatisticsPanel;

  /// 是否在图表顶部显示画图说明横幅；宿主自行摆放 [DrawingHintBanner] 时关闭。
  final bool showDrawingHint;

  final Set<MainState> mainStateLi;

  final bool volHidden;

  final Set<SecondaryState> secondaryStateLi;

  final bool isLine;

  final bool isTapShowInfoDialog;

  final bool hideGrid;

  /// 隐藏主图右侧价格刻度。与 [hideGrid] 独立：折线（分时）模式常见组合是
  /// `hideGrid: true, hidePriceAxis: false` —— 无网格但保留右侧价格刻度。
  final bool hidePriceAxis;

  final bool showNowPrice;

  final bool showInfoDialog;

  /// Whether to draw the bottom date axis row and reserve layout space for it.
  final bool showDateAxis;

  final bool materialInfoDialog;

  final ChartTranslations chartTranslations;

  final List<String> timeFormat;

  final double mBaseHeight;

  final Function(bool)? onLoadMore;

  final int fixedLength;

  final List<int> maDayList;

  final int flingTime;

  final double flingRatio;

  final Curve flingCurve;

  final Function(bool)? isOnDrag;

  final ChartColors chartColors;

  final ChartStyle chartStyle;

  final VerticalTextAlignment verticalTextAlignment;

  final bool isTrendLine;

  final ChartDrawingController? drawingController;
  final DrawingLabels drawingLabels;
  final bool latestCandleClosed;

  final double xFrontPadding;

  final double xBackPadding;

  final PriceFormatter? priceFormatter;

  final NowPriceAlignment? nowPriceAlignment;

  final CrossPriceAlignment crossPriceAlignment;

  final FutureOr<void> Function(bool isLeft)? onReachBoundary;

  final bool autoSwitchToLine;

  final double lineThreshold;

  final double panSensitivity;

  final Widget Function(bool isLeft)? loadingIndicatorBuilder;

  final Widget Function(bool isLeft, Object error, VoidCallback retry)?
      loadingErrorBuilder;

  final double boundaryThreshold;

  final int debounceDelay;

  /// 手势状态变化回调，用于与父级滚动视图协调
  /// 当手势状态变化时会调用此回调
  final ChartGestureStateCallback? onGestureStateChanged;

  /// 点击十字标签（加号 + 数据区）时回调，参数为十字横线指向的价格。
  /// 用于宿主侧打开快速交易弹窗并预填限价；包内不含任何业务逻辑。
  final void Function(double price)? onCrosshairQuickTrade;

  /// 当前显示的数据维度（价格 or 市值）
  final ChartValueType valueType;

  /// 市值缩放系数 = currentMarketCap / currentPrice
  final double mcapFactor;

  /// 市值格式化函数（大数字缩写，如 $3.89M）
  final PriceFormatter? mcapFormatter;

  /// 代币数量格式化函数（成交量和 K 线数额）。
  final PriceFormatter? amountFormatter;
  final PopupValueFormatters? popupValueFormatters;

  /// Optional branding overlaid inside the main chart's bottom-left corner.
  /// Drawn on the background layer, so candles and indicators paint over it.
  final String? watermarkText;

  /// 优先于 [watermarkText] 绘制的矢量水印；为 null 时回退到文字。
  final ChartWatermarkPicture? watermarkPicture;
  final Color watermarkColor;

  /// 需要叠加在 K 线上的买入/卖出点，价格与蜡烛同一 domain（token 价格）。
  final List<TradeMarkerEntity> tradeMarkers;

  /// Token ticker appended to trade quantities in history.
  final String tokenSymbol;

  /// Formats USD-denominated trade notionals.
  final PriceFormatter? usdFormatter;

  /// Lets the host app provide its shared sheet container without coupling
  /// this reusable package to app-specific presentation widgets.
  final Future<void> Function(BuildContext context, Widget content)?
      tradeHistorySheetBuilder;

  /// 是否绘制买入/卖出成交点。
  final bool showTradeMarkers;

  /// 平均买入/卖出价参考线（token 价格 domain）；为 null 或 <= 0 时不绘制。
  final double? avgBuyPrice, avgSellPrice;

  /// 均价参考线的文字标签，由调用方预先格式化好（含 i18n 文案），包内不内嵌
  /// 任何本地化文本；为 null 时对应参考线不绘制标签（但仍绘制参考线）。
  final String? avgBuyLabel, avgSellLabel;

  /// 是否绘制平均买入/卖出价参考线和标签。
  final bool showAvgPriceLines;

  /// Reports the timestamp of the candle currently locked by the crosshair.
  /// Null means the crosshair is unlocked/hidden.
  final ValueChanged<int?>? onLockedCandleTimeChanged;

  /// Horizontal zoom/scroll applied when the chart state is created, so a
  /// host can hand the visible window over to another chart instance (e.g.
  /// entering fullscreen) without a default-viewport frame.
  final ViewportSnapshot? viewport;

  /// Reports the horizontal zoom/scroll whenever it changes.
  final ValueChanged<ViewportSnapshot>? onViewportChanged;

  @override
  _CandlestickWidgetState createState() => _CandlestickWidgetState();
}

// ignore_for_file: library_private_types_in_public_api
