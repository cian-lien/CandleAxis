import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/gestures.dart' show EagerGestureRecognizer;
import 'package:flutter/material.dart';
import '../entity/k_line_entity.dart';
import 'chart_drawing_controller.dart';
import 'drawing_category_panel.dart';
import 'drawing_color_palette.dart';
import 'drawing_coordinates.dart';
import 'drawing_geometry.dart';
import 'drawing_hint_banner.dart';
import 'drawing_labels.dart';
import 'drawing_measurement.dart';
import 'drawing_models.dart';
import 'drawing_popup.dart';
import 'drawing_range_layout.dart';
import 'drawing_statistics.dart';
import 'drawing_tools.dart';
import 'measure_label_layout.dart';

part 'drawing_overlay_editing.dart';
part 'drawing_overlay_statistics.dart';
part 'drawing_overlay_measure.dart';
part 'drawing_magnifier.dart';

/// Optional chart UI. All labels and value/date formatting belong to the host.
class DrawingOverlay extends StatefulWidget {
  const DrawingOverlay(
      {super.key,
      required this.controller,
      this.viewportChanges,
      required this.labels,
      required this.rawData,
      required this.chartSize,
      required this.paintChart,
      required this.priceFormatter,
      required this.dateFormatter,
      this.amountFormatter,
      this.isMarketCap = false,
      this.factor = 1,
      this.latestClosed = false,
      this.showToolbar = true,
      this.showStatisticsPanel = true,
      this.showHint = true,
      this.measurementOnly = false});
  final ChartDrawingController controller;
  final Listenable? viewportChanges;
  final DrawingLabels labels;
  final List<KLineEntity> rawData;
  final Size chartSize;
  final void Function(Canvas, Size) paintChart;
  final String Function(double) priceFormatter;
  final String Function(int?) dateFormatter;
  final String Function(double)? amountFormatter;
  final bool isMarketCap, latestClosed;
  final bool showToolbar, showStatisticsPanel, showHint;

  /// Display-only charts retain measurement labels without editing controls.
  final bool measurementOnly;
  final double factor;
  @override
  State<DrawingOverlay> createState() => _DrawingOverlayState();
}

