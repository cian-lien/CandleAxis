import 'package:flutter/material.dart';

import 'chart_drawing_controller.dart';
import 'drawing_labels.dart';
import 'drawing_models.dart';

/// 选中画图工具后的说明横幅：工具名 + 已选，下一行是落点步骤与进度。
///
/// 默认由 [DrawingOverlay] 摆在图表顶部居中；宿主也可关闭图内横幅后自行摆放。
class DrawingHintBanner extends StatelessWidget {
  const DrawingHintBanner({
    super.key,
    required this.controller,
    required this.labels,
    this.backgroundColor = const Color(0xF2F3F4F6),
    this.foregroundColor = const Color(0xFF1F2329),
  });

  final ChartDrawingController controller;
  final DrawingLabels labels;
  final Color backgroundColor, foregroundColor;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller.controlChanges,
        builder: (context, _) {
          final tool = controller.tool;
          if (tool == null) return const SizedBox.shrink();
          return IgnorePointer(
            child: DecoratedBox(
              key: const ValueKey('drawing-hint-banner'),
              decoration: BoxDecoration(color: backgroundColor),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${labels.forTool(tool)} ${labels.selected}',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: 15,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _steps(tool),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: foregroundColor, fontSize: 12, height: 1.2),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

  String _steps(DrawingTool tool) {
    if (controller.invalidGeometry) return labels.invalidGeometry;
    // 文本只需点一下放置位置，不套用「点击 N 个锚点完成画线」。
    if (tool == DrawingTool.measure) return labels.freehandHint;
    if (tool == DrawingTool.text) return labels.textHint;
    final expected = tool.anchorCount;
    if (expected == null) return labels.freehandHint;
    final count = controller.draftAnchors.length;
    return '${labels.placePoints(expected)} ($count/$expected)';
  }
}
