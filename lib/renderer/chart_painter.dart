import 'dart:async' show StreamSink;
import 'dart:math' as math;
import 'dart:ui' show ClipOp;

import 'package:flutter/material.dart';

import '../candlestick_widget.dart'
    show
        ChartValueType,
        ChartWatermarkPicture,
        CrossPriceAlignment,
        MainState,
        NowPriceAlignment,
        PriceFormatter,
        SecondaryState;
import '../chart_section_border.dart';
import '../drawing/drawing.dart';
import '../drawing/drawing_canvas.dart';
import '../entity/info_window_entity.dart';
import '../entity/k_line_entity.dart';
import '../entity/trade_marker_entity.dart';
import '../utils/date_format_util.dart';
import '../utils/number_util.dart';
import 'base_chart_painter.dart';
import 'base_chart_renderer.dart';
import 'base_dimension.dart';
import 'chart_text_cache.dart';
import 'chart_watermark_cache.dart';
import 'main_renderer.dart';
import 'price_axis.dart';
import 'secondary_renderer.dart';
import 'trade_marker_painter_mixin.dart';
import 'vol_renderer.dart';

part '../drawing/chart_painter_drawing.dart';
part 'chart_painter_background.dart';
part 'chart_painter_crosshair.dart';
part 'chart_painter_now_price.dart';
part 'chart_painter_price_axis.dart';
part 'chart_painter_series.dart';
part 'chart_painter_trend_line.dart';

class TrendLine {
  TrendLine(this.p1, this.p2, this.maxHeight, this.scale);
  final Offset p1;
  final Offset p2;
  final double maxHeight;
  final double scale;
}

double? trendLineX;

double getTrendLineX() {
  return trendLineX ?? 0;
}

class ChartPainter extends BaseChartPainter with TradeMarkerPainterMixin {
  ChartPainter(
    this.chartStyle,
    this.chartColors, {
    required this.lines,
    required this.isTrendLine,
    required this.selectY,
    required this.sink,
    required datas,
    required scaleX,
    required scrollX,
    required isLongPass,
    required selectX,
    required xFrontPadding,
    required xBackPadding,
    required this.baseDimension,
    isOnTap,
    isTapShowInfoDialog,
    required this.verticalTextAlignment,
    mainStateLi,
    volHidden,
    secondaryStateLi,
    bool isLine = false,
    this.hideGrid = false,
    this.hidePriceAxis = false,
    this.showNowPrice = true,
    bool showDateAxis = true,
    this.fixedLength = 2,
    this.maDayList = const [5, 10, 20],
    this.priceFormatter,
    this.nowPriceAlignment,
    this.crossPriceAlignment = CrossPriceAlignment.auto,
    this.isCrossLocked = false,
    this.crossY,
    this.valueType = ChartValueType.price,
    this.mcapFactor = 1.0,
    this.mcapFormatter,
    this.amountFormatter,
    this.tradeMarkers = const [],
    this.showTradeMarkers = true,
    this.avgBuyPrice,
    this.avgSellPrice,
    this.avgBuyLabel,
    this.avgSellLabel,
    this.showAvgPriceLines = true,
    this.verticalScale = 1.0,
    this.viewportAnimation = 1.0,
    super.priceRangeTransition,
    super.manualPriceRange,
    super.rangeDatas,
    this.watermarkText,
    this.watermarkPicture,
    this.watermarkCache,
    this.pixelRatio = 1,
    this.watermarkBottomInset = 6,
    this.watermarkColor = const Color(0xFFD9DDDE),
    this.nowPricePositionProgress = 0.0,
    this.endpointPulse,
    Listenable? repaint,
    this.textCache,
    this.drawingController,
    this.separateDrawingLayer = false,
    this.drawingDatas,
    this.indicatorTextFormatter,
  }) : super(chartStyle,
            datas: datas,
            scaleX: scaleX,
            scrollX: scrollX,
            isLongPress: isLongPass,
            baseDimension: baseDimension,
            isOnTap: isOnTap,
            isTapShowInfoDialog: isTapShowInfoDialog,
            selectX: selectX,
            mainStateLi: mainStateLi,
            volHidden: volHidden,
            secondaryStateLi: secondaryStateLi,
            xFrontPadding: xFrontPadding,
            xBackPadding: xBackPadding,
            showDateAxis: showDateAxis,
            isLine: isLine,
            repaint: Listenable.merge([
              repaint,
              endpointPulse,
              if (!separateDrawingLayer) drawingController
            ])) {
    selectPointPaint = Paint()
      ..isAntiAlias = true
      ..strokeWidth = 0.5
      ..color = chartColors.selectFillColor;
    selectorBorderPaint = Paint()
      ..isAntiAlias = true
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke
      ..color = chartColors.selectBorderColor;
    nowPricePaint = Paint()
      ..strokeWidth = chartStyle.nowPriceLineWidth
      ..isAntiAlias = true;
  }
  final List<TrendLine> lines;
  @override
  final ChartTextCache? textCache;
  final _secondarySeriesCaches = <SecondaryState, SecondarySeriesCache>{};
  final _mainSeriesCache = MainSeriesCache();
  final bool isTrendLine;
  final double selectY;
  static double get maxScrollX => BaseChartPainter.maxScrollX;
  final bool isCrossLocked;

