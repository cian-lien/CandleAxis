import 'dart:math';

import 'package:flutter/material.dart'
    show Canvas, Color, CustomPainter, Rect, Size, TextStyle;

import '../candlestick_widget.dart';
import '../chart_style.dart' show ChartStyle;
import '../entity/k_line_entity.dart';
import '../indicators/indicator_presentation.dart';
import '../utils/date_format_util.dart';
import 'base_dimension.dart';
import 'price_range.dart';

export 'package:flutter/material.dart'
    show Canvas, Color, CustomPainter, Rect, Size, TextStyle;

part 'base_chart_painter_extrema.dart';

class ChartDateLabel {
  const ChartDateLabel({
    required this.index,
    required this.text,
    required this.centerX,
    required this.paintX,
  });

  final int index;
  final String text;
  final double centerX;
  final double paintX;
}

abstract class BaseChartPainter extends CustomPainter {
  BaseChartPainter(
    this.chartStyle, {
    this.datas,
    required this.scaleX,
    required this.scrollX,
    required this.isLongPress,
    required this.selectX,
    required this.xFrontPadding,
    required this.xBackPadding,
    required this.baseDimension,
    this.isOnTap = false,
    this.mainStateLi = const <MainState>{},
    this.volHidden = false,
    this.isTapShowInfoDialog = false,
    this.secondaryStateLi = const <SecondaryState>{},
    this.showDateAxis = true,
    this.isLine = false,
    this.verticalScale = 1.0,
    this.viewportAnimation = 1.0,
    this.priceRangeTransition,
    this.manualPriceRange,
    this.rangeDatas,
    super.repaint,
  }) {
    mItemCount = datas?.length ?? 0;
    mPointWidth = chartStyle.pointWidth;
    mTopPadding = chartStyle.topPadding;
    mBottomPadding = chartStyle.bottomPadding;
    mChildPadding = chartStyle.childPadding;
    mDateRowHeight = chartStyle.dateRowHeight;
    mGridRows = chartStyle.gridRows;
    mGridColumns = chartStyle.gridColumns;
    mDataLen = mItemCount * mPointWidth;
    initFormats();
  }
  static double maxScrollX = 0.0;
  List<KLineEntity>? datas;

  Set<MainState> mainStateLi;

  Set<SecondaryState> secondaryStateLi;

  bool volHidden;
  bool isTapShowInfoDialog;
  bool showDateAxis;
  double scaleX = 1.0, scrollX = 0.0, selectX;
  bool isLongPress = false;
  bool isOnTap;
  bool isLine;
  double verticalScale;

  /// Elapsed transition durations on the shared price-range clock.
  double viewportAnimation;
  final PriceRangeTransition? priceRangeTransition;
  final PriceRange? manualPriceRange;

  /// Final input data used for bounds while candle shapes interpolate.
  final List<KLineEntity>? rangeDatas;
  PriceRange? autoPriceRange;

  late Rect mMainLabelRect;

  late Rect mMainRect;

  /// Clamp the whole price tag to the plot, including its painted border.
  double clampMainPlotY(double rawY, double tagHeight, {double padding = 0}) {
    final halfHeight = tagHeight / 2 + padding;
    if (mMainRect.height <= halfHeight * 2) return mMainRect.center.dy;
    return rawY.clamp(
        mMainRect.top + halfHeight, mMainRect.bottom - halfHeight);
  }

  /// 水印文字的实际绘制区域（主图内部左下角），由 drawBg 每帧更新；
  /// 无水印文字时为 null。
  Rect? mWatermarkRect;

  Rect? mVolRect;

  List<RenderRect> mSecondaryRectList = [];
  late double mDisplayHeight, mWidth;

  double mTopPadding = 20.0, mBottomPadding = 20.0, mChildPadding = 12.0;

  double mDateRowHeight = 20.0;

  /// 主图与日期行之间的固定间距：避免主图底边溢出的绘制内容
  /// （最低价标签、现价胶囊等）压住日期文案。
  static const double dateRowGap = 6;

