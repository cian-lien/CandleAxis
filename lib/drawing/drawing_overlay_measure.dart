part of 'drawing_overlay.dart';

extension _DrawingMeasureLabels on _DrawingOverlayState {
  List<Widget> _measurementLabels() {
    final map = c.lastCoordinates;
    if (map == null || !map.isUsable) return const [];
    final draft = c.tool == DrawingTool.measure ? c.draftObject : null;
    final objects = [
      ...c.visibleObjects,
      if (draft != null) draft,
    ];
    final scheme = Theme.of(context).colorScheme;
    return [
      for (final object in objects)
        if (object.tool == DrawingTool.measure && object.anchors.length == 2)
          ..._measureLabel(object, map, scheme)
    ];
  }

  List<Widget> _measureLabel(
      DrawingObject object, DrawingCoordinates map, ColorScheme scheme) {
    final points = DrawingGeometry(object, map).points;
    final box = Rect.fromPoints(points[0], points[1]);
    if (!box.overlaps(map.plot)) return const [];
    final measurement =
        DrawingMeasurement.calculate(object.anchors, widget.rawData);
    final width = math.min(240.0, map.plot.width);
    final style = TextStyle(color: scheme.onSurface, fontSize: 11);
    final lines = [
      '${labels.change}: ${widget.priceFormatter(measurement.change)} / ${measurement.changePercent?.toStringAsFixed(2) ?? '—'}%',
      '${labels.count}: ${measurement.bars}',
      '${labels.time}: ${labels.measureDuration(measurement.duration.inSeconds)}',
    ];
    // Include padding and the actual scaled text height before choosing a side.
    var height = 8.0;
    for (var i = 0; i < lines.length; i++) {
      final painter = TextPainter(
          text: TextSpan(text: lines[i], style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          locale: Localizations.maybeLocaleOf(context),
          maxLines: 1,
          ellipsis: i == 1 ? null : '…')
        ..layout(maxWidth: math.max(0.0, width - 8));
      height += painter.height;
      painter.dispose();
    }
    final rect = computeMeasureLabelRect(
        box: box, plot: map.plot, labelSize: Size(width, height));
    if (rect == null) return const [];
    return [
      Positioned(
          left: rect.left,
          top: rect.top,
          width: width,
          child: IgnorePointer(
              child: Material(
                  key: ValueKey('drawing-measure-${object.id}'),
                  color: scheme.surfaceContainerHigh.withValues(alpha: .92),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: DefaultTextStyle(
                          style: style,
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(lines[0],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                Text(lines[1], maxLines: 1),
                                Text(lines[2],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ]))))))
    ];
  }
}
