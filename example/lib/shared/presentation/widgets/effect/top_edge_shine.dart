import 'package:flutter/material.dart';

import '../../../../themes/colors.dart';

/// 弹窗顶部的流光光晕。
///
/// 光晕画在弹窗**上边缘之外**（由 [CutCornerPanel] 用 `Clip.none` 的 Stack
/// 定位到面板上方），峰值紧贴边缘、向上衰减到透明：既把弹窗上边界勾出来
/// （深色主题下弹窗底色与遮罩非常接近，不勾边几乎看不出弹窗高度），
/// 又不侵占面板内部内容。
///
/// 另有一条打开时横扫一次的光带制造流光观感，同样被顶部渐隐遮罩限制。
/// 扫光只播放一次而不是无限循环：弹窗相关的业务代码与测试大量使用
/// `pumpAndSettle`，无限循环动画会让它们永远无法 settle。
class TopEdgeShine extends StatefulWidget {
  const TopEdgeShine({
    super.key,
    this.color,
    this.height = defaultHeight,
    this.sweepDuration = const Duration(milliseconds: 1200),
  });

  /// 默认光晕高度：从弹窗边缘向上溢出的范围。
  static const double defaultHeight = 56;

  /// 光晕颜色；为空时取当前主题的 [AppColors.panelTopShine]。
  ///
  /// 颜色自带透明度（青色光晕），两个主题各有一档强度。
  final Color? color;

  /// 光晕高度。
  final double height;

  /// 单次扫光的时长。
  final Duration sweepDuration;

  @override
  State<TopEdgeShine> createState() => _TopEdgeShineState();
}

class _TopEdgeShineState extends State<TopEdgeShine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: widget.sweepDuration,
    vsync: this,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 系统开启"减弱动态效果"时只保留静态高光。
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
      return;
    }

    if (!_controller.isAnimating && !_controller.isCompleted) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 弹窗边缘到上方的渐隐：峰值贴住边缘，向上衰减到透明。
  LinearGradient _edgeGradient(Color shine) => LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [
      shine,
      shine.withValues(alpha: shine.a * 0.35),
      shine.withValues(alpha: 0),
    ],
    stops: const [0, 0.45, 1],
  );

  /// 横向扫过的光带，[progress] 为 0→1 的一次完整扫动。
  LinearGradient _sweepGradient(Color shine, double progress) {
    final center = -0.4 + progress * 1.8;
    const halfWidth = 0.35;
    double clamp01(double value) => value.clamp(0.0, 1.0);

    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        shine.withValues(alpha: 0),
        // 光带比常驻高光稍强，才有"扫过"的观感。
        shine.withValues(alpha: (shine.a * 1.6).clamp(0.0, 1.0)),
        shine.withValues(alpha: 0),
      ],
      stops: [
        clamp01(center - halfWidth),
        clamp01(center),
        clamp01(center + halfWidth),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final shine = widget.color ?? AppColors.panelTopShine(context);
    final edgeGradient = _edgeGradient(shine);

    return IgnorePointer(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 常驻边缘光晕：任何时候都能看清弹窗上边缘。
            DecoratedBox(decoration: BoxDecoration(gradient: edgeGradient)),
            // 扫光：只在顶部渐隐范围内可见。
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: edgeGradient.createShader,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: _sweepGradient(shine, _controller.value),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
