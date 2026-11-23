import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../candlestick_widget.dart'
    show ChartValueType, MainState, PriceFormatter;
import '../entity/candle_entity.dart';
import '../entity/k_line_entity.dart';
import '../indicators/indicator_presentation.dart';
import '../indicators/indicator_values.dart';
import 'base_chart_renderer.dart';
import 'price_axis.dart';

part 'main_renderer_calculate_dynamic_shadow_width_1.dart';
part 'main_renderer_indicators.dart';
part 'main_renderer_price_axis.dart';
part 'main_renderer_series.dart';
part 'main_renderer_batch.dart';
part 'main_renderer_cache.dart';

/// 纵轴文字对齐方式枚举
enum VerticalTextAlignment { left, right }

// ===== 趋势线全局变量 =====
// 用于在不同渲染器之间共享趋势线的坐标数据
/// 趋势线区域的最大价格值
double? trendLineMax;

/// 趋势线区域的 Y 轴缩放比例
double? trendLineScale;

/// 趋势线内容区域的顶部坐标
double? trendLineContentRec;

/// 主图渲染器
/// 负责绘制 K 线图的主要内容，包括：
/// - 蜡烛图（实体和影线）
/// - 分时图（折线图）
/// - 技术指标（MA、BOLL、SAR）
/// - 价格文字和网格
class MainRenderer extends BaseChartRenderer<CandleEntity> {
  /// 主图渲染器构造函数
  /// [mainRect] 主图区域矩形
  /// [maxValue] 可见范围内的最大价格
  /// [minValue] 可见范围内的最小价格
  /// [topPadding] 顶部内边距
  /// [stateLi] 要显示的指标列表
  /// [isLine] 是否为分时图模式
  /// [fixedLength] 价格显示的小数位数
  /// [chartStyle] 样式配置
  /// [chartColors] 颜色配置
  /// [scaleX] 水平缩放倍数
  /// [verticalTextAlignment] 纵轴文字对齐方式
  /// [maDayList] MA 均线周期列表
  /// [priceFormatter] 自定义价格格式化函数
  MainRenderer(
      Rect mainRect,
      double maxValue,
      double minValue,
      double topPadding,
      this.stateLi,
      this.isLine,
      int fixedLength,
      this.chartStyle,
      this.chartColors,
      this.scaleX,
      this.verticalTextAlignment,
      [this.maDayList = const [5, 10, 20],
      PriceFormatter? priceFormatter,
      this.valueType = ChartValueType.price,
      this.mcapFactor = 1.0,
      this.mcapFormatter,
      this.chartData,
      this.indicatorTextFormatter])
      : super(
            chartRect: mainRect,
            maxValue: maxValue,
            minValue: minValue,
            topPadding: topPadding,
            fixedLength: fixedLength,
            gridColor: chartColors.gridColor,
            priceFormatter: priceFormatter) {
    // 初始化蜡烛图参数
    mCandleWidth = chartStyle.candleWidth;
    mCandleLineWidth = chartStyle.candleLineWidth;
    _shadowWidth = _calculateDynamicShadowWidth();
    _indicatorWidth = _calculateMainIndicatorWidth();

    // 初始化分时图画笔
    mLinePaint = Paint()
      ..isAntiAlias = true // 开启抗锯齿
      ..style = PaintingStyle.stroke // 描边模式
      ..strokeWidth = mLineStrokeWidth
      ..color = chartColors.kLineColor;

    // 计算实际绘制区域（去除上下 padding）
    _contentRect = Rect.fromLTRB(
        chartRect.left,
        chartRect.top + _contentPadding,
        chartRect.right,
        chartRect.bottom - _contentPadding);

    // Base renderer normalizes zero-width and unavailable ranges.
    scaleY = _contentRect.height / (this.maxValue - this.minValue);
    // Legacy trend-line gestures read these values between frames.
    updateTrendLineData();
  }

  /// 蜡烛实体的宽度（像素）
  late double mCandleWidth;
  late final double _shadowWidth, _indicatorWidth;

  /// 蜡烛影线的宽度（像素）
  late double mCandleLineWidth;

  /// 要显示的主图指标列表
  List<MainState> stateLi;

