import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color, Offset, Rect, Size;
import 'drawing_anchor_painter.dart';
import 'drawing_control_changes.dart';
import 'drawing_coordinates.dart';
import 'drawing_geometry.dart';
import 'drawing_models.dart';
import 'drawing_range_layout.dart';
import 'measure_candle_anchors.dart';

part 'drawing_pointer_interaction.dart';

/// Owns transient interaction and completed documents independently. Hosts
/// subscribe to document changes for persistence and dispose their controller.
class ChartDrawingController extends ChangeNotifier {
  ChartDrawingController({this.drawingColor});

  /// Host theme colour for channels and measurements; persisted styles win.
  final Color? drawingColor;
  DrawingControlChanges? _controlChanges;
  Listenable get controlChanges =>
      _controlChanges ??= DrawingControlChanges(this);

  DrawingDocument _document = DrawingDocument();
  final List<DrawingDocument> _undo = [], _redo = [];
  final Set<VoidCallback> _documentListeners = {};
  final Map<DrawingTool, DrawingStyle> _styles = {};
  DrawingMode _mode = DrawingMode.browse;
  DrawingTool? _tool;
  final List<DrawingAnchor> _draft = [];
  DrawingAnchor? _preview;

  /// 文本工具已落点、等待宿主输入框提交的锚点。
  DrawingAnchor? pendingTextAnchor;
  String? _selectedId;
  DrawingObject? _editPreview;
  bool _hidden = false, _continuous = false, _snapping = false;
  int _id = 0;
  int completionSerial = 0;

  /// 每次 [selectTool] 自增，宿主据此区分「新选中工具」与其他状态变化。
  int toolSelectionSerial = 0;

  /// 用户点击显隐开关时自增，区别于宿主同步或自动显示画图。
  int visibilityToggleSerial = 0;
  final Set<int> _pointers = {};
  final Set<int> _ignoredPointers = {};
  bool get pointerBlocksPan =>
      pointerConsumed &&
      (_mode == DrawingMode.draw ||
          _mode == DrawingMode.erase ||
          _mode == DrawingMode.statistics ||
          _pointerHit != null);
  void ignorePointer(int pointer) {
    _ignoredPointers.add(pointer);
    pointerConsumed = true;
  }

  int? _activePointer;
  DrawingRangeTarget? _rangeTarget;
  double _rangeGrabOffset = 0;

  /// 正被按住的区间手柄/关闭按钮，用于高亮。
  DrawingRangeTarget? get activeRangeTarget => _rangeTarget;
  bool _pinching = false;
  bool pointerConsumed = false;
  DrawingCoordinates? _frozenCoordinates;
  DrawingCoordinates? lastCoordinates;
  DrawingHit? _pointerHit;
  DrawingAnchor? _pointerOrigin;
  Size? _textResizeSize;
  List<DrawingAnchor> _originalAnchors = [];
  Object? _displayBasis;
  bool invalidGeometry = false;
  int? rangeStart, rangeEnd;
  void _notify() => notifyListeners();
  DrawingDocument get document => _document;
  List<DrawingObject> get completedObjects => _document.objects;
  List<DrawingObject> get visibleObjects => _hidden
      ? const []
      : [
          for (final object in completedObjects)
            object.id == _editPreview?.id ? _editPreview! : object
        ];
  DrawingMode get mode => _mode;
  DrawingTool? get tool => _tool;
  List<DrawingAnchor> get draftAnchors => List.unmodifiable(_draft);
  DrawingAnchor? get preview => _preview;
  bool get hidden => _hidden;
  bool get editing => _editPreview != null;
  bool get blocksBrowsing => _mode != DrawingMode.browse;
  bool get continuousDrawing => _continuous;
  set continuousDrawing(bool value) {
    _continuous = value;
    notifyListeners();
  }

  bool get snapping => _snapping;
  set snapping(bool value) {
    _snapping = value;
    notifyListeners();
  }

  bool get canUndo => _draft.isNotEmpty || _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  DrawingObject? get selectedObject {
    for (final o in visibleObjects) {
      if (o.id == _selectedId) return o;
    }
    return null;
  }

