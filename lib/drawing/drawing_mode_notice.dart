import 'dart:async';

import 'package:flutter/material.dart';

import 'chart_drawing_controller.dart';
import 'drawing_labels.dart';
import 'drawing_models.dart';

/// 切换模式类工具后的居中短提示，例如「橡皮擦已开启」「进入区间统计模式」。
///
/// 只对比控制器前后状态，不改控制器；提示到时自动消失，不拦截手势。
class DrawingModeNotice extends StatefulWidget {
  const DrawingModeNotice({
    super.key,
    required this.controller,
    required this.labels,
    this.backgroundColor = const Color(0xE6202124),
    this.foregroundColor = Colors.white,
    this.duration = const Duration(milliseconds: 1500),
  });

  final ChartDrawingController controller;
  final DrawingLabels labels;
  final Color backgroundColor, foregroundColor;
  final Duration duration;

  @override
  State<DrawingModeNotice> createState() => _DrawingModeNoticeState();
}

class _DrawingModeNoticeState extends State<DrawingModeNotice> {
  late DrawingMode _mode;
  late bool _snapping, _continuous;
  late int _visibilityToggleSerial;
  String? _message;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _capture(widget.controller);
    widget.controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(DrawingModeNotice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_onChanged);
    _capture(widget.controller);
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _capture(ChartDrawingController controller) {
    _mode = controller.mode;
    _snapping = controller.snapping;
    _continuous = controller.continuousDrawing;
    _visibilityToggleSerial = controller.visibilityToggleSerial;
  }

  void _onChanged() {
    final c = widget.controller, labels = widget.labels;
    final String? message;
    if (c.mode != _mode && c.mode == DrawingMode.erase) {
      message = labels.eraseNotice;
    } else if (c.mode != _mode && _mode == DrawingMode.erase) {
      message = labels.eraseOffNotice;
    } else if (c.mode != _mode && c.mode == DrawingMode.statistics) {
      message = labels.statisticsNotice;
    } else if (c.snapping != _snapping) {
      message = c.snapping ? labels.snapOnNotice : labels.snapOffNotice;
    } else if (c.continuousDrawing != _continuous) {
      message = c.continuousDrawing
          ? labels.continuousOnNotice
          : labels.continuousOffNotice;
    } else if (c.visibilityToggleSerial != _visibilityToggleSerial) {
      message = c.hidden ? labels.hiddenNotice : labels.shownNotice;
    } else {
      message = null;
    }
    _capture(c);
    if (message == null) return;
    _timer?.cancel();
    _timer = Timer(widget.duration, () {
      if (mounted) setState(() => _message = null);
    });
    setState(() => _message = message);
  }

  @override
  Widget build(BuildContext context) {
    final message = _message;
    if (message == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: DecoratedBox(
        key: const ValueKey('drawing-mode-notice'),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            message,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: widget.foregroundColor, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