  /// 最近一次绘制的主图指标标签区域（画布坐标），仅供测试校验遮挡关系。
  List<Rect> debugIndicatorLabelRects = const [];

  /// 价格刻度线 Y（画布坐标），由 painter 按标签高度解析后写入；主图网格横线
  /// 与价格标签共用，保证二者对齐。
  List<double> priceAxisLineYs = const [];

  /// Fixed nice prices; null supports callers supplying pixel tick lines.
  List<double>? priceAxisValues;

  /// 是否为分时图模式（true = 折线图，false = 蜡烛图）
  bool isLine;

  /// 实际绘制的内容区域（去除了上下 padding）
  late Rect _contentRect;

  /// 内容区域的上下内边距（像素）
  final double _contentPadding = 5.0;

  /// MA 均线的周期列表（例如 [5, 10, 20]）
  List<int> maDayList;

  /// 图表样式配置
  final ChartStyle chartStyle;

  /// 图表颜色配置
  final ChartColors chartColors;

  /// 分时图折线的视觉宽度。画布只做水平缩放（scale(scaleX, 1.0)），折线的
  /// 竖向厚度就等于 strokeWidth 本身，因此按常量绘制即可保证缩放时观感不变。
  final double mLineStrokeWidth = 2.0;

  /// 水平缩放倍数
  double scaleX;

  /// 分时图折线的画笔
  late Paint mLinePaint;

  /// 纵轴文字对齐方式
  final VerticalTextAlignment verticalTextAlignment;

  /// 当前显示的数据维度
  final ChartValueType valueType;

  /// 市值缩放系数
  final double mcapFactor;

  /// 市值格式化函数
  final PriceFormatter? mcapFormatter;
  final List<KLineEntity>? chartData;
  final String Function(String)? indicatorTextFormatter;
  @override
  void drawText(Canvas canvas, CandleEntity data, double x) {
    if (data is KLineEntity) drawIndicatorLabels(canvas, data, x);
  }

  @override
  void drawChart(CandleEntity lastPoint, CandleEntity curPoint, double lastX,
      double curX, Size size, Canvas canvas) {
    if (isLine) {
      drawPolyline(lastPoint.close, curPoint.close, canvas, lastX, curX);
    } else {
      drawCandle(curPoint, canvas, curX);
    }
    if (lastPoint is KLineEntity && curPoint is KLineEntity) {
      drawIndicators(lastPoint, curPoint, lastX, curX, canvas);
    }
  }

  Shader? mLineFillShader;
  Path? mLinePath, mLineFillPath;
  Paint mLineFillPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  //画折线图
  void drawPolyline(double lastPrice, double curPrice, Canvas canvas,
      double lastX, double curX) {
//    drawLine(lastPrice + 100, curPrice + 100, canvas, lastX, curX, ChartColors.kLineColor);
    mLinePath ??= Path();

//    if (lastX == curX) {
//      mLinePath.moveTo(lastX, getY(lastPrice));
//    } else {
////      mLinePath.lineTo(curX, getY(curPrice));
//      mLinePath.cubicTo(
//          (lastX + curX) / 2, getY(lastPrice), (lastX + curX) / 2, getY(curPrice), curX, getY(curPrice));
//    }
    if (lastX == curX) lastX = 0; //起点位置填充
    mLinePath!.moveTo(lastX, getY(lastPrice));
    mLinePath!.cubicTo((lastX + curX) / 2, getY(lastPrice), (lastX + curX) / 2,
        getY(curPrice), curX, getY(curPrice));

    //画阴影
    mLineFillShader ??= LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      tileMode: TileMode.clamp,
      colors: [chartColors.lineFillColor, chartColors.lineFillInsideColor],
    ).createShader(Rect.fromLTRB(
        chartRect.left, chartRect.top, chartRect.right, chartRect.bottom));
    mLineFillPaint.shader = mLineFillShader;

    mLineFillPath ??= Path();

    mLineFillPath!.moveTo(lastX, chartRect.height + chartRect.top);
    mLineFillPath!.lineTo(lastX, getY(lastPrice));
    mLineFillPath!.cubicTo((lastX + curX) / 2, getY(lastPrice),
        (lastX + curX) / 2, getY(curPrice), curX, getY(curPrice));
    mLineFillPath!.lineTo(curX, chartRect.height + chartRect.top);
    mLineFillPath!.close();

