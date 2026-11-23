part of 'drawing_overlay.dart';

extension _DrawingEditingControls on _DrawingOverlayState {
  Widget _editingToolbar() {
    final object = c.selectedObject;
    final tool = object?.tool ?? c.tool!;
    final style = c.currentStyle;
    final locked = object?.locked ?? false;
    return _surface(Row(
        key: const ValueKey('drawing-editing-toolbar'),
        mainAxisSize: MainAxisSize.min,
        children: [
          RawGestureDetector(
            gestures: {
              EagerGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                      EagerGestureRecognizer.new, (_) {}),
            },
            child: Listener(
                key: const ValueKey('drawing-toolbar-drag-handle'),
                behavior: HitTestBehavior.opaque,
                // 独立处理原始指针位移，避免输给图表或工具栏滚动手势。
                onPointerDown: (event) => _toolbarPointer ??= event.pointer,
                onPointerMove: (event) {
                  if (_toolbarPointer == event.pointer) {
                    _moveToolbar(event.delta);
                  }
                },
                onPointerUp: (event) => _releaseToolbarPointer(event.pointer),
                onPointerCancel: (event) =>
                    _releaseToolbarPointer(event.pointer),
                child: SizedBox(
                    width: 48,
                    height: 44,
                    child: Tooltip(
                        message: labels.drag,
                        child: const Icon(Icons.drag_indicator,
                            color: Colors.grey, size: 18)))),
          ),
          Flexible(
              child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _colors(style, fill: false, enabled: !locked),
                    if (tool.supportsFill)
                      _colors(style, fill: true, enabled: !locked),
                    if (tool == DrawingTool.text)
                      _textBackground(style, enabled: !locked),
                    if (tool == DrawingTool.text)
                      ..._textControls(style, enabled: !locked)
                    else ...[
                      DrawingMenuButton<double>(
                          tooltip: labels.width,
                          enabled: !locked,
                          icon: _dimmed(
                              const Icon(Icons.line_weight,
                                  size: 18, color: Colors.white),
                              enabled: !locked),
                          onSelected: (width) =>
                              c.updateStyle(style.copyWith(width: width)),
                          itemBuilder: (_) => [
                                for (final width in [1.0, 1.5, 2.0, 3.0, 4.0])
                                  PopupMenuItem(
                                      value: width,
                                      child: Row(children: [
                                        Icon(
                                            width == style.width
                                                ? Icons.check
                                                : Icons.remove,
                                            size: 16),
                                        const SizedBox(width: 8),
                                        Container(
                                            width: 70,
                                            height: width,
                                            color: Colors.grey)
                                      ]))
                              ]),
                      DrawingMenuButton<DrawingLineStyle>(
                          tooltip: labels.lineStyle,
                          enabled: !locked,
                          icon: _dimmed(
                              const Icon(Icons.more_horiz,
                                  size: 18, color: Colors.white),
                              enabled: !locked),
                          onSelected: (line) =>
                              c.updateStyle(style.copyWith(lineStyle: line)),
                          itemBuilder: (_) => [
                                for (final line in DrawingLineStyle.values)
                                  CheckedPopupMenuItem(
                                      value: line,
                                      checked: line == style.lineStyle,
                                      child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(labels.lineNames[line] ??
                                                line.name),
                                            const SizedBox(width: 12),
                                            CustomPaint(
                                                size: const Size(70, 18),
                                                painter:
                                                    _DrawingLineStyleSample(
                                                        line,
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .onSurface))
                                          ]))
                              ]),
                    ],
                    if (tool.supportsExtend)
                      _button(
                          Icons.unfold_more,
                          labels.extend,
                          locked
                              ? null
                              : () => c.updateStyle(
                                  style.copyWith(extend: !style.extend)),
                          selected: style.extend),
                    if (tool == DrawingTool.fibonacci)
                      _button(
                          Icons.swap_vert,
                          labels.reverse,
                          locked
                              ? null
                              : () => c.updateStyle(
                                  style.copyWith(reverse: !style.reverse)),
                          selected: style.reverse),
                    if (tool == DrawingTool.horizontalLine ||
                        tool == DrawingTool.priceLine)
                      _button(
                          Icons.label_outline,
                          labels.showPrice,
                          locked
                              ? null
                              : () => c.updateStyle(
                                  style.copyWith(showPrice: !style.showPrice)),
                          selected: style.showPrice),
                    // 锁定后只保留锁定开关、拖动手柄与关闭可用，其余工具置灰且不可点。
                    if (object != null)
                      _button(
                          locked ? Icons.lock : Icons.lock_open,
                          locked ? labels.unlock : labels.lock,
                          () => c.setLocked(!locked)),
                    if (object != null)
                      _button(Icons.delete_outline, labels.delete,
                          locked ? null : c.deleteSelected),
                    _button(Icons.close, labels.cancel, c.cancelDraft),
                  ]))),
        ]));
  }

  /// 文本工具的编辑项：字号、加粗、斜体（颜色复用线色菜单）。
  List<Widget> _textControls(DrawingStyle style, {required bool enabled}) => [
        DrawingMenuButton<double>(
            key: const ValueKey('drawing-text-font-size'),
            tooltip: labels.fontSize,
            enabled: enabled,
            icon: _dimmed(
                const Icon(Icons.format_size, size: 18, color: Colors.white),
                enabled: enabled),
            onSelected: (size) => c.updateStyle(style.copyWith(fontSize: size)),
            itemBuilder: (_) => [
                  for (final size in _DrawingOverlayState._fontSizes)
                    CheckedPopupMenuItem(
                        value: size,
                        checked: size == style.fontSize,
                        child: Text('${size.toInt()}'))
                ]),
        _button(
            Icons.format_bold,
            labels.bold,
            enabled
                ? () => c.updateStyle(style.copyWith(bold: !style.bold))
                : null,
            selected: style.bold),
        _button(
            Icons.format_italic,
            labels.italic,
            enabled
                ? () => c.updateStyle(style.copyWith(italic: !style.italic))
                : null,
            selected: style.italic),
      ];

  Widget _colors(DrawingStyle style,
      {required bool fill, required bool enabled}) {
    final selected = fill ? style.fillColor : style.color;
    return DrawingMenuButton<Color>(
        key: ValueKey('drawing-${fill ? 'fill' : 'stroke'}-color'),
        tooltip: fill ? labels.fill : labels.color,
        enabled: enabled,
        icon: _dimmed(
            CustomPaint(
                key: ValueKey(
                    'drawing-${fill ? 'fill' : 'stroke'}-color-sample'),
                size: const Size(26, 20),
                painter: _DrawingColorSample(selected)),
            enabled: enabled),
        onSelected: (color) => c.updateStyle(fill
            ? style.copyWith(
                fillColor: color,
                clearFill: sameDrawingColor(color, drawingPaletteNone))
            : style.copyWith(color: color)),
        itemBuilder: (_) => [
              DrawingColorPaletteEntry(
                  selected: selected,
                  alpha: fill ? .18 : null,
                  noneLabel: fill ? labels.noFill : null),
            ]);
  }

  /// 文本底色：与文字色共用调色板，额外提供「无」清除底色。
  Widget _textBackground(DrawingStyle style, {required bool enabled}) {
    final selected = style.textBackground;
    return DrawingMenuButton<Color>(
        key: const ValueKey('drawing-text-background'),
        tooltip: labels.textBackground,
        enabled: enabled,
        icon: _dimmed(
            CustomPaint(
                key: const ValueKey('drawing-text-background-sample'),
                size: const Size(26, 20),
                painter: _DrawingTextBackgroundSample(selected)),
            enabled: enabled),
        onSelected: (color) => c.updateStyle(
            sameDrawingColor(color, drawingPaletteNone)
                ? style.copyWith(clearTextBackground: true)
                : style.copyWith(textBackground: color)),
        itemBuilder: (_) => [
              DrawingColorPaletteEntry(
                  selected: selected, noneLabel: labels.noBackground),
            ]);
  }
}