  DrawingStyle get currentStyle {
    final remembered = selectedObject?.style ?? _styles[_tool];
    if (remembered != null) return remembered;
    if (_tool == DrawingTool.parallelChannel || _tool == DrawingTool.measure) {
      final color = drawingColor ?? const DrawingStyle().color;
      return DrawingStyle(
          color: color, fillColor: color.withValues(alpha: .15));
    }
    return const DrawingStyle();
  }

  DrawingObject? get draftObject => _tool == null
      ? null
      : DrawingObject(
          id: 'draft',
          tool: _tool!,
          anchors: [..._draft, if (_preview != null) _preview!],
          style: currentStyle);

  void addDocumentListener(VoidCallback listener) =>
      _documentListeners.add(listener);
  void removeDocumentListener(VoidCallback listener) =>
      _documentListeners.remove(listener);
  void _publish(DrawingDocument next, {bool record = true}) {
    if (record) {
      _undo.add(_document);
      _redo.clear();
    }
    _document = next;
    for (final callback in List<VoidCallback>.of(_documentListeners)) {
      callback();
    }
    notifyListeners();
  }

  void restore(DrawingDocument document) {
    if (document.version != 1 ||
        document.objects.any((o) => !o.isValid) ||
        document.objects.map((o) => o.id).toSet().length !=
            document.objects.length) {
      throw ArgumentError('Invalid drawing document');
    }
    _undo.clear();
    _redo.clear();
    _document = document;
    cancelDraft();
  }

  void selectTool(DrawingTool tool) {
    cancelPointer();
    _draft.clear();
    _selectedId = null;
    _tool = tool;
    // 编辑已有图形的样式会被记作该工具的下次默认样式；「延伸」不能这样
    // 沿用，否则开过一次延伸后新画的斐波那契都会拉到绘图区右缘。
    // 延伸只在本次选中工具期间（含连续绘制）有效。
    final remembered = _styles[tool];
    if (remembered != null && remembered.extend) {
      _styles[tool] = remembered.copyWith(extend: false);
    }
    _mode = DrawingMode.draw;
    invalidGeometry = false;
    toolSelectionSerial++;
    notifyListeners();
  }

  void previewAnchor(DrawingAnchor anchor) {
    if (_mode != DrawingMode.draw || !anchor.isValid) return;
    if (_tool?.isFreehand == true) {
      // 画笔按轨迹累积；与上一点完全重合的采样直接丢弃。
      final last = _draft.isEmpty ? null : _draft.last;
      if (last != null && last == anchor) return;
      _draft.add(anchor);
      invalidGeometry = false;
      notifyListeners();
      return;
    }
    _preview = anchor;
    invalidGeometry = false;
    notifyListeners();
  }

  void enterEraseMode() {
    cancelDraft();
    _mode = DrawingMode.erase;
    notifyListeners();
  }

  void eraseAt(Offset point, DrawingCoordinates coordinates) {
    if (_mode != DrawingMode.erase) return;
    final hit = hitTest(point, coordinates);
    if (hit == null) return;
    final object = completedObjects.firstWhere((o) => o.id == hit.objectId);
    if (object.locked) return;
    _publish(DrawingDocument(
        objects: completedObjects.where((o) => o.id != object.id)));
  }

  bool confirmAnchor() {
    if (_mode != DrawingMode.draw || _tool == null) return false;
    final tool = _tool!;
    if (tool.isFreehand) return _finishFreehand(tool);
    if (_preview == null) return false;
    if (tool == DrawingTool.text) {
      // 文本需要宿主的输入框；先记下锚点，等 commitText/cancelText。
      pendingTextAnchor = _preview;
      _preview = null;
      _draft.clear();
      notifyListeners();
      return true;
    }
    final anchors = [..._draft, _preview!];
    if (anchors.length == tool.anchorCount) {
      return _complete(tool, anchors);
    }
    _draft.add(_preview!);
    _preview = null;
    notifyListeners();
    return true;
  }