  int mGridRows = 4, mGridColumns = 4;
  int mStartIndex = 0, mStopIndex = 0;
  double mMainMaxValue = double.minPositive, mMainMinValue = double.maxFinite;
  double mVolMaxValue = double.minPositive, mVolMinValue = double.maxFinite;
  double mTranslateX = double.minPositive;
  int mMainMaxIndex = 0, mMainMinIndex = 0;
  double mMainHighMaxValue = double.minPositive,
      mMainLowMinValue = double.maxFinite;
  int mItemCount = 0;
  double mDataLen = 0.0;
  final ChartStyle chartStyle;
  late double mPointWidth;

  List<String> mFormats = [yyyy, '-', mm, '-', dd, ' ', HH, ':', nn];
  double xFrontPadding;
  double xBackPadding;

  List<ChartDateLabel> dateAxisLabels = const <ChartDateLabel>[];

  final BaseDimension baseDimension;

  void initFormats() {
    if (chartStyle.dateTimeFormat != null) {
      mFormats = chartStyle.dateTimeFormat!;
      return;
    }

    if (mItemCount < 2) {
      mFormats = [yyyy, '-', mm, '-', dd, ' ', HH, ':', nn];
      return;
    }

    int firstTime = datas!.first.time ?? 0;
    int secondTime = datas![1].time ?? 0;
    int time = secondTime - firstTime;
    time ~/= 1000;

    if (time >= 24 * 60 * 60 * 28) {
      mFormats = [yy, '-', mm];
    } else if (time >= 24 * 60 * 60) {
      mFormats = [yy, '-', mm, '-', dd];
    } else if (time >= 60) {
      mFormats = [mm, '-', dd, ' ', HH, ':', nn];
    } else {
      // 亚分钟级（如 1 秒 K 线）：需要显示到秒
      mFormats = [HH, ':', nn, ':', ss];
    }
  }