  /// 十字横线的自由 Y（屏幕局部坐标）。null = 钉在所选 K 线收盘价；
  /// 非 null = 跟随手指（由 widget 在锁定拖动/长按时写入）。
  final double? crossY;
  late BaseChartRenderer mMainRenderer;
  BaseChartRenderer? mVolRenderer;
  // Renderer order matches secondaryStateLi, so a list avoids hash-set
  // allocation/iteration overhead on every paint.
  final List<BaseChartRenderer> mSecondaryRendererList = <BaseChartRenderer>[];
  StreamSink<InfoWindowEntity?> sink;
  int fixedLength;
  List<int> maDayList;
  @override
  final ChartColors chartColors;
  late Paint selectPointPaint, selectorBorderPaint, nowPricePaint;
  final Paint _backgroundPaint = Paint();
  @override
  final ChartStyle chartStyle;
  final bool hideGrid;

  /// 隐藏主图右侧价格刻度。与 [hideGrid] 解耦：折线（分时）模式隐藏网格但
  /// 保留价格刻度。
  final bool hidePriceAxis;
  final bool showNowPrice;
  final VerticalTextAlignment verticalTextAlignment;
  @override
  final BaseDimension baseDimension;
  final PriceFormatter? priceFormatter;
  final NowPriceAlignment? nowPriceAlignment;
  final CrossPriceAlignment crossPriceAlignment;
  final ChartValueType valueType;
  final double mcapFactor;
  final PriceFormatter? mcapFormatter;
  final PriceFormatter? amountFormatter;
  final String Function(String)? indicatorTextFormatter;
  @override
  final double verticalScale;
  @override
  double viewportAnimation;
  final String? watermarkText;
  final ChartWatermarkPicture? watermarkPicture;
  final ChartWatermarkCache? watermarkCache;
  final double pixelRatio;
  final Color watermarkColor;
  final double watermarkBottomInset;
  double nowPricePositionProgress;

  /// Repaints the endpoint halo without rebuilding widgets; null disables it.
  final Animation<double>? endpointPulse;
  List<PriceAxisLabel> priceAxisLabels = const [];
  @visibleForTesting
  Rect? nowPriceTagRect;
  final ChartDrawingController? drawingController;
  final bool separateDrawingLayer;
  Object? _drawingGeometryKey;
  final _drawingGeometryCache = DrawingGeometryCache();
  final List<KLineEntity>? drawingDatas;
  @visibleForTesting
  Offset? endpointDotOffset;
  @visibleForTesting
  double get endpointPulseValue => endpointPulse?.value ?? 0.0;
  @override
  final List<TradeMarkerEntity> tradeMarkers;
  @override
  final bool showTradeMarkers;
  @override
  final double? avgBuyPrice, avgSellPrice;
  @override
  final String? avgBuyLabel, avgSellLabel;
  @override
  final bool showAvgPriceLines;
  String formatPrice(double price, {int? precision}) {
    if (valueType == ChartValueType.marketCap) {
      final mcapValue = price * mcapFactor;
      if (mcapFormatter != null) return mcapFormatter!(mcapValue);
      if (priceFormatter != null) return priceFormatter!(mcapValue);
      return mcapValue.toStringAsFixed(precision ?? fixedLength);
    }
    if (priceFormatter != null) {
      return priceFormatter!(price);
    }
    return price.toStringAsFixed(precision ?? fixedLength);
  }