    canvas.drawPath(mLineFillPath!, mLineFillPaint);
    mLineFillPath!.reset();

    canvas.drawPath(mLinePath!, mLinePaint..strokeWidth = mLineStrokeWidth);
    mLinePath!.reset();
  }

  void drawMaLine(CandleEntity lastPoint, CandleEntity curPoint, Canvas canvas,
      double lastX, double curX) {
    final lineWidth = _indicatorWidth;
    for (int i = 0; i < (curPoint.maValueList?.length ?? 0); i++) {
      if (i == 3) {
        break;
      }
      if (lastPoint.maValueList?[i] != 0) {
        drawLine(lastPoint.maValueList?[i], curPoint.maValueList?[i], canvas,
            lastX, curX, chartColors.getMAColor(i),
            lineWidth: lineWidth);
      }
    }
  }

  void drawBollLine(CandleEntity lastPoint, CandleEntity curPoint,
      Canvas canvas, double lastX, double curX) {
    final lineWidth = _indicatorWidth;
    if (lastPoint.up != 0) {
      drawLine(
          lastPoint.up, curPoint.up, canvas, lastX, curX, chartColors.ma10Color,
          lineWidth: lineWidth);
    }
    if (lastPoint.mb != 0) {
      drawLine(
          lastPoint.mb, curPoint.mb, canvas, lastX, curX, chartColors.ma5Color,
          lineWidth: lineWidth);
    }
    if (lastPoint.dn != 0) {
      drawLine(
          lastPoint.dn, curPoint.dn, canvas, lastX, curX, chartColors.ma30Color,
          lineWidth: lineWidth);
    }
  }

  /// SAR markers are circular in screen space, independent of candle zoom.
  @override
  void drawCircle(Canvas canvas, double curX, double curY, Color color,
      {double? radius, double? strokeWidth}) {
    canvas.save();
    canvas.scale(1 / scaleX, 1);
    super.drawCircle(canvas, curX * scaleX, curY, color,
        radius: radius, strokeWidth: strokeWidth);
    canvas.restore();
  }

  /// 绘制 SAR（抛物线转向指标）
  /// 用圆点表示 SAR 值，颜色根据趋势方向决定
  void drawSAR(CandleEntity lastPoint, CandleEntity curPoint, Canvas canvas,
      double lastX, double curX) {
    final sar = curPoint.sar;
    if (sar == null) return;

    // 计算当前 K 线的中间价位
    final halfHL = (curPoint.high + curPoint.low) / 2;
    late final Color color;

    // 根据 SAR 与中间价的关系决定颜色
    if (sar == halfHL) {
      color = chartColors.avgColor; // 相等：中性色
    } else if (sar < halfHL) {
      color = chartColors.upColor; // SAR 在下方：看涨（绿色/红色）
    } else {
      color = chartColors.dnColor; // SAR 在上方：看跌（红色/绿色）
    }

    // 使用动态宽度绘制 SAR 圆点
    final lineWidth = _indicatorWidth;
    final radius = lineWidth.clamp(1.5, 3.0); // 圆点半径基于线宽
    drawCircle(canvas, curX, sar, color,
        radius: radius, strokeWidth: lineWidth * 0.5);
  }

  /// 计算主图技术指标的动态线宽
  /// 根据缩放级别动态调整线条粗细，保持视觉一致性
  ///
  /// 算法：
  /// 1. 基础宽度除以 scaleX，补偿缩放效果
  /// 2. 最大宽度不超过 min(固定上限, K 线实体宽度)
  ///
  /// 返回值：应该使用的线条宽度
  double _calculateMainIndicatorWidth() {
    if (!chartStyle.enableDynamicMainIndicatorWidth) {
      return chartStyle.mainIndicatorBaseWidth;
    }

    // 基础宽度 / scaleX，补偿缩放
    final baseWidth = chartStyle.mainIndicatorBaseWidth / scaleX;

    // 最大宽度 = min(固定上限, K 线实体宽度)
    final maxWidth = chartStyle.mainIndicatorMaxWidth < mCandleWidth
        ? chartStyle.mainIndicatorMaxWidth
        : mCandleWidth;

    // 限制最大宽度，最小宽度使用较小的值保证细线效果
    return baseWidth > maxWidth ? maxWidth : baseWidth;
  }

  /// 绘制单根蜡烛图
  /// 这是 K 线图的核心绘制逻辑
  /// [curPoint] 当前 K 线数据
  /// [canvas] 画布
  /// [curX] 当前 K 线的 X 坐标（中心点）
  void drawCandle(CandleEntity curPoint, Canvas canvas, double curX) {
    // 将价格转换为屏幕 Y 坐标
    var high = getY(curPoint.high); // 最高价对应的 Y 坐标
    var low = getY(curPoint.low); // 最低价对应的 Y 坐标
    var open = getY(curPoint.open); // 开盘价对应的 Y 坐标
    var close = getY(curPoint.close); // 收盘价对应的 Y 坐标

    double r = mCandleWidth / 2; // 实体半宽

    // ===== 动态影线宽度计算 =====
    // 根据缩放级别平滑调整影线宽度，缩放越小影线越粗
    double lineR = _shadowWidth / 2; // 影线半宽

    // ===== 阳线（涨）：开盘价 >= 收盘价 =====
    if (open >= close) {
      // 确保实体有最小可见高度（避免十字星看不见）
      if (open - close < mCandleLineWidth) {
        open = close + mCandleLineWidth;
      }

      _drawCandleBody(
        canvas,
        body: Rect.fromLTRB(curX - r, close, curX + r, open),
        shadow: Rect.fromLTRB(curX - lineR, high, curX + lineR, low),
        color: chartColors.upColor,
        bodyStyle: chartStyle.riseCandleBodyStyle,
      );
    }
    // ===== 阴线（跌）：收盘价 > 开盘价 =====
    else if (close > open) {
      // 确保实体有最小可见高度
      if (close - open < mCandleLineWidth) {
        open = close - mCandleLineWidth;
      }

      _drawCandleBody(
        canvas,
        body: Rect.fromLTRB(curX - r, open, curX + r, close),
        shadow: Rect.fromLTRB(curX - lineR, high, curX + lineR, low),
        color: chartColors.dnColor,
        bodyStyle: chartStyle.fallCandleBodyStyle,
      );
    }
  }

  void _drawCandleBody(
    Canvas canvas, {
    required Rect body,
    required Rect shadow,
    required Color color,
    required CandleBodyStyle bodyStyle,
  }) {
    chartPaint
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeWidth = mCandleLineWidth;

    if (bodyStyle == CandleBodyStyle.filled) {
      canvas.drawRect(body, chartPaint);
      canvas.drawRect(shadow, chartPaint);
      return;
    }

    canvas.drawRect(shadow, chartPaint);
    canvas.drawRect(
      body,
      chartPaint
        ..style = PaintingStyle.stroke
        ..strokeWidth = mCandleLineWidth,
    );
    chartPaint.style = PaintingStyle.fill;
  }

  @override
  void drawVerticalText(canvas, textStyle, int gridRows) {
    drawPriceAxisLabels(canvas, textStyle, priceAxisTargetValues());
  }

  @override
  void drawGrid(Canvas canvas, int gridRows, int gridColumns) {
    for (final y in priceAxisLineYs) {
      if (y < chartRect.top || y > chartRect.bottom) continue;
      canvas.drawLine(Offset(0, y), Offset(chartRect.width, y), gridPaint);
    }
    double columnSpace = chartRect.width / gridColumns;

    for (int i = 0; i <= gridColumns; i++) {
      canvas.drawLine(Offset(columnSpace * i, 0),
          Offset(columnSpace * i, chartRect.bottom), gridPaint);
    }
  }

  @override
  double getY(double y) {
    return (maxValue - y) * scaleY + _contentRect.top;
  }

  void updateTrendLineData() {
    trendLineMax = maxValue;
    trendLineScale = scaleY;
    trendLineContentRec = _contentRect.top;
  }
}
// ignore_for_file: type_annotate_public_apis
