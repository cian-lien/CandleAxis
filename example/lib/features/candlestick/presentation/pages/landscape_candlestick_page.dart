import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../themes/colors.dart';

/// 系统负责转向；窗口到达目标方向后才绘制目标页，避免预旋转与原生动画叠加。
class LandscapeCandlestickPage extends StatefulWidget {
  const LandscapeCandlestickPage({super.key, required this.child});

  final Widget child;

  static const handoffDuration = Duration.zero;

  static Future<void> open(
    BuildContext context, {
    required WidgetBuilder builder,
  }) => Navigator.of(context, rootNavigator: true).push<void>(
    _LandscapeRoute(
      pageBuilder: (context, _, _) =>
          LandscapeCandlestickPage(child: builder(context)),
    ),
  );

  static Future<void> close(BuildContext context) =>
      Navigator.of(context).maybePop();

  @override
  State<LandscapeCandlestickPage> createState() =>
      _LandscapeCandlestickPageState();
}

class _LandscapeRoute extends PageRouteBuilder<void> {
  _LandscapeRoute({required super.pageBuilder})
    : super(
        opaque: false,
        allowSnapshotting: false,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );
}

class _LandscapeCandlestickPageState extends State<LandscapeCandlestickPage>
    with WidgetsBindingObserver {
  bool _closingRequested = false;
  bool _restored = false;
  bool _popRequested = false;
  bool _fallbackRotation = false;
  Timer? _entryTimeout;
  Timer? _exitTimeout;

  bool get _systemRotation =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get _portraitWindow {
    final size = View.of(context).physicalSize;
    return size.height >= size.width;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _enterFullscreen());
  }

  void _enterFullscreen() {
    if (!mounted || _closingRequested || _restored) return;
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
    if (!_systemRotation || _fallbackRotation) return;
    unawaited(
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );
    if (!_portraitWindow) return;
    _entryTimeout ??= Timer(const Duration(seconds: 1), () {
      if (!mounted || _closingRequested || !_portraitWindow) return;
      // 锁定窗口/多窗口拒绝转向时才启用手动旋转，先撤销系统横屏请求。
      unawaited(
        SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]),
      );
      setState(() => _fallbackRotation = true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _enterFullscreen();
  }

  @override
  void didChangeMetrics() {
    if (!_systemRotation || _fallbackRotation) return;
    if (!_portraitWindow) {
      _entryTimeout?.cancel();
      _entryTimeout = null;
    }
    // 在竖屏首帧布局前出栈，不再绘制一帧旋转后的横屏图表或等待淡出。
    if (_closingRequested && _portraitWindow) _pop();
  }

  void _restore() {
    if (_restored) return;
    _restored = true;
    _entryTimeout?.cancel();
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    if (_systemRotation) {
      unawaited(
        SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]),
      );
    }
  }

  void _close() {
    if (_closingRequested) return;
    setState(() => _closingRequested = true);
    _restore();
    if (!_systemRotation || _fallbackRotation || _portraitWindow) {
      _pop();
    } else {
      _exitTimeout = Timer(const Duration(seconds: 1), _pop);
    }
  }

  void _pop() {
    if (!mounted || _popRequested) return;
    _popRequested = true;
    _exitTimeout?.cancel();
    Navigator.of(context).pop();
  }

  EdgeInsets _contentInsets(BuildContext context, {required bool rotated}) {
    final media = MediaQuery.of(context);
    final view = media.viewPadding, padding = media.padding;
    double inset(double a, double b, {required bool longAxis}) =>
        math.max(math.max(a, b), longAxis ? 16 : 12);
    return EdgeInsets.fromLTRB(
      inset(view.left, padding.left, longAxis: !rotated),
      inset(view.top, padding.top, longAxis: rotated),
      inset(view.right, padding.right, longAxis: !rotated),
      inset(view.bottom, padding.bottom, longAxis: rotated),
    );
  }

  @override
  void dispose() {
    _entryTimeout?.cancel();
    _exitTimeout?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    // 导航栈替换等异常离场也必须恢复系统栏。
    _restore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _close();
    },
    child: LayoutBuilder(
      builder: (context, constraints) {
        final rotated = constraints.maxHeight > constraints.maxWidth;
        final native = _systemRotation && !_fallbackRotation;
        final waiting = native && rotated;
        final insets = _contentInsets(context, rotated: rotated);
        final content = Padding(
          padding: waiting
              ? EdgeInsets.fromLTRB(
                  insets.top,
                  insets.right,
                  insets.bottom,
                  insets.left,
                )
              : insets,
          child: native
              ? widget.child
              : RotatedBox(quarterTurns: rotated ? 1 : 0, child: widget.child),
        );
        final size = waiting
            ? Size(constraints.maxHeight, constraints.maxWidth)
            : constraints.biggest;
        return Stack(
          key: const Key('landscape-candlestick-page'),
          fit: StackFit.expand,
          children: [
            // 在目标尺寸下预先构建并布局，但不把横屏内容画进竖屏源画面。
            // 系统转向只切换显隐，复用已准备好的 State 和图表视口。
            Offstage(
              offstage: waiting,
              child: OverflowBox(
                minWidth: size.width,
                maxWidth: size.width,
                minHeight: size.height,
                maxHeight: size.height,
                child: IgnorePointer(
                  ignoring: _closingRequested,
                  child: Scaffold(
                    resizeToAvoidBottomInset: false,
                    backgroundColor: AppColors.background(context),
                    body: content,
                  ),
                ),
              ),
            ),
            if (waiting) const AbsorbPointer(child: SizedBox.expand()),
          ],
        );
      },
    ),
  );
}