  /// Prepare shared geometry before either the base or drawing layer paints.
  void prepareChart(Size size) {
    mDisplayHeight = size.height - mTopPadding - mBottomPadding;
    mWidth = size.width;
    initRect(size);
    calculateValue();
    initChartRenderer();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, size.height));
    prepareChart(size);
    canvas.save();
    canvas.scale(1, 1);
    drawBg(canvas, size);
    drawGrid(canvas);
    if (datas != null && datas!.isNotEmpty) {
      drawChart(canvas, size);
      // 买卖点属于成交注记层；均价线和标签始终绘制在其上方。
      drawTradeMarkers(canvas);
      // 右侧价格刻度位于买卖点上方，避免成交徽标遮挡坐标轴。
      drawPriceAxis(canvas);
      drawVerticalText(canvas);
      if (showDateAxis) drawDate(canvas, size);

      drawMaxAndMin(canvas);
      drawAvgPriceLines(canvas);
      drawNowPriceLine(canvas);
      drawAvgPriceLabels(canvas);
      drawNowPriceLabel(canvas);

      if (isLongPress == true || (isTapShowInfoDialog && isOnTap)) {
        drawCrossLineText(canvas, size);
      }
      // 指标数值文案位于最顶层：现价虚线、均价线与标签、十字线价格
      // 标签等都不得遮挡它。
      drawText(canvas, datas!.last, 5);
    }
    canvas.restore();
  }

  void initChartRenderer();

  void drawBg(Canvas canvas, Size size);

  void drawGrid(canvas);

  void drawChart(Canvas canvas, Size size);

  /// 主图右侧价格标签。
  void drawPriceAxis(Canvas canvas);

  /// 量能/副图的纵轴文字。
  void drawVerticalText(canvas);

  void drawDate(Canvas canvas, Size size);

  void drawText(Canvas canvas, KLineEntity data, double x);

  void drawMaxAndMin(Canvas canvas);

  void drawNowPrice(Canvas canvas);

  /// 绘制最新价虚线，不绘制最新价 Tag。
  void drawNowPriceLine(Canvas canvas);

  /// 绘制最新价 Tag，必须晚于所有虚线绘制，避免虚线盖住标签。
  void drawNowPriceLabel(Canvas canvas);

  /// 绘制平均买入/卖出价参考线（token-pnl 口径的均价，可为空）。
  void drawAvgPriceLines(Canvas canvas);

  /// 绘制平均买入/卖出价标签。
  void drawAvgPriceLabels(Canvas canvas);

  /// 绘制叠加在 K 线上的买入/卖出成交点。
  void drawTradeMarkers(Canvas canvas);

  void drawCrossLine(Canvas canvas, Size size);

  void drawCrossLineText(Canvas canvas, Size size);

  void initRect(Size size) {
    double volHeight = baseDimension.mVolumeHeight;
    double secondaryHeight = baseDimension.mSecondaryHeight;

    double mainHeight = mDisplayHeight;
    mainHeight -= volHeight;
    mainHeight -= baseDimension.totalSecondaryHeight;

    if (showDateAxis) {
      mainHeight -= mDateRowHeight;
      mainHeight -= dateRowGap;
    }

    mMainRect = Rect.fromLTRB(0, mTopPadding, mWidth, mTopPadding + mainHeight);

    double dateRowBottom = mMainRect.bottom;
    if (showDateAxis) {
      dateRowBottom += dateRowGap + mDateRowHeight;
    }

    double panelPadding(double height) => chartStyle.secondaryPanelPadding
        .clamp(0.0, max(0.0, (height - mChildPadding) / 2))
        .toDouble();
    if (volHidden != true) {
      final padding = panelPadding(volHeight);
      mVolRect = Rect.fromLTRB(0, dateRowBottom + mChildPadding + padding,
          mWidth, dateRowBottom + volHeight - padding);
    }

    mSecondaryRectList.clear();
    for (int i = 0; i < secondaryStateLi.length; ++i) {
      final padding = panelPadding(secondaryHeight);
      mSecondaryRectList.add(RenderRect(
        Rect.fromLTRB(
            0,
            dateRowBottom +
                volHeight +
                i * secondaryHeight +
                mChildPadding +
                padding,
            mWidth,
            dateRowBottom +
                volHeight +
                i * secondaryHeight +
                secondaryHeight -
                padding),
      ));
    }
  }

  double xToTranslateX(double x) => -mTranslateX + x / scaleX;

  int indexOfTranslateX(double translateX) =>
      _indexOfTranslateX(translateX, 0, mItemCount - 1);

  int _indexOfTranslateX(double translateX, int start, int end) {
    if (end == start || end == -1) {
      return start;
    }

    if (end - start == 1) {
      double startValue = getX(start);
      double endValue = getX(end);
      return (translateX - startValue).abs() < (translateX - endValue).abs()
          ? start
          : end;
    }

    int mid = start + (end - start) ~/ 2;
    double midValue = getX(mid);

    if (translateX < midValue) {
      return _indexOfTranslateX(translateX, start, mid);
    } else if (translateX > midValue) {
      return _indexOfTranslateX(translateX, mid, end);
    } else {
      return mid;
    }
  }

  double getX(int position) => position * mPointWidth + mPointWidth / 2;

  KLineEntity getItem(int position) {
    return datas![position];
  }

  void setTranslateXFromScrollX(double scrollX) =>
      mTranslateX = scrollX + getMinTranslateX();

  double getMinTranslateX() {
    var x =
        -mDataLen + mWidth / scaleX - mPointWidth / 2 - xFrontPadding / scaleX;
    return x >= 0 ? 0.0 : x;
  }

  double getMaxTranslateX() {
    return xBackPadding / scaleX - mPointWidth / 2;
  }

  int calculateSelectedX(double selectX) {
    int mSelectedIndex = indexOfTranslateX(xToTranslateX(selectX));

    if (mSelectedIndex < mStartIndex) {
      mSelectedIndex = mStartIndex;
    }
    if (mSelectedIndex > mStopIndex) {
      mSelectedIndex = mStopIndex;
    }

    return mSelectedIndex;
  }

  double translateXtoX(double translateX) =>
      (translateX + mTranslateX) * scaleX;

  TextStyle getTextStyle(Color color) {
    return TextStyle(fontSize: 10.0, color: color);
  }

  @override
  bool shouldRepaint(BaseChartPainter oldDelegate) {
    // Live viewport changes reuse this delegate and arrive through repaint.
    // A replacement delegate represents a widget/configuration change: repaint
    // conservatively, including mutable styles and in-place data updates.
    return !identical(this, oldDelegate);
  }
}

class RenderRect {
  RenderRect(this.mRect);
  Rect mRect;
  double mMaxValue = double.minPositive, mMinValue = double.maxFinite;
}
// ignore_for_file: strict_top_level_inference, type_annotate_public_apis
