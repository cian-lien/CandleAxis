import 'package:flutter/material.dart';

import 'chart_drawing_controller.dart';
import 'drawing_labels.dart';
import 'drawing_models.dart';
import 'drawing_popup.dart';
import 'drawing_tool_icon.dart';

/// The same drawing commands can live in the chart or a host toolbar.
///
/// A category with a single tool selects it immediately. Categories with more
/// tools either report to [onExpandCategory] so the host can show a flat panel
/// beside the rail, or fall back to a popup menu when the host passes nothing.
class DrawingTools extends StatelessWidget {
  const DrawingTools({
    super.key,
    required this.controller,
    required this.labels,
    this.canMeasure = true,
    this.foregroundColor = Colors.white,
    this.activeColor = Colors.blue,
    this.showStatisticsButton = true,
    this.additionalFunctions = const [],
    this.onExpandCategory,
    this.onBack,
    this.itemWidth,
    this.iconSize,
    this.buttonStyle,
    this.scrollAreaBuilder,
  });

  final ChartDrawingController controller;
  final DrawingLabels labels;
  final bool canMeasure, showStatisticsButton;
  final Color foregroundColor, activeColor;
  final List<Widget> additionalFunctions;

  /// 需要二级面板的分类交给宿主展开；为空时退回弹窗菜单。
  final ValueChanged<DrawingToolCategory>? onExpandCategory;

  /// 返回上一级工具栏；为空时保留「退出绘图」按钮。
  final VoidCallback? onBack;

  /// Hosts can opt into fixed, centered cells without changing other toolbars.
  final double? itemWidth;

  /// A uniform size for both painted symbols and Material icons when supplied.
  final double? iconSize;

  /// Overrides [drawingCircleButtonStyle] so hosts can give every rail button
  /// the same tap target as their own toolbar buttons.
  final ButtonStyle? buttonStyle;

  /// Decorates each bounded scroll viewport, for example with host-themed fades.
  /// The pinned back/exit cell stays outside these areas.
  final Widget Function(BuildContext context, Widget child)? scrollAreaBuilder;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller.controlChanges,
        builder: (context, _) => SizedBox(
          width: itemWidth ?? 44,
          child: LayoutBuilder(builder: (context, constraints) {
            final categories = Column(
              key: const ValueKey('drawing-category-area'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (final category in DrawingToolCategory.values)
                  _categoryButton(context, category),
              ],
            );
            final functions = Column(
              key: const ValueKey('drawing-function-area'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _functionButton('snap', Icons.my_location, labels.snap,
                    () => controller.snapping = !controller.snapping,
                    selected: controller.snapping),
                _functionButton(
                    'continuous',
                    Icons.edit_outlined,
                    labels.continuous,
                    () => controller.continuousDrawing =
                        !controller.continuousDrawing,
                    selected: controller.continuousDrawing),
                _functionButton(
                    'erase',
                    Icons.auto_fix_normal_outlined,
                    labels.erase,
                    () => controller.mode == DrawingMode.erase
                        ? controller.browse()
                        : controller.enterEraseMode(),
                    selected: controller.mode == DrawingMode.erase),
                _functionButton(
                    'hide',
                    controller.hidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    controller.hidden ? labels.show : labels.hide,
                    controller.toggleHidden,
                    selected: controller.hidden),
                _cell(
                  DrawingMenuButton<_DrawingCommand>(
                    tooltip: labels.tools,
                    style: buttonStyle,
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.more_horiz,
                        color: foregroundColor, size: iconSize ?? 20),
                    onSelected: (action) => _run(context, action),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                          value: _DrawingCommand.undo,
                          enabled: controller.canUndo,
                          child: Text(labels.undo)),
                      PopupMenuItem(
                          value: _DrawingCommand.redo,
                          enabled: controller.canRedo,
                          child: Text(labels.redo)),
                      PopupMenuItem(
                          value: _DrawingCommand.clear,
                          enabled: controller.completedObjects.isNotEmpty,
                          child: Text(labels.clear)),
                    ],
                  ),
                ),
                if (showStatisticsButton)
                  _functionButton(
                      'statistics',
                      Icons.bar_chart,
                      controller.mode == DrawingMode.statistics
                          ? labels.exitStatistics
                          : labels.statistics,
                      !canMeasure
                          ? null
                          : () => controller.mode == DrawingMode.statistics
                              ? controller.exitStatistics()
                              : controller.enterStatistics(),
                      selected: controller.mode == DrawingMode.statistics),
                ...additionalFunctions,
              ],
            );
            final divider = Divider(
                height: 9,
                indent: 6,
                endIndent: 6,
                color: foregroundColor.withValues(alpha: .2));
            final exit = onBack != null
                ? _functionButton('back', Icons.arrow_back, labels.back, onBack)
                : _functionButton('exit', Icons.exit_to_app, labels.exitDrawing,
                    controller.browse);
            Widget scrollArea(Widget child) {
              final scroll = SingleChildScrollView(child: child);
              return scrollAreaBuilder?.call(context, scroll) ?? scroll;
            }

