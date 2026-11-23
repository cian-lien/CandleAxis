part of 'main_renderer.dart';

/// 主图右侧价格标签：刻度线对应价格的反算与右对齐绘制。
extension MainRendererPriceAxis on MainRenderer {
  /// 各刻度线此刻真实对应的价格（[getY] 的反函数）。
  List<double> priceAxisTargetValues() =>
      priceAxisValues ??
      [
        for (final y in priceAxisLineYs)
          maxValue - (y - _contentRect.top) / scaleY,
      ];

  /// 在各刻度线上方绘制 [values]；标签右边缘固定，数值变化时不会左右抖动。
  List<PriceAxisLabel> drawPriceAxisLabels(
    Canvas canvas,
    TextStyle textStyle,
    List<double> values,
  ) {
    final targets = priceAxisTargetValues();
    final labels = <PriceAxisLabel>[];
    for (var i = 0; i < priceAxisLineYs.length && i < values.length; i++) {
      final value = values[i];
      // 市值模式下将价格值缩放为市值
      final displayValue =
          valueType == ChartValueType.marketCap ? value * mcapFactor : value;
      final text =
          valueType == ChartValueType.marketCap && mcapFormatter != null
              ? mcapFormatter!(displayValue)
              : format(displayValue);
      final tp = layoutText(TextSpan(text: text, style: textStyle));

      final offsetX = switch (verticalTextAlignment) {
        VerticalTextAlignment.left => 0.0,
        VerticalTextAlignment.right => chartRect.width - tp.width - 10.0,
      };
      final offset = Offset(offsetX, priceAxisLineYs[i] - tp.height);
      tp.paint(canvas, offset);
      labels.add(PriceAxisLabel(
        text: text,
        rect: offset & tp.size,
        value: value,
        target: targets[i],
      ));
    }
    return labels;
  }
}
