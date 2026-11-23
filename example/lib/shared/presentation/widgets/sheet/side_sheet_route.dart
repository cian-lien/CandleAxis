import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'sheet_presentation.dart';

class SideSheetRoute<T> extends PopupRoute<T> {
  SideSheetRoute({
    required this.builder,
    required this.capturedThemes,
    required Color barrierColor,
    required this.barrierLabel,
    this.barrierDismissible = true,
    this.enableDrag = true,
    this.barrierColorListenable,
    super.settings,
  }) : _barrierColor = barrierColor;

  final WidgetBuilder builder;
  final CapturedThemes capturedThemes;
  final Color _barrierColor;
  final bool enableDrag;
  final ValueListenable<Color?>? barrierColorListenable;

  @override
  final String barrierLabel;

  @override
  final bool barrierDismissible;

  @override
  Color get barrierColor => barrierColorListenable?.value ?? _barrierColor;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 250);

  @override
  void install() {
    super.install();
    barrierColorListenable?.addListener(changedInternalState);
  }

  @override
  void dispose() {
    barrierColorListenable?.removeListener(changedInternalState);
    super.dispose();
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => capturedThemes.wrap(
    LayoutBuilder(
      // 跟随横屏页的 RotatedBox 回退，兼容仍锁定竖屏的窗口。
      builder: (_, viewport) => RotatedBox(
        quarterTurns: viewport.maxHeight > viewport.maxWidth ? 1 : 0,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth * 0.42)
                .clamp(320.0, 480.0)
                .clamp(0.0, constraints.maxWidth);
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(size: constraints.biggest),
              child: SideSheetScope(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SlideTransition(
                    position: animation
                        .drive(CurveTween(curve: Curves.easeOutCubic))
                        .drive(
                          Tween(begin: const Offset(1, 0), end: Offset.zero),
                        ),
                    child: SizedBox(
                      key: const Key('cut-corner-side-sheet'),
                      width: width,
                      height: constraints.maxHeight,
                      child: _SideSheetDragTarget(
                        enabled: enableDrag,
                        child: Builder(builder: builder),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

class _SideSheetDragTarget extends StatefulWidget {
  const _SideSheetDragTarget({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<_SideSheetDragTarget> createState() => _SideSheetDragTargetState();
}

class _SideSheetDragTargetState extends State<_SideSheetDragTarget> {
  final Map<int, Offset> _pointerStarts = {};

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: widget.enabled
        ? (event) {
            if (event.localPosition.dx <= 32) {
              _pointerStarts[event.pointer] = event.position;
            }
          }
        : null,
    onPointerCancel: widget.enabled
        ? (event) => _pointerStarts.remove(event.pointer)
        : null,
    onPointerUp: widget.enabled
        ? (event) {
            final start = _pointerStarts.remove(event.pointer);
            if (start == null) return;
            final delta = event.position - start;
            if (delta.dx > 100 && delta.dx.abs() > delta.dy.abs()) {
              Navigator.of(context).pop();
            }
          }
        : null,
    child: widget.child,
  );
}
