import 'package:flutter/material.dart';

import '../../../../themes/colors.dart';

/// 竖屏全屏 K 线页（Bitget 式 ↕）：借用行情 Cubit，全程保持竖屏，
/// 不改动 [DeviceOrientation] / SystemChrome。经 FullscreenCandlestickRoute
/// 推入，过渡与横屏全屏共用。
class PortraitFullscreenCandlestickPage extends StatelessWidget {
  const PortraitFullscreenCandlestickPage({super.key, required this.child});

  final Widget child;

  static Future<void> close(BuildContext context) =>
      Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('portrait-fullscreen-candlestick-page'),
    // 文本画图弹层自行避让键盘，底层图表和工具栏保持原尺寸。
    resizeToAvoidBottomInset: false,
    // 不透明底色，过渡期间详情页的盘口 / 交易按钮不会透出。
    backgroundColor: AppColors.background(context),
    body: SafeArea(maintainBottomViewPadding: true, child: child),
  );
}