  /// 画笔抬笔即完结；不足两个点视为误触并放弃。
  bool _finishFreehand(DrawingTool tool) {
    if (_draft.length < 2) {
      _draft.clear();
      notifyListeners();
      return false;
    }
    return _complete(tool, List.of(_draft));
  }

  bool _complete(DrawingTool tool, List<DrawingAnchor> anchors,
      {String? text}) {
    String id;
    do {
      id = 'drawing-${DateTime.now().microsecondsSinceEpoch}-${_id++}';
    } while (completedObjects.any((o) => o.id == id));
    final object = DrawingObject(
        id: id, tool: tool, anchors: anchors, style: currentStyle, text: text);
    if (!object.isValid) {
      invalidGeometry = true;
      notifyListeners();
      return false;
    }
    completionSerial++;
    _draft.clear();
    _preview = null;
    if (!_continuous) {
      _mode = DrawingMode.browse;
      _tool = null;
    }
    _publish(DrawingDocument(objects: [...completedObjects, object]));
    return true;
  }

  /// 文本由宿主输入框提交；取消或空文本不落图。
  void commitText(String? value) {
    final anchor = pendingTextAnchor;
    pendingTextAnchor = null;
    final trimmed = value?.trim();
    if (anchor == null) return;
    if (trimmed == null || trimmed.isEmpty) {
      cancelDraft();
      return;
    }
    _complete(DrawingTool.text, [anchor], text: trimmed);
  }

  void cancelInteraction() {
    _pointers.clear();
    _ignoredPointers.clear();
    _pinching = false;
    pointerConsumed = false;
    cancelPointer();
  }

  void cancelPointer() {
    // Browsing releases only clear pointer bookkeeping. Notifying here would
    // rebuild drawing tools and host headers after every chart pan or pinch.
    final notify = _mode != DrawingMode.browse ||
        _preview != null ||
        _editPreview != null ||
        _rangeTarget != null;
    if (_tool == DrawingTool.measure) _draft.clear();
    _preview = null;
    _editPreview = null;
    _activePointer = null;
    _frozenCoordinates = null;
    _textResizeSize = null;
    _pointerHit = null;
    _rangeTarget = null;
    if (notify) notifyListeners();
  }

  void browse() => cancelDraft();
  void cancelDraft() {
    cancelInteraction();
    _draft.clear();
    pendingTextAnchor = null;
    _tool = null;
    _selectedId = null;
    _mode = DrawingMode.browse;
    invalidGeometry = false;
    rangeStart = rangeEnd = null;
    notifyListeners();
  }

  void selectObject(String? id) {
    if (_mode == DrawingMode.statistics) return;
    cancelPointer();
    _draft.clear();
    _tool = null;
    _selectedId = id;
    _mode = id == null ? DrawingMode.browse : DrawingMode.edit;
    notifyListeners();
  }

  void beginEdit() {
    final o = selectedObject;
    if (o == null || o.locked) return;
    _editPreview = o;
    notifyListeners();
  }

  void previewEdit(List<DrawingAnchor> anchors) {
    if (_editPreview == null) return;
    _editPreview = _editPreview!.copyWith(anchors: anchors);
    notifyListeners();
  }

  void commitEdit() {
    final edited = _editPreview;
    _editPreview = null;
    if (edited == null || !edited.isValid) {
      notifyListeners();
      return;
    }
    final original = completedObjects.firstWhere((o) => o.id == edited.id);
    final resized = original.style.fontSize != edited.style.fontSize;
    if (listEquals(original.anchors, edited.anchors) && !resized) {
      notifyListeners();
      return;
    }
    if (resized) _styles[edited.tool] = edited.style;
    _replace(edited);
  }

  void _replace(DrawingObject object) => _publish(DrawingDocument(objects: [
        for (final o in completedObjects) o.id == object.id ? object : o
      ]));
  void updateStyle(DrawingStyle style) {
    if (!style.width.isFinite ||
        style.width <= 0 ||
        !style.fontSize.isFinite ||
        style.fontSize <= 0) {
      return;
    }
    final selected = selectedObject;
    if (selected != null) {
      if (selected.locked) return;
      _styles[selected.tool] = style;
      _replace(selected.copyWith(style: style));
    } else if (_tool != null) {
      _styles[_tool!] = style;
      notifyListeners();
    }
  }

