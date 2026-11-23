part of 'chart_drawing_controller.dart';

extension DrawingPointerInteraction on ChartDrawingController {
  void pointerDown(int pointer, Offset point, DrawingCoordinates coordinates) {
    if (_ignoredPointers.contains(pointer)) return;
    _pointers.add(pointer);
    if (_pointers.length >= 2) {
      _pinching = true;
      cancelPointer();
      return;
    }
    _pinching = false;
    pointerConsumed = false;
    if (!coordinates.isUsable || !coordinates.plot.contains(point)) return;
    if (mode == DrawingMode.statistics) {
      // 只有手柄和关闭按钮吃掉触点；其余位置照常平移/缩放，区间不跟手。
      final layout = DrawingRangeLayout.of(coordinates, rangeStart, rangeEnd);
      final target = layout?.hitTest(point);
      if (layout == null || target == null) return;
      _frozenCoordinates = coordinates;
      _activePointer = pointer;
      _rangeTarget = target;
      _rangeGrabOffset = point.dx -
          (target == DrawingRangeTarget.start ? layout.left : layout.right);
      pointerConsumed = true;
      _notify();
      return;
    }
    _frozenCoordinates = coordinates;
    _activePointer = pointer;
    if (mode == DrawingMode.draw) {
      pointerConsumed = true;
      _locate(point);
      if (tool == DrawingTool.measure) confirmAnchor();
      return;
    }
    if (mode == DrawingMode.erase) {
      pointerConsumed = true;
      // Commit on release so cancellation or a second finger can still abort.
      _pointerOrigin = coordinates.fromScreen(point);
      return;
    }
    final hit = hitTest(point, coordinates);
    if (hit == null) {
      if (mode == DrawingMode.edit) {
        selectObject(null);
        pointerConsumed = true;
      }
      _activePointer = null;
      return;
    }
    // selectObject resets preview bookkeeping, then the gesture freezes it.
    selectObject(hit.objectId);
    _frozenCoordinates = coordinates;
    _activePointer = pointer;
    _pointerHit = hit;
    _pointerOrigin = coordinates.fromScreen(point);
    _originalAnchors = List.of(selectedObject!.anchors);
    pointerConsumed = true;
    beginEdit();
    // Expanded anchor targets also select on a tap. Locate only on movement
    // so selection does not rewrite an anchor or open the magnifier.
  }

  void _locate(Offset point) {
    final map = _frozenCoordinates!;
    // 文本可自由拖出绘图区，不吸附边缘；其他工具仍限制在绘图区内。
    final tool = mode == DrawingMode.draw ? this.tool : selectedObject?.tool;
    final p = tool == DrawingTool.text ? point : map.clamp(point);
    final free = snapping ? map.snap(p) : map.fromScreen(p);
    // Measure always uses candle time, even when OHLC snapping is disabled.
    final anchor = tool == DrawingTool.measure
        ? DrawingAnchor(time: map.nearestTime(p.dx), price: free.price)
        : free;
    if (mode == DrawingMode.draw) {
      previewAnchor(anchor);
    } else if (editing && _pointerHit?.textCorner != null) {
      _resizeText(point);
    } else if (editing && _pointerHit?.boxHandle != null) {
      final handle = _pointerHit!.boxHandle!;
      final anchors = List<DrawingAnchor>.of(_originalAnchors);
      for (var i = 0; i < anchors.length; i++) {
        anchors[i] = DrawingAnchor(
            time: handle.timeIndex == i ? anchor.time : anchors[i].time,
            price: handle.priceIndex == i ? anchor.price : anchors[i].price);
      }
      // An edge midpoint is not a persisted anchor; keep its opposite axis.
      final center =
          Rect.fromPoints(map.toScreen(anchors[0]), map.toScreen(anchors[1]))
              .center;
      _preview = map.fromScreen(Offset(
          handle.timeIndex == null ? center.dx : map.toScreen(anchor).dx,
          handle.priceIndex == null ? center.dy : map.toScreen(anchor).dy));
      previewEdit(anchors);
    } else if (editing && _pointerHit?.channelEdge == true) {
      final anchors = List<DrawingAnchor>.of(_originalAnchors);
      final d = map.toScreen(anchors[1]) - map.toScreen(anchors[0]);
      final delta = map.toScreen(anchor) - map.toScreen(_pointerOrigin!);
      // Remove movement along the baseline and preserve the initial grab gap.
      final offset = d.dx.abs() < 1e-12
          ? Offset(delta.dx, 0)
          : Offset(0, delta.dy - d.dy * delta.dx / d.dx);
      anchors[2] = map.fromScreen(map.toScreen(anchors[2]) + offset);
      _preview = map.fromScreen(
          DrawingGeometry(selectedObject!.copyWith(anchors: anchors), map)
              .handlePoints[2]);
      previewEdit(anchors);
    } else if (editing && _pointerHit?.anchorIndex != null) {
      _preview = anchor;
      final anchors = List<DrawingAnchor>.of(_originalAnchors);
      anchors[_pointerHit!.anchorIndex!] = anchor;
      previewEdit(anchors);
    }
  }

