import 'package:flutter/material.dart';

import '../../../../themes/colors.dart';

/// 竖屏全屏 K 线（↕）的路由与过渡：先用不透明底色快速盖住详情页（盘口 /
/// Trade 不透出），图表内容再淡入 + 轻微上滑展开；返回时反向。点击即开始，
/// 从不等待数据。横屏会话跟随系统转屏动画，不走本过渡。
class FullscreenCandlestickRoute<T> extends PageRouteBuilder<T> {
  FullscreenCandlestickRoute({required super.pageBuilder, super.settings})
    : super(
        fullscreenDialog: true,
        transitionDuration: FullscreenCandlestickRoute.enterDuration,
        reverseTransitionDuration: FullscreenCandlestickRoute.exitDuration,
        transitionsBuilder: transitions,
      );

  static const Duration enterDuration = Duration(milliseconds: 240);
  static const Duration exitDuration = Duration(milliseconds: 200);

  // 系统动画缩放为 0（Android 无障碍 disableAnimations）时，normal 行为的
  // controller 会把时长压缩到约 5%，过渡看起来像瞬间切换；preserve 保留
  // Bitget 式过渡的可见效果。
  @override
  AnimationController createAnimationController() => AnimationController(
    duration: transitionDuration,
    reverseDuration: reverseTransitionDuration,
    debugLabel: debugLabel,
    vsync: navigator!,
    animationBehavior: AnimationBehavior.preserve,
  );

  static Animation<double> _cover(Animation<double> animation) =>
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0, .4, curve: Curves.easeOut),
        reverseCurve: const Interval(.6, 1, curve: Curves.easeIn),
      );

  /// 内容展开：淡入 + 轻微上滑 + 0.96→1 缩放。
  static Widget _reveal(Animation<double> animation, Widget child) {
    final content = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: content,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(content),
        child: ScaleTransition(
          alignment: Alignment.bottomCenter,
          scale: Tween<double>(begin: 0.96, end: 1).animate(content),
          child: child,
        ),
      ),
    );
  }

  static Widget transitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => Stack(
    fit: StackFit.expand,
    children: [
      FadeTransition(
        opacity: _cover(animation),
        child: ColoredBox(color: AppColors.background(context)),
      ),
      _reveal(animation, child),
    ],
  );
}
