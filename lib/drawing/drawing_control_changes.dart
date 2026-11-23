import 'package:flutter/foundation.dart';

import 'chart_drawing_controller.dart';

/// Cursor coordinates invalidate painters, while controls only react to their
/// own values. In particular, moving an edit preview keeps its toolbar intact.
class DrawingControlChanges extends ChangeNotifier {
  DrawingControlChanges(this.controller) {
    _value = _snapshot();
    controller.addListener(_changed);
  }
  final ChartDrawingController controller;
  late Object _value;

  Object _snapshot() {
    final c = controller, selected = controller.selectedObject;
    final style = c.currentStyle;
    return (
      c.mode,
      c.tool,
      selected?.id,
      selected?.tool,
      selected?.locked,
      c.hidden,
      c.continuousDrawing,
      c.snapping,
      c.canUndo,
      c.canRedo,
      c.invalidGeometry,
      c.completionSerial,
      c.toolSelectionSerial,
      c.tool?.anchorCount == null ? 0 : c.draftAnchors.length,
      (
        style.color,
        style.fillColor,
        style.width,
        style.lineStyle,
        style.extend,
        style.reverse,
        style.showPrice,
        style.fontSize,
        style.bold,
        style.italic,
        style.textBackground
      ),
    );
  }

  void _changed() {
    final next = _snapshot();
    if (next == _value) return;
    _value = next;
    notifyListeners();
  }

  @override
  void dispose() {
    controller.removeListener(_changed);
    super.dispose();
  }
}
