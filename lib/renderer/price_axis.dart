import 'dart:math' as math;
import 'dart:ui' show Rect;

/// Price-axis density and nice-price tick calculations (independent of paint).
class PriceAxisLayout {
  const PriceAxisLayout._();

  /// 相邻两个标签之间的最小留白（像素）。
  static const double defaultMinGap = 6;

  /// 在 [plotHeight] 内最多能放下的互不重叠标签数，不超过 [maxCount]。
  static int resolveCount({
    required double plotHeight,
    required double labelHeight,
    required int maxCount,
    double minGap = defaultMinGap,
  }) {
    if (maxCount <= 0 || labelHeight <= 0 || plotHeight < labelHeight) {
      return 0;
    }
    final fit =
        1 + ((plotHeight - labelHeight) / (labelHeight + minGap)).floor();
    return math.min(maxCount, fit);
  }

  /// Prices on a 1/2/2.5/5 × power-of-ten lattice. Recomputed from the
  /// displayed range; common prices retain their identity as the scale moves.
  static List<double> tickValues({
    required double min,
    required double max,
    required double span,
    required int count,
  }) {
    if (count < 2 || span <= 0 || !span.isFinite) return const [];
    final raw = span / (count - 1);
    if (raw <= 0 || !raw.isFinite) return const [];
    final magnitude =
        math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    if (magnitude <= 0 || !magnitude.isFinite) return const [];
    final normalized = raw / magnitude;
    final unit =
        [1.0, 2.0, 2.5, 5.0, 10.0].firstWhere((v) => v >= normalized - 1e-10);
    final step = unit * magnitude;
    final first = (min / step).ceil();
    final last = (max / step).floor();
    return [for (var i = last; i >= first; i--) i * step];
  }

  /// [count] 条等距刻度线的 Y（自上而下）。
  static List<double> lineYs({
    required double top,
    required double bottom,
    required double labelHeight,
    required int count,
  }) {
    if (count <= 0) return const [];
    final first = top + labelHeight;
    final step = count == 1 ? 0.0 : (bottom - first) / (count - 1);
    return List<double>.generate(count, (i) => first + step * i);
  }
}

/// 一次绘制出的价格标签。
class PriceAxisLabel {
  const PriceAxisLabel({
    required this.text,
    required this.rect,
    required this.value,
    required this.target,
  });

  final String text;

  /// 文字绘制区域（画布坐标）。
  final Rect rect;

  /// 固定刻度价格，与 [target] 相同；动画只改变它的屏幕位置。
  final double value;

  /// 该刻度线此刻真实对应的价格。
  final double target;
}