/// 底色工具图标：圆角底块上压一个「A」，无底色时为描边 + 斜线，
/// 与纯色块的文字色按钮区分开。
class _DrawingTextBackgroundSample extends CustomPainter {
  const _DrawingTextBackgroundSample(this.color);
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    final sample = RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 2, 16, 16), const Radius.circular(4));
    final fill = color?.withValues(alpha: 1);
    if (fill != null) canvas.drawRRect(sample, Paint()..color = fill);
    canvas.drawRRect(
        sample,
        Paint()
          ..color = Colors.white54
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    final glyph = TextPainter(
        text: TextSpan(
            text: 'A',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: fill != null && fill.computeLuminance() > .5
                    ? Colors.black87
                    : Colors.white)),
        textDirection: TextDirection.ltr)
      ..layout();
    glyph.paint(
        canvas, sample.center - Offset(glyph.width / 2, glyph.height / 2));
    if (fill == null) {
      canvas.drawLine(
          const Offset(2, 16),
          const Offset(14, 4),
          Paint()
            ..color = Colors.white70
            ..strokeWidth = 1);
    }
    canvas.drawPath(
        Path()
          ..moveTo(20, 8)
          ..lineTo(26, 8)
          ..lineTo(23, 12)
          ..close(),
        Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_DrawingTextBackgroundSample oldDelegate) =>
      oldDelegate.color != color;
}

class _DrawingColorSample extends CustomPainter {
  const _DrawingColorSample(this.color);
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    final sample = RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 2, 16, 16), const Radius.circular(3));
    // Use an opaque fill sample so translucent fills remain legible on dark UI.
    canvas.drawRRect(
        sample, Paint()..color = color?.withValues(alpha: 1) ?? Colors.white12);
    canvas.drawRRect(
        sample,
        Paint()
          ..color = Colors.white54
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    if (color == null) {
      canvas.drawLine(
          const Offset(3, 15),
          const Offset(13, 5),
          Paint()
            ..color = Colors.white
            ..strokeWidth = 1.5);
    }
    canvas.drawPath(
        Path()
          ..moveTo(20, 8)
          ..lineTo(26, 8)
          ..lineTo(23, 12)
          ..close(),
        Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_DrawingColorSample oldDelegate) =>
      oldDelegate.color != color;
}

class _DrawingLineStyleSample extends CustomPainter {
  const _DrawingLineStyleSample(this.lineStyle, this.color);
  final DrawingLineStyle lineStyle;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    final y = size.height / 2;
    if (lineStyle == DrawingLineStyle.solid) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      return;
    }
    final dash = lineStyle == DrawingLineStyle.dotted ? 1.0 : 6.0;
    for (double x = 0; x < size.width; x += dash + 4) {
      canvas.drawLine(
          Offset(x, y), Offset(math.min(size.width, x + dash), y), paint);
    }
  }

  @override
  bool shouldRepaint(_DrawingLineStyleSample oldDelegate) =>
      oldDelegate.lineStyle != lineStyle || oldDelegate.color != color;
}
