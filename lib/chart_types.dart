import 'dart:ui' as ui;

import 'utils/date_format_util.dart';

// ignore_for_file: constant_identifier_names

typedef PriceFormatter = String Function(double price);

/// 预录制的矢量水印（如宿主用 flutter_svg 解析出的 logo）。
/// [size] 为 [picture] 的原始尺寸；绘制时按 [height] 等比缩放并用水印色
/// srcIn 着色。[picture] 由宿主持有并负责 dispose，图表只绘制。
class ChartWatermarkPicture {
  const ChartWatermarkPicture({
    required this.picture,
    required this.size,
    this.height = 18,
  });

  final ui.Picture picture;
  final ui.Size size;
  final double height;
}

/// Overrides for buy/sell rows only; other popup values and history keep their format.
class PopupValueFormatters {
  const PopupValueFormatters({this.marketCap, this.usd});

  final PriceFormatter? marketCap;
  final PriceFormatter? usd;
}

class ViewportSnapshot {
  const ViewportSnapshot({
    required this.dataLength,
    required this.scrollX,
    required this.scaleX,
  });

  final int dataLength;

  final double scrollX;

  final double scaleX;
}

enum MainState { MA, EMA, BOLL, SAR, AVL, RESIST, SUPER, VWAP, ICHI }

enum SecondaryState {
  MACD,
  KDJ,
  RSI,
  ROC,
  CCI,
  WR,
  OBV,
  StochRSI,
  MFI,
  DMI,
  DMA,
  MTM,
  EMV
}

enum NowPriceAlignment { left, right, auto }

enum CrossPriceAlignment { left, right, auto }

/// K 线图显示的数据维度
enum ChartValueType { price, marketCap }

/// 图表手势状态，用于与父级滚动视图协调
enum ChartGestureState {
  /// 空闲状态，允许父级滚动
  idle,

  /// 指针已落下但方向尚未确定，父级水平分页应等待图表判定
  pending,

  /// 正在缩放（双指），应阻止父级滚动
  scaling,

  /// 正在水平拖动（单指水平），应阻止父级滚动
  horizontalDragging,

  /// 正在垂直拖动（单指垂直），允许父级滚动
  verticalDragging,
}

/// 手势状态变化回调
typedef ChartGestureStateCallback = void Function(ChartGestureState state);

class TimeFormat {
  static const List<String> YEAR_MONTH_DAY = [yyyy, '-', mm, '-', dd];

  static const List<String> YEAR_MONTH_DAY_WITH_HOUR = [
    yyyy,
    '-',
    mm,
    '-',
    dd,
    ' ',
    HH,
    ':',
    nn
  ];

  static const List<String> YEAR_MONTH_DAY_WITH_SECOND = [
    yyyy,
    '-',
    mm,
    '-',
    dd,
    ' ',
    HH,
    ':',
    nn,
    ':',
    ss
  ];
}
