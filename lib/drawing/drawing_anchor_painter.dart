import 'package:flutter/material.dart';

/// 所有画线工具共用 Binance mobile 风格的实心中心与半透明光晕锚点，颜色跟随画线。
/// 拖拽或绘制中略微放大；触摸命中范围独立于视觉尺寸。
class DrawingAnchorPainter {
  const DrawingAnchorPainter._();

  /// 普通锚点半径（逻辑像素）。
  static const double dotRadius = 3.5;

  /// 正在拖拽或绘制中跟手的锚点半径。
  static const double activeDotRadius = 4.5;

  /// 选中画线锚点的命中半径，大于线段命中容差，手指更容易抓住锚点。
  static const double hitRadius = 22;

  static void paint(Canvas canvas, Offset center,
      {required Color color, bool active = false}) {
    final radius = active ? activeDotRadius : dotRadius;
    canvas.drawCircle(
        center, radius * 2, Paint()..color = color.withValues(alpha: .2));
    // 画线本身可半透明，但控制点中心保持不透明以便定位。
    canvas.drawCircle(
        center, radius, Paint()..color = color.withValues(alpha: 1));
  }
}