            // Keep category selection above commands even when either area must scroll.
            if (constraints.hasBoundedHeight) {
              return Column(children: [
                Expanded(
                  child: Column(children: [
                    Flexible(flex: 4, child: scrollArea(categories)),
                    divider,
                    Flexible(
                        flex: showStatisticsButton ? 6 : 5,
                        child: scrollArea(functions)),
                  ]),
                ),
                exit,
              ]);
            }
            return Column(
                mainAxisSize: MainAxisSize.min,
                children: [categories, divider, functions, exit]);
          }),
        ),
      );

  Widget _categoryButton(BuildContext context, DrawingToolCategory category) {
    final selected = controller.tool?.category == category;
    final representative = selected ? controller.tool! : category.tools.first;
    final color = selected ? activeColor : foregroundColor;
    final expand = onExpandCategory;
    // 单工具分类点击即用；多工具分类优先交给宿主展开内联面板。
    if (category.isDirect || expand != null) {
      return _cell(
        IconButton(
          key: ValueKey('drawing-category-${category.name}'),
          tooltip: labels.forCategory(category),
          style: buttonStyle ?? drawingCircleButtonStyle,
          padding: EdgeInsets.zero,
          onPressed: () {
            if (category.isDirect) {
              controller.selectTool(category.tools.first);
            } else {
              expand!(category);
            }
          },
          icon: _sizedIcon(DrawingToolIcon(tool: representative, color: color)),
        ),
      );
    }
    return _cell(
      DrawingMenuButton<DrawingTool>(
        key: ValueKey('drawing-category-${category.name}'),
        tooltip: labels.forCategory(category),
        style: buttonStyle,
        icon: Stack(clipBehavior: Clip.none, children: [
          _sizedIcon(DrawingToolIcon(tool: representative, color: color)),
          Positioned(
              left: -8,
              top: 7,
              child: Icon(Icons.arrow_left, size: 10, color: color)),
        ]),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(maxHeight: 320),
        onSelected: controller.selectTool,
        itemBuilder: (_) => [
          for (final tool in category.tools)
            PopupMenuItem(
                value: tool,
                child: Row(children: [
                  DrawingToolIcon(
                      tool: tool,
                      color: Theme.of(context).colorScheme.onSurface),
                  const SizedBox(width: 12),
                  Expanded(child: Text(labels.forTool(tool))),
                  if (controller.tool == tool)
                    const Icon(Icons.check, size: 18),
                ])),
        ],
      ),
    );
  }

  Widget _functionButton(
          String name, IconData icon, String tooltip, VoidCallback? callback,
          {bool selected = false}) =>
      _cell(
        IconButton(
          key: ValueKey('drawing-function-$name'),
          tooltip: tooltip,
          style: buttonStyle ?? drawingCircleButtonStyle,
          padding: EdgeInsets.zero,
          onPressed: callback,
          icon: _functionIcon(
              name,
              icon,
              callback == null
                  ? foregroundColor.withValues(alpha: .35)
                  : selected
                      ? activeColor
                      : foregroundColor),
        ),
      );

  Widget _cell(Widget child) => SizedBox(
        width: itemWidth,
        height: 36,
        child: itemWidth == null ? child : Center(child: child),
      );

  Widget _sizedIcon(Widget icon) => iconSize == null
      ? icon
      : SizedBox.square(
          dimension: iconSize,
          child: FittedBox(child: icon),
        );

  Widget _functionIcon(String name, IconData icon, Color color) =>
      name == 'snap' || name == 'erase'
          ? _sizedIcon(DrawingUtilityIcon(erase: name == 'erase', color: color))
          : Icon(icon, size: iconSize ?? 20, color: color);

  Future<void> _run(BuildContext context, _DrawingCommand action) async {
    switch (action) {
      case _DrawingCommand.undo:
        controller.undo();
      case _DrawingCommand.redo:
        controller.redo();
      case _DrawingCommand.clear:
        final presenter = DrawingPopupScope.of(context);
        if (presenter != null) {
          final accepted = await presenter.confirm(
            context,
            message: labels.clearConfirmation,
            cancelLabel: labels.cancel,
            confirmLabel: labels.confirm,
          );
          if (context.mounted && accepted == true) controller.clear();
          return;
        }
        final accepted = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(labels.clearConfirmation),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(labels.cancel)),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(labels.confirm)),
            ],
          ),
        );
        if (context.mounted && accepted == true) controller.clear();
    }
  }
}

enum _DrawingCommand { undo, redo, clear }
