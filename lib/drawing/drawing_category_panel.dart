import 'dart:ui';

import 'package:flutter/material.dart';

import 'chart_drawing_controller.dart';
import 'drawing_labels.dart';
import 'drawing_models.dart';
import 'drawing_tool_icon.dart';

/// Flat tool list for one category.
///
/// The host places this panel beside its toolbar rail so the list never opens a
/// modal route: the chart stays visible and interactive next to it.
class DrawingCategoryPanel extends StatelessWidget {
  const DrawingCategoryPanel({
    super.key,
    required this.controller,
    required this.labels,
    required this.category,
    required this.onClose,
    this.foregroundColor = const Color(0xFF1F2329),
    this.activeColor = Colors.blue,
    this.backgroundColor = const Color(0xD9F5F6F7),
  });

  final ChartDrawingController controller;
  final DrawingLabels labels;
  final DrawingToolCategory category;
  final VoidCallback onClose;
  final Color foregroundColor;
  final Color activeColor;

  /// Translucent surface; the chart stays visible through a blur behind it.
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) => ClipRect(
          key: ValueKey('drawing-panel-${category.name}'),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(color: backgroundColor),
              child: SizedBox(
                width: 148,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final tool in category.tools) _item(tool),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _item(DrawingTool tool) {
    final color = controller.tool == tool ? activeColor : foregroundColor;
    return SizedBox(
      height: 38,
      child: TextButton.icon(
        key: ValueKey('drawing-tool-${tool.name}'),
        onPressed: () {
          controller.selectTool(tool);
          onClose();
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          foregroundColor: color,
          shape: const RoundedRectangleBorder(),
        ),
        icon: DrawingToolIcon(tool: tool, color: color),
        label: Text(
          labels.forTool(tool),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }
}
