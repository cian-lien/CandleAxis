import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../effect/top_edge_shine.dart';

/// 可被斜切的面板角。
///
/// Dialog、Sheet 等展示面板共用该枚举，调用方可以通过 [CutCornerPanel.corners]
/// 同时指定多个斜切角。
enum CutCornerPosition { topLeft, topRight, bottomLeft, bottomRight }

/// 为 Dialog、Sheet 等组件提供可配置斜切外观的基础面板。
///
/// [cutSize] 是同时设置水平、垂直切角尺寸的便捷参数；[cutWidth] 与 [cutHeight]
/// 可分别覆盖它，以形成非 45 度的斜切。未传入三者时，沿用现有弹层的
/// `25.w x 21.5.h` 视觉基线。
class CutCornerPanel extends StatelessWidget {
  const CutCornerPanel({
    super.key,
    required this.child,
    this.panelKey,
    this.corners = const {CutCornerPosition.topLeft},
    this.cutSize,
    this.cutWidth,
    this.cutHeight,
    this.backgroundColor,
    this.gradient,
    this.borderSide = BorderSide.none,
    this.elevation = 0,
    this.shadowColor,
    this.clipBehavior = Clip.antiAlias,
    this.topShine = false,
  }) : assert(cutSize == null || cutSize >= 0, 'cutSize 不能小于 0。'),
       assert(cutWidth == null || cutWidth >= 0, 'cutWidth 不能小于 0。'),
       assert(cutHeight == null || cutHeight >= 0, 'cutHeight 不能小于 0。');

  /// 面板内部内容。
  final Widget child;

  /// 赋予内部 [Material] 的 Key，便于测试或定位该面板。
  final Key? panelKey;

  /// 需要斜切的角集合，默认仅斜切左上角。
  final Set<CutCornerPosition> corners;

  /// 水平和垂直方向共用的切角尺寸。
  final double? cutSize;

  /// 切角的水平延伸长度，优先级高于 [cutSize]。
  final double? cutWidth;

  /// 切角的垂直延伸长度，优先级高于 [cutSize]。
  final double? cutHeight;

  /// 面板纯色背景；未设置时使用当前主题的 surface 颜色。
  final Color? backgroundColor;

  /// 面板渐变背景；设置后覆盖 [backgroundColor]。
  final Gradient? gradient;

  /// 面板边框样式。
  final BorderSide borderSide;

  /// 面板阴影高度。
  final double elevation;

  /// 面板阴影颜色；为空时使用 Material 默认阴影色。
  final Color? shadowColor;

  /// 是否将子内容裁剪到斜切形状内。
  final Clip clipBehavior;

  /// 顶部是否绘制流光提示（[TopEdgeShine]）。
  ///
  /// 默认关闭：光晕属于装饰性效果，需要时由调用方显式开启。
  /// 纯视觉叠层，不参与布局：面板尺寸与内容位置不受影响。
  final bool topShine;

  /// 根据斜切角和尺寸生成 Material 使用的形状。
  BeveledRectangleBorder _buildShape() {
    final radius = Radius.elliptical(
      cutWidth ?? cutSize ?? 25.w,
      cutHeight ?? cutSize ?? 21.5.h,
    );

    Radius radiusFor(CutCornerPosition corner) {
      return corners.contains(corner) ? radius : Radius.zero;
    }

    return BeveledRectangleBorder(
      side: borderSide,
      borderRadius: BorderRadius.only(
        topLeft: radiusFor(CutCornerPosition.topLeft),
        topRight: radiusFor(CutCornerPosition.topRight),
        bottomLeft: radiusFor(CutCornerPosition.bottomLeft),
        bottomRight: radiusFor(CutCornerPosition.bottomRight),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shape = _buildShape();
    final panel = Material(
      key: panelKey,
      color: gradient == null
          ? (backgroundColor ?? Theme.of(context).colorScheme.surface)
          : Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: shape,
      clipBehavior: clipBehavior,
      elevation: elevation,
      shadowColor: shadowColor,
      child: gradient == null
          ? child
          : DecoratedBox(
              decoration: BoxDecoration(gradient: gradient),
              child: child,
            ),
    );

    if (!topShine) {
      return panel;
    }

    return Stack(
      // 光晕要画到面板上边缘之外，因此不能裁剪。
      clipBehavior: Clip.none,
      children: [
        panel,
        // 顶部流光：峰值贴住面板上边缘，向屏幕上方溢出；不侵入面板内容。
        const Positioned(
          left: 0,
          right: 0,
          top: -TopEdgeShine.defaultHeight,
          child: TopEdgeShine(),
        ),
      ],
    );
  }
}