  @visibleForTesting
  static double crosshairPriceFromY(
    double y, {
    required double chartTop,
    required double maxValue,
    required double scaleY,
  }) {
    return maxValue - (y - chartTop) / scaleY;
  }

  /// 十字位置相对基准价的涨跌百分比（带符号，两位小数）。
  /// refPrice <= 0 时无法计算有意义百分比，返回 null（隐藏百分比行）。
  @visibleForTesting
  static String? crosshairChangePercent(double price, double refPrice) {
    if (refPrice <= 0) return null;
    final pct = (price - refPrice) / refPrice * 100;
    return '${pct > 0 ? '+' : ''}${pct.toStringAsFixed(2)}%';
  }

  double priceFromY(double y) {
    final renderer = mMainRenderer;
    return crosshairPriceFromY(
      y,
      chartTop: renderer.chartRect.top,
      maxValue: renderer.maxValue,
      scaleY: renderer.scaleY,
    );
  }

  Rect? crossTagHitRect;
  double? _lastCrossTagPrice;

  @visibleForTesting
  Rect? crossPlusCircleRect;

  @visibleForTesting
  Rect? crossDividerRect;

  bool get _isCrossVisible =>
      !isTrendLine &&
      (isLongPress == true ||
          isCrossLocked ||
          (isTapShowInfoDialog && isOnTap));

  /// 十字快速交易热区：数值标签与加号按钮均可独立命中。
  bool isCrossTagHit(Offset position) {
    if (!_isCrossVisible) return false;
    if (crossTagHitRect?.contains(position) ?? false) return true;
    return crossPlusCircleRect?.contains(position) ?? false;
  }

  double? quickTradePriceForHit(Offset position) {
    if (!isCrossTagHit(position)) return null;
    return _lastCrossTagPrice;
  }

  @override
  void prepareChart(Size size) {
    super.prepareChart(size);
    _updateDrawingCoordinates();
    _drawingGeometryKey = _drawingKey(size);
  }

  @override
  void initChartRenderer() {
    if (datas != null && datas!.isNotEmpty) {
      var t = datas![0];
      fixedLength =
          NumberUtil.getMaxDecimalLength(t.open, t.close, t.high, t.low);
    }
    final mainRenderer = MainRenderer(
      mMainRect,
      mMainMaxValue,
      mMainMinValue,
      mTopPadding,
      mainStateLi.toList(),
      isLine,
      fixedLength,
      chartStyle,
      chartColors,
      scaleX,
      verticalTextAlignment,
      maDayList,
      priceFormatter,
      valueType,
      mcapFactor,
      mcapFormatter,
      datas,
      indicatorTextFormatter,
    );
    mainRenderer.priceAxisLineYs = _resolvePriceAxisLineYs(mainRenderer);
    mMainRenderer = mainRenderer..textCache = textCache;
    if (mVolRect != null) {
      mVolRenderer = VolRenderer(
          mVolRect!,
          mVolMaxValue,
          mVolMinValue,
          mChildPadding,
          fixedLength,
          chartStyle,
          chartColors,
          amountFormatter ?? priceFormatter)
        ..textCache = textCache;
    }
    mSecondaryRendererList.clear();
    for (int i = 0; i < mSecondaryRectList.length; ++i) {
      mSecondaryRendererList.add(SecondaryRenderer(
        mSecondaryRectList[i].mRect,
        mSecondaryRectList[i].mMaxValue,
        mSecondaryRectList[i].mMinValue,
        mChildPadding,
        secondaryStateLi.elementAt(i),
        fixedLength,
        chartStyle,
        chartColors,
        scaleX,
        priceFormatter,
        valueType,
        mcapFactor,
        mcapFormatter,
      )..textCache = textCache);
    }
  }

