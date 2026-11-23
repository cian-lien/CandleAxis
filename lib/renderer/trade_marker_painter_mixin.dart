import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../chart_style.dart' show ChartColors;
import '../entity/trade_marker_entity.dart';
import 'base_chart_painter.dart';
import 'chart_dash_cache.dart';
import 'chart_text_cache.dart';
import 'trade_marker_index.dart';

part 'trade_marker_painter_mixin_support_1.dart';

part 'trade_marker_painter_mixin_label_drawing.dart';

/// 均价参考线 + 买卖点标记的绘制逻辑。
///
/// 从 [ChartPainter] 拆出为独立 mixin，避免把新增的 K 线买卖点/均价功能
/// 直接堆进已经很大的 `chart_painter.dart`（受仓库文件行数基线约束）。
/// 依赖 [ChartPainter] 已有的字段/方法（[chartColors]、[tradeMarkers] 等），
/// 通过抽象 getter/方法声明解耦。
mixin TradeMarkerPainterMixin on BaseChartPainter {
  ChartColors get chartColors;
  ChartTextCache? get textCache;
  final _markerIndex = TradeMarkerIndex();
  final dashCache = ChartDashCache();
  List<TradeMarkerEntity> get tradeMarkers;
  bool get showTradeMarkers;
  double? get avgBuyPrice;
  double? get avgSellPrice;
  String? get avgBuyLabel;
  String? get avgSellLabel;
  bool get showAvgPriceLines;

  double getMainY(double price);

  /// 买卖点圆角方框徽标的宽高（像素），固定大小、不随缩放变化，保持可读性。
  static const double _pinWidth = 14.0;
  static const double _pinHeight = 12.0;

  /// 徽标圆角半径（像素）。
  static const Radius _pinCornerRadius = Radius.circular(3.0);

  /// 徽标下方箭头（尖角）的高度/半宽（像素），比原先更小更精致。
  static const double _pinTailHeight = 3.0;
  static const double _pinTailHalfWidth = 3.0;

  /// 徽标箭头尖端与蜡烛最高点之间的间距（像素），保持小而明显的留白，
  /// 避免徽标尖角与蜡烛影线贴在一起，同时不会显得离蜡烛太远。
  static const double _pinGap = 4.0;

  /// 均价徽标的内边距（像素）。
  static const double _avgLabelPaddingH = 6.0;
  static const double _avgLabelPaddingV = 4.5;

  /// 均价徽标的圆角半径（像素）。
  static const Radius _avgLabelCornerRadius = Radius.circular(4.0);

  late final Paint _avgBuyPaint = Paint()
    ..strokeWidth = chartStyle.nowPriceLineWidth
    ..isAntiAlias = true
    ..color = chartColors.upColor;
  late final Paint _avgSellPaint = Paint()
    ..strokeWidth = chartStyle.nowPriceLineWidth
    ..isAntiAlias = true
    ..color = chartColors.dnColor;
  late final Paint _buyMarkerPaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.fill
    ..color = chartColors.upColor;
  late final Paint _sellMarkerPaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.fill
    ..color = chartColors.dnColor;

  /// Last painted average-line label rectangles, exposed for widget tests.
  @visibleForTesting
  List<Rect> debugAvgPriceLabelRects = const [];

  @override
  void drawAvgPriceLines(Canvas canvas) {
    if (isLine || !showAvgPriceLines || datas == null || datas!.isEmpty) {
      return;
    }

    canvas.save();
    canvas.clipRect(mMainRect);
    for (final spec in _avgPriceLineSpecs()) {
      _drawAvgPriceDashLine(canvas, spec.y, spec.paint);
    }
    canvas.restore();
  }

  @override
  void drawAvgPriceLabels(Canvas canvas) {
    debugAvgPriceLabelRects = const [];
    if (isLine || !showAvgPriceLines || datas == null || datas!.isEmpty) {
      return;
    }

    final labeledSpecs = _avgPriceLineSpecs()
        .where((spec) => spec.hasLabel)
        .toList(growable: false);
    if (labeledSpecs.isEmpty) return;

    debugAvgPriceLabelRects = [
      for (final spec in labeledSpecs)
        Rect.fromLTWH(0, spec.labelTop, spec.boxWidth, spec.boxHeight),
    ];
    canvas.save();
    canvas.clipRect(mMainRect);
    for (final spec in labeledSpecs) {
      _drawAvgPriceLabel(canvas, spec);
    }
    canvas.restore();
  }

  List<_AvgPriceLineSpec> _avgPriceLineSpecs() {
    final specs = [
      if (_buildAvgPriceLineSpec(avgBuyPrice, avgBuyLabel, _avgBuyPaint)
          case final spec?)
        spec,
      if (_buildAvgPriceLineSpec(avgSellPrice, avgSellLabel, _avgSellPaint)
          case final spec?)
        spec,
    ];
    _layoutPriceLabels(specs.where((spec) => spec.hasLabel).toList());
    return specs;
  }

  _AvgPriceLineSpec? _buildAvgPriceLineSpec(
      double? price, String? label, Paint paint) {
    if (price == null || price <= 0) return null;
    final y = clampMainPlotY(getMainY(price), paint.strokeWidth);

    final labelParts = label == null || label.isEmpty
        ? null
        : _splitAvgLabel(label, paint.color);

    return _AvgPriceLineSpec(y: y, paint: paint, labelParts: labelParts);
  }

  _AvgLabelParts _splitAvgLabel(String label, Color valueColor) {
    final parts = label.split('\n');
    final title = parts.first;
    final value = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    return _AvgLabelParts(
      titlePainter: _avgTextPainter(title, chartColors.tradeOverlayOnColor),
      valuePainter: value.isEmpty ? null : _avgTextPainter(value, valueColor),
    );
  }

  TextPainter _tradeText(String text, TextStyle style) {
    final span = TextSpan(text: text, style: style);
    return textCache?.layout(span) ??
        (TextPainter(text: span, textDirection: TextDirection.ltr)..layout());
  }

  TextPainter _avgTextPainter(String text, Color color) {
    return _tradeText(text, TextStyle(fontSize: 10, height: 1, color: color));
  }

  /// 绘制单条均价参考线虚线，复用 `drawNowPrice` 的虚线绘制风格。
  void _drawAvgPriceDashLine(Canvas canvas, double y, Paint paint) {
    dashCache.draw(canvas, mWidth, y, chartStyle.nowPriceLineLength,
        chartStyle.nowPriceLineSpan, paint);
  }

  void _drawAvgPriceLabel(Canvas canvas, _AvgPriceLineSpec spec) {
    final parts = spec.labelParts;
    if (parts == null) return;
    _drawSplitLabel(canvas, parts, spec.labelTop, spec.paint);
  }

  @override
  void drawTradeMarkers(Canvas canvas) {
    if (isLine ||
        !showTradeMarkers ||
        datas == null ||
        datas!.isEmpty ||
        tradeMarkers.isEmpty) {
      return;
    }

    _markerIndex.update(rangeDatas ?? datas!, tradeMarkers);
    _markerIndex.groups.forEach((index, markers) {
      if (index < mStartIndex || index > mStopIndex) return;
      final x = translateXtoX(getX(index));
      // 同一根蜡烛上，买/卖各自最多只画一个徽标：多笔同方向成交合并成一个
      // B 或一个 S（明细仍通过 tradesAtIndex 完整保留给浮窗展示），避免
      // 出现两个 B 或两个 S 叠在一起。
      final hasBuy = markers.any((m) => m.side == TradeMarkerSide.buy);
      final hasSell = markers.any((m) => m.side == TradeMarkerSide.sell);
      final sellTipY = getMainY(datas![index].high) - _pinGap;
      final buyTipY = getMainY(datas![index].low) + _pinGap;
      // 徽标整体（含尖角）不得越出画布顶部；主图上方保留的 chartStyle.topPadding
      // 是纯留白区域（图例文字画在更靠下、更接近 mMainRect.top 的位置），允许
      // 徽标画进这段留白，避免蜡烛最高点正好是可视区间最高价时（此时
      // mMainRect.top 已经贴着该高点）被强行压回去贴住蜡烛。
      final minTipY = mMainRect.top -
          chartStyle.topPadding +
          _pinTailHeight +
          _pinHeight +
          2.0;
      final maxBuyTipY = mMainRect.bottom -
          chartStyle.bottomPadding -
          _pinTailHeight -
          _pinHeight -
          2.0;
      if (hasSell) {
        _drawMarkerPin(
          canvas,
          x,
          math.max(sellTipY, minTipY),
          isBuy: false,
          paint: _sellMarkerPaint,
          pointsDown: true,
        );
      }
      if (hasBuy) {
        _drawMarkerPin(
          canvas,
          x,
          math.min(buyTipY, maxBuyTipY),
          isBuy: true,
          paint: _buyMarkerPaint,
          pointsDown: false,
        );
      }
    });
  }

  /// 在给定屏幕坐标绘制一个圆角方框 + 小尖角箭头组成的"图钉"徽标：方框置于
  /// 上方承载 "B"/"S" 字母，尖角朝下指向 [tipY]（即目标蜡烛上方）。
  void _drawMarkerPin(
    Canvas canvas,
    double x,
    double tipY, {
    required bool isBuy,
    required Paint paint,
    required bool pointsDown,
  }) {
    final boxTop =
        pointsDown ? tipY - _pinTailHeight - _pinHeight : tipY + _pinTailHeight;
    final boxBottom = boxTop + _pinHeight;
    final tail = pointsDown
        ? (Path()
          ..moveTo(x - _pinTailHalfWidth, boxBottom)
          ..lineTo(x, tipY)
          ..lineTo(x + _pinTailHalfWidth, boxBottom)
          ..close())
        : (Path()
          ..moveTo(x - _pinTailHalfWidth, boxTop)
          ..lineTo(x, tipY)
          ..lineTo(x + _pinTailHalfWidth, boxTop)
          ..close());
    canvas.drawPath(tail, paint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x - _pinWidth / 2, boxTop, _pinWidth, _pinHeight),
            _pinCornerRadius),
        paint);

    final centerY = boxTop + _pinHeight / 2;
    final tp = _tradeText(
        isBuy ? 'B' : 'S',
        const TextStyle(
            fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold));
    // 用字形的 ascent/descent 而非整行盒高（tp.height）来找垂直中心：不同
    // 字体在行盒里预留的额外行距（leading）往往偏向顶部分配，直接用
    // tp.height/2 居中会让字母视觉上偏上；ascent/descent 更贴近字形实际
    // 可见范围，居中效果更准确。
    final metrics = tp.computeLineMetrics();
    final ascent = metrics.isNotEmpty ? metrics.first.ascent : tp.height * 0.8;
    final descent =
        metrics.isNotEmpty ? metrics.first.descent : tp.height * 0.2;
    final dy = centerY - (ascent + descent) / 2;
    tp.paint(canvas, Offset(x - tp.width / 2, dy));
  }

  /// 返回落在给定蜡烛下标区间内的成交点，供长按/点击浮窗展示买卖明细。
  List<TradeMarkerEntity> tradesAtIndex(int index) {
    if (isLine) return const [];
    if (datas == null || index < 0 || index >= datas!.length) {
      return const [];
    }
    if (tradeMarkers.isEmpty) return const [];
    _markerIndex.update(rangeDatas ?? datas!, tradeMarkers);
    return List.of(_markerIndex.groups[index] ?? const []);
  }
}