class _DrawingOverlayState extends State<DrawingOverlay>
    with WidgetsBindingObserver {
  /// 用户拖动编辑工具条的位移（已夹紧）；默认停在图表底部水平居中。
  Offset _toolbarDrag = Offset.zero;
  int? _toolbarPointer;
  final _toolbarKey = GlobalKey();
  bool _toolbarClampPending = false;
  final _viewportTick = ValueNotifier<int>(0);
  bool? _magnifierOnLeft;
  Timer? _completionTimer;
  int _completionSerial = 0;
  bool _completed = false;
  DrawingToolCategory? _expandedCategory;
  static const _fontSizes = [10.0, 12.0, 14.0, 16.0, 20.0, 24.0];
  ChartDrawingController get c => widget.controller;
  DrawingLabels get labels => widget.labels;
  @override
  void initState() {
    super.initState();
    c.controlChanges.addListener(_changed);
    widget.viewportChanges?.addListener(_viewportChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  /// 旋转、键盘或安全区变化时，图表尺寸可能不变，需单独重新夹紧工具条。
  @override
  void didChangeMetrics() => _scheduleToolbarClamp();

  @override
  void didUpdateWidget(DrawingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewportChanges != widget.viewportChanges) {
      oldWidget.viewportChanges?.removeListener(_viewportChanged);
      widget.viewportChanges?.addListener(_viewportChanged);
    }
    if (oldWidget.controller != c) {
      oldWidget.controller.controlChanges.removeListener(_changed);
      c.controlChanges.addListener(_changed);
    }
  }

  bool _viewportUpdatePending = false;

  void _viewportChanged() {
    if (_viewportUpdatePending ||
        !(c.visibleObjects.any((o) => o.tool == DrawingTool.measure) ||
            c.preview != null ||
            c.rangeStart != null)) {
      return;
    }
    // Coordinates are written by ChartPainter during paint. Refresh only this
    // overlay after paint, never notify the controller's parent listeners.
    _viewportUpdatePending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewportUpdatePending = false;
      if (mounted) _viewportTick.value++;
    });
  }

  void _changed() {
    if (!mounted) return;
    if (_completionSerial != c.completionSerial) {
      _completionSerial = c.completionSerial;
      _completed = true;
      _completionTimer?.cancel();
      _completionTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _completed = false);
      });
    }
    if (c.preview == null) _magnifierOnLeft = null;
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    c.controlChanges.removeListener(_changed);
    widget.viewportChanges?.removeListener(_viewportChanged);
    _completionTimer?.cancel();
    _viewportTick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.measurementOnly) {
      return _movingLayer(widget.chartSize, measurementOnly: true);
    }
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final toolbarMaxWidth = math.max(1.0, size.width - 16);
      const toolbarHeight = 44.0;
      // 工具条与图表底边留出间距，不贴着副图指标。
      final toolbarTop = size.height - toolbarHeight - 20 + _toolbarDrag.dy;
      final draftTool = c.tool;
      final showEditingToolbar = draftTool != null || c.selectedObject != null;
      // 布局完成后按实际尺寸夹紧，覆盖首帧、图表尺寸变化与横竖屏切换。
      if (showEditingToolbar) _scheduleToolbarClamp();
      return Listener(
          onPointerDown: (event) => c.ignorePointer(event.pointer),
          child: Stack(children: [
            Positioned.fill(child: _movingLayer(size, measurementOnly: true)),
            if (widget.showToolbar)
              Positioned(
                  top: 4,
                  right: 4,
                  bottom: 4,
                  child: _surface(DrawingTools(
                      controller: c,
                      labels: labels,
                      canMeasure: widget.rawData.isNotEmpty,
                      onExpandCategory: (category) =>
                          setState(() => _expandedCategory = category)))),
            if (widget.showToolbar && _expandedCategory != null)
              Positioned(
                  top: 4,
                  right: 52,
                  child: DrawingCategoryPanel(
                    controller: c,
                    labels: labels,
                    category: _expandedCategory!,
                    onClose: () => setState(() => _expandedCategory = null),
                  )),
            if (widget.showHint && draftTool != null)
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Center(
                    child: DrawingHintBanner(controller: c, labels: labels)),
              ),
            if (_completed && draftTool == null)
              Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: Center(
                      child: IgnorePointer(
                          child: _surface(Padding(
                              padding: const EdgeInsets.all(6),
                              child: Text(labels.completed,
                                  style: const TextStyle(fontSize: 11))))))),
            if (showEditingToolbar)
              // 横向铺满：平移后的工具条仍在父级范围内，贴边时手柄可命中。
              Positioned(
                  left: 0,
                  right: 0,
                  top: toolbarTop,
                  child: Center(
                      child: Transform.translate(
                          offset: Offset(_toolbarDrag.dx, 0),
                          child: ConstrainedBox(
                              key: _toolbarKey,
                              constraints:
                                  BoxConstraints(maxWidth: toolbarMaxWidth),
                              child: _editingToolbar())))),
            Positioned.fill(child: _movingLayer(size)),
          ]));
    });
  }

  Widget _movingLayer(Size size, {bool measurementOnly = false}) =>
      RepaintBoundary(
        child: ListenableBuilder(
          listenable: Listenable.merge([c, _viewportTick]),
          builder: (context, _) {
            if (measurementOnly) return Stack(children: _measurementLabels());
            if (c.preview == null) _magnifierOnLeft = null;
            return Stack(children: [
              if (widget.showStatisticsPanel &&
                  c.mode == DrawingMode.statistics &&
                  c.rangeStart != null)
                _statisticsPanelPositioned(size),
              if (c.preview != null && c.lastCoordinates != null)
                ..._magnifier(size),
            ]);
          },
        ),
      );

  void _releaseToolbarPointer(int pointer) {
    if (_toolbarPointer == pointer) _toolbarPointer = null;
  }

  void _moveToolbar(Offset delta) =>
      setState(() => _toolbarDrag = _clampToolbarDrag(_toolbarDrag, delta));

  void _scheduleToolbarClamp() {
    if (_toolbarClampPending) return;
    _toolbarClampPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _toolbarClampPending = false;
      if (!mounted) return;
      final clamped = _clampToolbarDrag(_toolbarDrag, Offset.zero);
      if (clamped != _toolbarDrag) setState(() => _toolbarDrag = clamped);
    });
  }

  /// 把工具条按 [delta] 移动后的位置夹紧到「图表区域 ∩ 屏幕安全可视区」内，
  /// 返回新的拖拽位移。工具条尚未布局时原样返回。
  Offset _clampToolbarDrag(Offset drag, Offset delta) {
    final toolbar = _toolbarKey.currentContext?.findRenderObject();
    final overlay = context.findRenderObject();
    if (toolbar is! RenderBox ||
        !toolbar.hasSize ||
        overlay is! RenderBox ||
        !overlay.hasSize) {
      return drag + delta;
    }
    final rect =
        (toolbar.localToGlobal(Offset.zero) & toolbar.size).shift(delta);
    final bounds = _toolbarBounds(overlay);
    // 路由旋转过渡可能暂时产生不可逆矩阵，保留上一次有效位置。
    if (!rect.isFinite || !bounds.isFinite) return drag;
    // 可视区比工具条还小时贴住左上角，保证拖拽手柄可见。
    final maxLeft = math.max(bounds.left, bounds.right - rect.width);
    final maxTop = math.max(bounds.top, bounds.bottom - rect.height);
    final target = Offset(rect.left.clamp(bounds.left, maxLeft),
        rect.top.clamp(bounds.top, maxTop));
    return drag + delta + (target - rect.topLeft);
  }

  Rect _toolbarBounds(RenderBox overlay) {
    const margin = 4.0;
    // 用 View 的原始度量：祖先 SafeArea 会清零 MediaQuery.padding。
    final view = MediaQueryData.fromView(View.of(context));
    final insets = EdgeInsets.fromLTRB(
        math.max(view.padding.left, view.viewInsets.left),
        math.max(view.padding.top, view.viewInsets.top),
        math.max(view.padding.right, view.viewInsets.right),
        math.max(view.padding.bottom, view.viewInsets.bottom));
    final screen = insets.deflateRect(Offset.zero & view.size);
    final chart = overlay.localToGlobal(Offset.zero) & overlay.size;
    // 顶部让出提示横幅的位置。
    final area = Rect.fromLTRB(chart.left + margin, chart.top + 46,
            chart.right - margin, chart.bottom - margin)
        .intersect(screen.deflate(margin));
    if (area.width >= 0 && area.height >= 0) return area;
    // 图表与可视区不相交（极端尺寸）时退回可视区，至少保证可见。
    return screen.deflate(margin);
  }

  Widget _surface(Widget child) => Material(
      color: const Color(0xEE161B22),
      borderRadius: BorderRadius.circular(8),
      child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white, fontSize: 11),
          child: child));
  Widget _button(IconData icon, String tooltip, VoidCallback? callback,
          {bool selected = false}) =>
      IconButton(
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          padding: EdgeInsets.zero,
          tooltip: tooltip,
          onPressed: callback,
          icon: Icon(icon,
              size: 20,
              color: callback == null
                  ? _disabledToolColor
                  : selected
                      ? const Color(0xFF4285F4)
                      : Colors.white));

  /// 工具条底色固定为深色（与主题无关），禁用项统一为 38% 白。
  static const _disabledToolColor = Color(0x61FFFFFF);

  /// 菜单类按钮的图标（含自绘色块）不受 IconButton 禁用色影响，统一按透明度变暗。
  Widget _dimmed(Widget icon, {required bool enabled}) =>
      enabled ? icon : Opacity(opacity: .38, child: icon);
}