  @override
  void drawBg(Canvas canvas, Size size) => drawBgImpl(canvas, size);
  @override
  void drawGrid(canvas) => drawGridImpl(canvas);

  @override
  void drawChart(Canvas canvas, Size size, {bool mainOnly = false}) {
    _drawChartSeries(canvas, size, [mMainRenderer],
        clip: mMainRect, cullToClip: mainOnly);
    if (!mainOnly) {
      _drawChartSeries(canvas, size, [
        if (mVolRenderer != null) mVolRenderer!,
        ...mSecondaryRendererList,
      ]);
    }
    // The endpoint and current-price tag share the displayed Y transform.
    if (isLine && datas != null && datas!.isNotEmpty) {
      endpointDotOffset = Offset(
        (getX(datas!.length - 1) + mTranslateX) * scaleX,
        mMainRenderer.getY(datas!.last.close),
      );
    } else {
      endpointDotOffset = null;
    }

    canvas.save();
    canvas.translate(mTranslateX * scaleX, 0.0);
    canvas.scale(scaleX, 1.0);
    if ((isLongPress == true ||
            isCrossLocked ||
            (isTapShowInfoDialog && isOnTap)) &&
        isTrendLine == false) {
      drawCrossLine(canvas, size);
    }
    if (isTrendLine == true) drawTrendLines(canvas, size);
    canvas.restore();
    if (!separateDrawingLayer || mainOnly) _drawDrawingObjects(canvas);
  }

  @override
  void drawPriceAxis(Canvas canvas) => drawMainPriceAxisImpl(canvas);

  @override
  void drawVerticalText(canvas) => drawVerticalTextImpl(canvas);

  @override
  void drawDate(Canvas canvas, Size size) {
    drawDateImpl(canvas, size);
  }

  @override
  void drawCrossLineText(Canvas canvas, Size size) {
    drawCrossLineTextImpl(canvas, size);
  }

  @override
  void drawText(Canvas canvas, KLineEntity data, double x) {
    if (!separateDrawingLayer || drawingController == null) {
      drawTextImpl(canvas, data, x);
    }
  }

  @override
  void drawMaxAndMin(Canvas canvas) {
    drawMaxAndMinImpl(canvas);
  }

  @override
  void drawNowPrice(Canvas canvas) {
    drawNowPriceImpl(canvas);
  }

  @override
  void drawNowPriceLine(Canvas canvas) {
    drawNowPriceLineImpl(canvas);
  }

  @override
  void drawNowPriceLabel(Canvas canvas) {
    drawNowPriceLabelImpl(canvas);
  }

  bool isNowPriceButtonHit(Offset position) {
    return isNowPriceButtonHitImpl(position);
  }

  void drawTrendLines(Canvas canvas, Size size) {
    drawTrendLinesImpl(canvas, size);
  }

  @override
  void drawCrossLine(Canvas canvas, Size size) {
    drawCrossLineImpl(canvas, size);
  }

  TextPainter getTextPainter(text, color) {
    color ??= chartColors.defaultTextColor;
    TextSpan span = TextSpan(text: '$text', style: getTextStyle(color));
    return textCache?.layout(span) ??
        (TextPainter(text: span, textDirection: TextDirection.ltr)..layout());
  }

  String getDate(int? date) => dateFormat(
        DateTime.fromMillisecondsSinceEpoch(
            date ?? DateTime.now().millisecondsSinceEpoch),
        mFormats,
      );

  /// Reuses the initialized renderers and transforms without recalculating
  /// viewport extrema, animation snapshots or main-chart layout.
  void paintDrawingMagnifier(Canvas canvas, Size size) {
    paintDrawingMagnifierImpl(canvas, size);
  }

  @override
  double getMainY(double y) => mMainRenderer.getY(y);

  bool isInMainRect(Offset point) => mMainRect.contains(point);
}
// ignore_for_file: overridden_fields, strict_top_level_inference, type_annotate_public_apis
