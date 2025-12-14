import 'package:flutter/material.dart';
import '../entity/candle_entity.dart';
import '../candlestick_widget.dart' show MainState, PriceFormatter;
import 'base_chart_renderer.dart';

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
  /// 蜡烛实体的宽度（像素）
  late double mCandleWidth;

  /// 蜡烛影线的宽度（像素）
  late double mCandleLineWidth;

  /// 要显示的主图指标列表
  List<MainState> stateLi;

  /// 是否为分时图模式（true = 折线图，false = 蜡烛图）
  bool isLine;

  /// 实际绘制的内容区域（去除了上下 padding）
  late Rect _contentRect;

  /// 内容区域的上下内边距（像素）
  double _contentPadding = 5.0;

  /// MA 均线的周期列表（例如 [5, 10, 20]）
  List<int> maDayList;

  /// 图表样式配置
  final ChartStyle chartStyle;

  /// 图表颜色配置
  final ChartColors chartColors;

  /// 分时图折线的宽度
  final double mLineStrokeWidth = 1.0;

  /// 水平缩放倍数
  double scaleX;

  /// 分时图折线的画笔
  late Paint mLinePaint;

  /// 纵轴文字对齐方式
  final VerticalTextAlignment verticalTextAlignment;

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
      PriceFormatter? priceFormatter])
      : super(
            chartRect: mainRect,
            maxValue: maxValue,
            minValue: minValue,
            topPadding: topPadding,
            fixedLength: fixedLength,
            gridColor: chartColors.gridColor,
            priceFormatter: priceFormatter) {
    // 初始化蜡烛图参数
    mCandleWidth = this.chartStyle.candleWidth;
    mCandleLineWidth = this.chartStyle.candleLineWidth;

    // 初始化分时图画笔
    mLinePaint = Paint()
      ..isAntiAlias = true // 开启抗锯齿
      ..style = PaintingStyle.stroke // 描边模式
      ..strokeWidth = mLineStrokeWidth
      ..color = this.chartColors.kLineColor;

    // 计算实际绘制区域（去除上下 padding）
    _contentRect = Rect.fromLTRB(
        chartRect.left,
        chartRect.top + _contentPadding,
        chartRect.right,
        chartRect.bottom - _contentPadding);

    // 处理极端情况：最大值等于最小值时，扩大范围避免除零
    if (maxValue == minValue) {
      maxValue *= 1.5;
      minValue /= 2;
    }

    // 计算 Y 轴缩放比例：像素高度 / 价格范围
    scaleY = _contentRect.height / (maxValue - minValue);
  }
  @override
  void drawText(Canvas canvas, CandleEntity data, double x) {
    if (isLine == true) return;
    for (int i = 0; i < stateLi.length; ++i) {
      TextSpan? span;
      if (stateLi[i] == MainState.MA) {
        span = TextSpan(
          children: _createMATextSpan(data),
        );
      } else if (stateLi[i] == MainState.BOLL) {
        span = TextSpan(
          children: [
            if (data.up != 0)
              TextSpan(
                  text: "BOLL:${format(data.mb)}    ",
                  style: getTextStyle(this.chartColors.ma5Color)),
            if (data.mb != 0)
              TextSpan(
                  text: "UB:${format(data.up)}    ",
                  style: getTextStyle(this.chartColors.ma10Color)),
            if (data.dn != 0)
              TextSpan(
                  text: "LB:${format(data.dn)}    ",
                  style: getTextStyle(this.chartColors.ma30Color)),
          ],
        );
      } else if (stateLi[i] == MainState.SAR) {
        span = TextSpan(
          text: "SAR:${format(data.sar)}",
          style: getTextStyle(this.chartColors.sarColor),
        );
      }
      if (span == null) return;
      TextPainter tp =
          TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();

      Offset offset = Offset(x, chartRect.top - topPadding + i * 12);

      canvas.drawRect(
          Rect.fromLTRB(
            offset.dx - 2,
            offset.dy - 2,
            tp.width + offset.dx + 2,
            tp.height + offset.dy + 2,
          ),
          Paint()..color = this.chartColors.bgColor);

      tp.paint(canvas, offset);
    }
  }

  List<InlineSpan> _createMATextSpan(CandleEntity data) {
    List<InlineSpan> result = [];
    for (int i = 0; i < (data.maValueList?.length ?? 0); i++) {
      if (data.maValueList?[i] != 0) {
        var item = TextSpan(
            text: "MA${maDayList[i]}:${format(data.maValueList![i])}    ",
            style: getTextStyle(this.chartColors.getMAColor(i)));
        result.add(item);
      }
    }
    return result;
  }

  @override
  void drawChart(CandleEntity lastPoint, CandleEntity curPoint, double lastX,
      double curX, Size size, Canvas canvas) {
    if (isLine) {
      drawPolyline(lastPoint.close, curPoint.close, canvas, lastX, curX);
    } else {
      drawCandle(curPoint, canvas, curX);

      /// draw chart main state
      for (int i = 0; i < stateLi.length; ++i) {
        if (stateLi[i] == MainState.MA) {
          drawMaLine(lastPoint, curPoint, canvas, lastX, curX);
        } else if (stateLi[i] == MainState.BOLL) {
          drawBollLine(lastPoint, curPoint, canvas, lastX, curX);
        } else if (stateLi[i] == MainState.SAR) {
          drawSAR(lastPoint, curPoint, canvas, lastX, curX);
        }
      }
    }
  }

  Shader? mLineFillShader;
  Path? mLinePath, mLineFillPath;
  Paint mLineFillPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  //画折线图
  drawPolyline(double lastPrice, double curPrice, Canvas canvas, double lastX,
      double curX) {
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
      colors: [
        this.chartColors.lineFillColor,
        this.chartColors.lineFillInsideColor
      ],
    ).createShader(Rect.fromLTRB(
        chartRect.left, chartRect.top, chartRect.right, chartRect.bottom));
    mLineFillPaint..shader = mLineFillShader;

    mLineFillPath ??= Path();

    mLineFillPath!.moveTo(lastX, chartRect.height + chartRect.top);
    mLineFillPath!.lineTo(lastX, getY(lastPrice));
    mLineFillPath!.cubicTo((lastX + curX) / 2, getY(lastPrice),
        (lastX + curX) / 2, getY(curPrice), curX, getY(curPrice));
    mLineFillPath!.lineTo(curX, chartRect.height + chartRect.top);
    mLineFillPath!.close();

    canvas.drawPath(mLineFillPath!, mLineFillPaint);
    mLineFillPath!.reset();

    canvas.drawPath(mLinePath!,
        mLinePaint..strokeWidth = (mLineStrokeWidth / scaleX).clamp(0.1, 1.0));
    mLinePath!.reset();
  }

  void drawMaLine(CandleEntity lastPoint, CandleEntity curPoint, Canvas canvas,
      double lastX, double curX) {
    for (int i = 0; i < (curPoint.maValueList?.length ?? 0); i++) {
      if (i == 3) {
        break;
      }
      if (lastPoint.maValueList?[i] != 0) {
        drawLine(lastPoint.maValueList?[i], curPoint.maValueList?[i], canvas,
            lastX, curX, this.chartColors.getMAColor(i));
      }
    }
  }

  void drawBollLine(CandleEntity lastPoint, CandleEntity curPoint,
      Canvas canvas, double lastX, double curX) {
    if (lastPoint.up != 0) {
      drawLine(lastPoint.up, curPoint.up, canvas, lastX, curX,
          this.chartColors.ma10Color);
    }
    if (lastPoint.mb != 0) {
      drawLine(lastPoint.mb, curPoint.mb, canvas, lastX, curX,
          this.chartColors.ma5Color);
    }
    if (lastPoint.dn != 0) {
      drawLine(lastPoint.dn, curPoint.dn, canvas, lastX, curX,
          this.chartColors.ma30Color);
    }
  }

  /// 绘制 SAR（抛物线转向指标）
  /// 用圆点表示 SAR 值，颜色根据趋势方向决定
  void drawSAR(CandleEntity lastPoint, CandleEntity curPoint, Canvas canvas,
      double lastX, double curX) {
    final sar = curPoint.sar;
    if (sar == null) return;

    // 计算当前 K 线的中间价位
    final halfHL = (curPoint.high + curPoint.low) / 2;
    late final color;

    // 根据 SAR 与中间价的关系决定颜色
    if (sar == halfHL) {
      color = this.chartColors.avgColor; // 相等：中性色
    } else if (sar < halfHL) {
      color = this.chartColors.upColor; // SAR 在下方：看涨（绿色/红色）
    } else {
      color = this.chartColors.dnColor; // SAR 在上方：看跌（红色/绿色）
    }

    drawCircle(canvas, curX, sar, color);
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
    double lineR = mCandleLineWidth / 2; // 影线半宽

    // ===== 阳线（涨）：开盘价 >= 收盘价 =====
    if (open >= close) {
      // 确保实体有最小可见高度（避免十字星看不见）
      if (open - close < mCandleLineWidth) {
        open = close + mCandleLineWidth;
      }

      chartPaint.color = this.chartColors.upColor;

      // 绘制实体矩形（从收盘价到开盘价）
      canvas.drawRect(
          Rect.fromLTRB(curX - r, close, curX + r, open), chartPaint);

      // 绘制上下影线（从最高价到最低价）
      canvas.drawRect(
          Rect.fromLTRB(curX - lineR, high, curX + lineR, low), chartPaint);
    }
    // ===== 阴线（跌）：收盘价 > 开盘价 =====
    else if (close > open) {
      // 确保实体有最小可见高度
      if (close - open < mCandleLineWidth) {
        open = close - mCandleLineWidth;
      }

      chartPaint.color = this.chartColors.dnColor;

      // 绘制实体矩形（从开盘价到收盘价）
      canvas.drawRect(
          Rect.fromLTRB(curX - r, open, curX + r, close), chartPaint);

      // 绘制上下影线
      canvas.drawRect(
          Rect.fromLTRB(curX - lineR, high, curX + lineR, low), chartPaint);
    }
  }

  @override
  void drawVerticalText(canvas, textStyle, int gridRows) {
    double rowSpace = chartRect.height / gridRows;
    for (var i = 0; i <= gridRows; ++i) {
      double value = (gridRows - i) * rowSpace / scaleY + minValue;
      TextSpan span = TextSpan(text: "${format(value)}", style: textStyle);
      TextPainter tp =
          TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();

      double offsetX;
      switch (verticalTextAlignment) {
        case VerticalTextAlignment.left:
          offsetX = 0;
          break;
        case VerticalTextAlignment.right:
          offsetX = chartRect.width - tp.width;
          break;
      }

      if (i == 0) {
        tp.paint(canvas, Offset(offsetX, topPadding));
      } else {
        tp.paint(
            canvas, Offset(offsetX, rowSpace * i - tp.height + topPadding));
      }
    }
  }

  @override
  void drawGrid(Canvas canvas, int gridRows, int gridColumns) {
//    final int gridRows = 4, gridColumns = 4;
    double rowSpace = chartRect.height / gridRows;
    for (int i = 0; i <= gridRows; i++) {
      canvas.drawLine(Offset(0, rowSpace * i + topPadding),
          Offset(chartRect.width, rowSpace * i + topPadding), gridPaint);
    }
    double columnSpace = chartRect.width / gridColumns;

    for (int i = 0; i <= columnSpace; i++) {
      canvas.drawLine(Offset(columnSpace * i, 0),
          Offset(columnSpace * i, chartRect.bottom), gridPaint);
    }
  }

  @override
  double getY(double y) {
    //For TrendLine
    updateTrendLineData();
    return (maxValue - y) * scaleY + _contentRect.top;
  }

  void updateTrendLineData() {
    trendLineMax = maxValue;
    trendLineScale = scaleY;
    trendLineContentRec = _contentRect.top;
  }
}