  void setLocked(bool locked) {
    final selected = selectedObject;
    if (selected != null && selected.locked != locked) {
      _replace(selected.copyWith(locked: locked));
    }
  }

  void deleteSelected() {
    final selected = selectedObject;
    if (selected == null || selected.locked) return;
    _selectedId = null;
    _mode = DrawingMode.browse;
    _publish(DrawingDocument(
        objects: completedObjects.where((o) => o.id != selected.id)));
  }

  /// The host UI must confirm destructive clear. This operation is undoable.
  void clear() {
    if (completedObjects.isEmpty) return;
    cancelDraft();
    _publish(DrawingDocument());
  }

  void toggleHidden() {
    visibilityToggleSerial++;
    setHidden(!_hidden);
  }

  void setHidden(bool hidden) {
    _hidden = hidden;
    if (hidden && _mode == DrawingMode.edit) selectObject(null);
    notifyListeners();
  }

  void undo() {
    cancelPointer();
    if (_draft.isNotEmpty) {
      _draft.removeLast();
      notifyListeners();
      return;
    }
    if (_undo.isEmpty) return;
    _redo.add(_document);
    _selectedId = null;
    if (_mode == DrawingMode.edit) _mode = DrawingMode.browse;
    _publish(_undo.removeLast(), record: false);
  }

  void redo() {
    if (_redo.isEmpty || _draft.isNotEmpty) return;
    _undo.add(_document);
    _selectedId = null;
    if (_mode == DrawingMode.edit) _mode = DrawingMode.browse;
    _publish(_redo.removeLast(), record: false);
  }

  /// 选中画线上正被按住/拖拽的锚点序号，用于放大高亮该锚点。
  int? get activeAnchorIndex => editing ? _pointerHit?.anchorIndex : null;

  /// Includes derived measurement handles and the channel width anchor.
  int? get activeHandleIndex {
    if (!editing) return null;
    final hit = _pointerHit;
    if (hit?.boxHandle != null) return 2 + hit!.boxHandle!.index;
    if (selectedObject?.tool.isFreehand == true && hit?.anchorIndex != null) {
      return hit!.anchorIndex == 0 ? 0 : 1;
    }
    return hit?.channelEdge == true ? 2 : hit?.anchorIndex;
  }

  DrawingHit? hitTest(Offset point, DrawingCoordinates coordinates,
      {double tolerance = 14}) {
    if (_hidden ||
        _mode == DrawingMode.statistics ||
        !coordinates.plot.contains(point)) {
      return null;
    }
    // 选中画线的锚点手柄使用更大的命中半径，且优先于其他画线，方便拖拽。
    final selected = _mode == DrawingMode.edit ? selectedObject : null;
    if (selected != null) {
      final hit = DrawingGeometry(selected, coordinates).hitTestHandles(
          point,
          selected.tool == DrawingTool.text
              ? tolerance
              : DrawingAnchorPainter.hitRadius);
      if (hit != null) return hit;
    }
    for (final o in visibleObjects.reversed) {
      final hit = DrawingGeometry(o, coordinates).hitTest(point, tolerance);
      if (hit != null) return hit;
    }
    return null;
  }

  void enterStatistics({List<int>? visibleTimes}) {
    final times =
        visibleTimes ?? lastCoordinates?.visibleTimes ?? const <int>[];
    cancelDraft();
    if (times.isEmpty) return;
    _mode = DrawingMode.statistics;
    rangeStart = times.length > 10 ? times[times.length - 10] : times.first;
    rangeEnd = times.last;
    notifyListeners();
  }

  void exitStatistics() => cancelDraft();
  @override
  void dispose() {
    _documentListeners.clear();
    _controlChanges?.dispose();
    super.dispose();
  }
}