  void _resizeText(Offset point) {
    final original =
        completedObjects.firstWhere((o) => o.id == _editPreview!.id);
    final size = _textResizeSize ??= _measureOriginalText(original);
    final corner = _pointerHit!.textCorner!;
    final diagonal = Offset(corner.isEven ? -size.width : size.width,
        corner < 2 ? -size.height : size.height);
    if (diagonal.distanceSquared == 0) return;
    final delta = point - _frozenCoordinates!.toScreen(_pointerOrigin!);
    // Project from the original grab, avoiding cumulative scaling and snapping.
    // All four corners scale outward while the persisted top-left stays fixed.
    final scale = 1 +
        (delta.dx * diagonal.dx + delta.dy * diagonal.dy) /
            diagonal.distanceSquared;
    final fontSize = (original.style.fontSize * scale).clamp(8.0, 48.0);
    _editPreview =
        original.copyWith(style: original.style.copyWith(fontSize: fontSize));
    _notify();
  }

  Size _measureOriginalText(DrawingObject original) {
    // The original font and viewport are frozen for this gesture. Keep only
    // its metrics, and release the temporary paragraph immediately.
    final painter = DrawingGeometry(original, _frozenCoordinates!).textPainter!;
    final size = painter.size;
    painter.dispose();
    return size;
  }

  /// 拖动手柄：边界线跟随手指（保留按下时的抓取偏移），吸附到蜡烛边缘，
  /// 且左右边界不能交叉。
  void _dragRangeEdge(Offset point) {
    final target = _rangeTarget;
    if (target == null || target == DrawingRangeTarget.close) return;
    final map = _frozenCoordinates!;
    final half = map.pointWidth * map.scaleX / 2;
    // 边界不拖出绘图区，手柄始终可见、可再次抓取。
    final edge =
        (point.dx - _rangeGrabOffset).clamp(map.plot.left, map.plot.right);
    if (target == DrawingRangeTarget.start) {
      final time = map.nearestTime(edge + half);
      rangeStart = time > rangeEnd! ? rangeEnd : time;
    } else {
      final time = map.nearestTime(edge - half);
      rangeEnd = time < rangeStart! ? rangeStart : time;
    }
    _notify();
  }

  void pointerMove(int pointer, Offset point) {
    if (_ignoredPointers.contains(pointer)) return;
    if (_activePointer != pointer || _pinching || _frozenCoordinates == null) {
      return;
    }
    if (mode == DrawingMode.statistics) {
      _dragRangeEdge(point);
      return;
    }
    // Pen endpoints are move handles: preserve every sample with one chart delta.
    if (mode == DrawingMode.draw ||
        (_pointerHit?.anchorIndex != null &&
            selectedObject?.tool.isFreehand != true) ||
        _pointerHit?.boxHandle != null ||
        _pointerHit?.textCorner != null ||
        _pointerHit?.channelEdge == true) {
      _locate(point);
      return;
    }
    if (!editing || _pointerOrigin == null) return;
    final current = _frozenCoordinates!.fromScreen(point);
    final dt = current.time - _pointerOrigin!.time;
    final dp = current.price - _pointerOrigin!.price;
    final map = _frozenCoordinates!;
    if (selectedObject?.tool == DrawingTool.measure) {
      final dx = point.dx - map.toScreen(_pointerOrigin!).dx;
      previewEdit(MeasureCandleAnchors(map.candles).translate(_originalAnchors,
          bars: (dx / (map.pointWidth * map.scaleX)).round(), priceDelta: dp));
      return;
    }
    previewEdit([
      for (final a in _originalAnchors)
        DrawingAnchor(time: a.time + dt, price: a.price + dp)
    ]);
  }

  void pointerUp(int pointer, {bool cancelled = false}) {
    if (_ignoredPointers.remove(pointer)) return;
    if (tool == DrawingTool.measure && (cancelled || _pinching)) {
      _draft.clear();
    }
    if (_activePointer == pointer && !_pinching && !cancelled) {
      if (mode == DrawingMode.statistics &&
          _rangeTarget == DrawingRangeTarget.close) {
        exitStatistics();
        // 退出后仍标记已消费，避免同一次点按落到图表上锁定十字线。
        pointerConsumed = true;
        return;
      }
      if (mode == DrawingMode.draw) {
        if (tool == DrawingTool.measure && _preview == null) {
          _draft.clear();
        } else {
          confirmAnchor();
          if (tool == DrawingTool.measure) _draft.clear();
        }
      } else if (mode == DrawingMode.erase && _pointerOrigin != null) {
        final coordinates = _frozenCoordinates!;
        eraseAt(coordinates.toScreen(_pointerOrigin!), coordinates);
      } else if (editing) {
        commitEdit();
      }
    }
    _pointers.remove(pointer);
    if (pointer == _activePointer || _pointers.isEmpty) cancelPointer();
    if (_pointers.isEmpty) _pinching = false;
  }

  /// Cancel an in-flight gesture when the external price dimension changes.
  void updateDisplayBasis(Object basis) {
    if (_displayBasis != null &&
        _displayBasis != basis &&
        _activePointer != null) {
      cancelPointer();
      pointerConsumed = true;
    }
    _displayBasis = basis;
  }
}
