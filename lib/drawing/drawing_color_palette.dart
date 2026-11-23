import 'package:flutter/material.dart';

/// 画图颜色面板：7 列 × 5 行，每行从深到浅（灰阶、红粉、橙黄、绿青、蓝紫）。
/// 旧版的默认色（0xFF4285F4、Material blue/yellow/red/green/purple、白）都在内，
/// 已有图形仍能显示为选中。
const List<Color> drawingPaletteColors = [
  Color(0xFFFFFFFF), Color(0xFFE0E0E0), Color(0xFFBDBDBD), Color(0xFF9E9E9E),
  Color(0xFF757575), Color(0xFF424242), Color(0xFF000000),
  //
  Color(0xFFB71C1C), Color(0xFFF44336), Color(0xFFFF5252), Color(0xFFE91E63),
  Color(0xFFF06292), Color(0xFFF8BBD0), Color(0xFFFFCDD2),
  //
  Color(0xFFE65100), Color(0xFFFF9800), Color(0xFFFFB74D), Color(0xFFFFC107),
  Color(0xFFFFEB3B), Color(0xFFFFF176), Color(0xFFFFF9C4),
  //
  Color(0xFF1B5E20), Color(0xFF4CAF50), Color(0xFF81C784), Color(0xFFC8E6C9),
  Color(0xFF009688), Color(0xFF4DB6AC), Color(0xFFB2DFDB),
  //
  Color(0xFF0D47A1), Color(0xFF4285F4), Color(0xFF2196F3), Color(0xFF90CAF9),
  Color(0xFF673AB7), Color(0xFF9C27B0), Color(0xFFCE93D8),
];

const int drawingPaletteColumns = 7;

/// 「无」选项的返回值（填充、文本底色可清空）。
const Color drawingPaletteNone = Color(0x00000000);

/// 按 ARGB 比较：持久化后 [MaterialColor] 会变成普通 [Color]，
/// 而两者的 `==` 因运行时类型不同永不相等。
bool sameDrawingColor(Color? a, Color? b) =>
    a == null || b == null ? a == b : a.toARGB32() == b.toARGB32();

/// 网格调色板菜单项：选中后以颜色值关闭所在的弹出路由。
///
/// [alpha] 非空时返回带透明度的颜色（填充色用），格子仍显示不透明色。
/// [noneLabel] 非空时顶部多一个「无」选项，返回 [drawingPaletteNone]。
class DrawingColorPaletteEntry extends PopupMenuEntry<Color> {
  const DrawingColorPaletteEntry(
      {super.key, required this.selected, this.alpha, this.noneLabel});

  final Color? selected;
  final double? alpha;
  final String? noneLabel;

  static const double cellSize = 30, swatchSize = 22, padding = 8;
  static const double noneRowHeight = 36;

  static double get gridWidth => drawingPaletteColumns * cellSize + padding * 2;

  @override
  double get height =>
      (drawingPaletteColors.length / drawingPaletteColumns).ceil() * cellSize +
      padding * 2 +
      (noneLabel == null ? 0 : noneRowHeight);

  @override
  bool represents(Color? value) => false;

  @override
  State<DrawingColorPaletteEntry> createState() => _DrawingColorPaletteState();
}

class _DrawingColorPaletteState extends State<DrawingColorPaletteEntry> {
  static const _accent = Color(0xFF4285F4);

  Color _value(Color color) =>
      widget.alpha == null ? color : color.withValues(alpha: widget.alpha);

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final rows = <Widget>[];
    for (var start = 0;
        start < drawingPaletteColors.length;
        start += drawingPaletteColumns) {
      rows.add(Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = start; i < start + drawingPaletteColumns; i++)
          _swatch(i, onSurface),
      ]));
    }
    final noneLabel = widget.noneLabel;
    return Padding(
      key: const ValueKey('drawing-color-palette'),
      padding: const EdgeInsets.all(DrawingColorPaletteEntry.padding),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (noneLabel != null) _none(noneLabel, onSurface),
            ...rows,
          ]),
    );
  }

  Widget _none(String label, Color onSurface) {
    final checked = widget.selected == null;
    return InkWell(
      key: const ValueKey('drawing-palette-none'),
      onTap: () => Navigator.of(context).pop(drawingPaletteNone),
      child: SizedBox(
        width: drawingPaletteColumns * DrawingColorPaletteEntry.cellSize,
        height: DrawingColorPaletteEntry.noneRowHeight,
        child: Row(children: [
          SizedBox(
              width: DrawingColorPaletteEntry.cellSize,
              child: Center(
                  child: CustomPaint(
                      size: const Size.square(
                          DrawingColorPaletteEntry.swatchSize),
                      painter: _NoneSwatchPainter(onSurface,
                          selected: checked, accent: _accent)))),
          const SizedBox(width: 6),
          Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: onSurface, fontSize: 13))),
        ]),
      ),
    );
  }

  Widget _swatch(int index, Color onSurface) {
    final color = drawingPaletteColors[index];
    final value = _value(color);
    final selected = sameDrawingColor(widget.selected, value);
    return InkWell(
      key: ValueKey('drawing-palette-swatch-$index'),
      customBorder: const CircleBorder(),
      onTap: () => Navigator.of(context).pop(value),
      child: SizedBox.square(
        dimension: DrawingColorPaletteEntry.cellSize,
        child: Center(
          child: Container(
            width: DrawingColorPaletteEntry.swatchSize,
            height: DrawingColorPaletteEntry.swatchSize,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              // 细描边让白色在浅色主题、黑色在深色主题下仍可见；选中加粗为强调色环。
              border: selected
                  ? Border.all(color: _accent, width: 2)
                  : Border.all(color: onSurface.withValues(alpha: .2)),
            ),
            child: selected
                ? Icon(Icons.check,
                    key: const ValueKey('drawing-palette-selected'),
                    size: 14,
                    color: color.computeLuminance() > .5
                        ? Colors.black87
                        : Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}

/// 「无」：描边方块 + 红色斜线。
class _NoneSwatchPainter extends CustomPainter {
  const _NoneSwatchPainter(this.border,
      {required this.selected, required this.accent});
  final Color border, accent;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(1), const Radius.circular(4));
    canvas.drawRRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 2 : 1
          ..color = selected ? accent : border.withValues(alpha: .35));
    canvas.drawLine(
        Offset(4, size.height - 4),
        Offset(size.width - 4, 4),
        Paint()
          ..color = const Color(0xFFF44336)
          ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(_NoneSwatchPainter oldDelegate) =>
      oldDelegate.border != border ||
      oldDelegate.selected != selected ||
      oldDelegate.accent != accent;
}
