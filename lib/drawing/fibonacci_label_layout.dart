import 'package:flutter/painting.dart';

import 'drawing_geometry.dart';

/// 斐波那契档位标签的放置优先级（按 `DrawingObject.fibonacciRatios` 下标）：
/// 0 与 1.0 两端最重要，其次 0.5、0.618、0.382、0.236、0.786。
const fibonacciLabelPriority = [0, 6, 3, 4, 2, 1, 5];

/// 斐波那契各档位标签的左上角；`null` 表示该档位不画标签。
///
/// - 横向：左侧在色带外右对齐，右侧在锚点右缘外，内侧贴色带左缘内侧；
///   只随图形移动，不贴绘图区左右边缘（越界部分由画布裁剪）。
/// - 纵向：文字底边始终紧贴各自档位线上方，越界部分由画布裁剪。
/// - 碰撞：按 [priority] 依次放置，重叠的低优先级标签不画，不翻到线下方。
/// - 档位线在绘图区上下边缘之外时不画该标签。
List<Offset?> layoutFibonacciLabels({
  required List<Size> labels,
  required List<double> levels,
  required double bandLeft,
  required double anchorRight,
  required FibonacciLabelSide side,
  required Rect plot,
  List<int> priority = fibonacciLabelPriority,
  double gap = 4,
}) {
  final result = List<Offset?>.filled(levels.length, null);
  if (side == FibonacciLabelSide.hidden) return result;
  final order = [
    ...priority.where((i) => i < levels.length),
    for (var i = 0; i < levels.length; i++)
      if (!priority.contains(i)) i,
  ];
  final placed = <Rect>[];
  for (final i in order) {
    final y = levels[i], size = labels[i];
    if (y < plot.top || y > plot.bottom) continue;
    final x = switch (side) {
      FibonacciLabelSide.right => anchorRight + gap,
      FibonacciLabelSide.inside => bandLeft + gap,
      _ => bandLeft - gap - size.width,
    };
    final rect = Offset(x, y - size.height - 1) & size;
    if (rect.bottom <= plot.top) continue;
    if (placed.any(rect.overlaps)) continue;
    placed.add(rect);
    result[i] = rect.topLeft;
  }
  return result;
}
