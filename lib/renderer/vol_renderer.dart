import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../candlestick_widget.dart';
import '../entity/k_line_entity.dart';
import '../entity/volume_entity.dart';
import 'index.dart';

class VolRenderer extends BaseChartRenderer<VolumeEntity> {
  VolRenderer(Rect mainRect, double maxValue, double minValue,
      double topPadding, int fixedLength, this.chartStyle, this.chartColors,
      [PriceFormatter? priceFormatter])
      : super(
          chartRect: mainRect,
          maxValue: maxValue,
          minValue: minValue,
          topPadding: topPadding,
          fixedLength: fixedLength,
          gridColor: chartColors.gridColor,
          priceFormatter: priceFormatter,
        ) {
    mVolWidth = chartStyle.volWidth;
  }
  late double mVolWidth;
  final ChartStyle chartStyle;
  final ChartColors chartColors;
  static final Set<String> _loggedRenderStates = <String>{};

  bool _validVolume(VolumeEntity point) =>
      point.vol.isFinite &&
      point.vol >= 0 &&
      (point is! KLineEntity || point.volumeValid);

  @override
  void drawChart(VolumeEntity lastPoint, VolumeEntity curPoint, double lastX,
      double curX, Size size, Canvas canvas) {
    if (!_validVolume(curPoint)) return;
    double r = mVolWidth / 2;
    double top = getVolY(curPoint.vol);
    double bottom = chartRect.bottom;
    _logRenderDiagnostics(curPoint, top: top, bottom: bottom);
    if (curPoint.vol != 0) {
      canvas.drawRect(
          Rect.fromLTRB(curX - r, top, curX + r, bottom),
          chartPaint
            ..color = curPoint.close > curPoint.open
                ? chartColors.upColor
                : chartColors.dnColor);
    }

    if (_validVolume(lastPoint) && lastPoint.MA5Volume != null) {
      drawLine(lastPoint.MA5Volume, curPoint.MA5Volume, canvas, lastX, curX,
          chartColors.ma5Color);
    }

    if (_validVolume(lastPoint) && lastPoint.MA10Volume != null) {
      drawLine(lastPoint.MA10Volume, curPoint.MA10Volume, canvas, lastX, curX,
          chartColors.ma10Color);
    }
  }

  double getVolY(double value) =>
      (maxValue - value) * (chartRect.height / maxValue) + chartRect.top;

  void _logRenderDiagnostics(
    VolumeEntity point, {
    required double top,
    required double bottom,
  }) {
    if (!kDebugMode || point is! KLineEntity) return;

    final signature = '${point.time}:${point.vol}:$maxValue:'
        '${chartRect.height}:${point.MA5Volume}:${point.MA10Volume}';
    if (!_loggedRenderStates.add(signature)) return;
    if (_loggedRenderStates.length > 500) {
      _loggedRenderStates.clear();
      _loggedRenderStates.add(signature);
    }

    final heightRatio = maxValue > 0 ? point.vol / maxValue : 0.0;
    debugPrint(
      '[KLINE][VOL_RENDER] time=${point.time} '
      'open=${point.open} close=${point.close} vol=${point.vol} '
      'ma5=${point.MA5Volume} ma10=${point.MA10Volume} '
      'visibleMax=$maxValue chartHeight=${chartRect.height} '
      'top=$top bottom=$bottom barHeight=${bottom - top} '
      'heightRatio=${heightRatio.toStringAsFixed(6)}',
    );
  }

  @override
  void drawText(Canvas canvas, VolumeEntity data, double x) {
    TextSpan span = TextSpan(
      children: [
        TextSpan(
            text: 'VOL:${format(_validVolume(data) ? data.vol : null)}    ',
            style: getTextStyle(chartColors.volColor)),
        TextSpan(
            text: data.MA5Volume != null
                ? 'MA5:${format(data.MA5Volume!)}    '
                : 'MA5:--    ',
            style: getTextStyle(chartColors.ma5Color)),
        TextSpan(
            text: data.MA10Volume != null
                ? 'MA10:${format(data.MA10Volume!)}    '
                : 'MA10:--    ',
            style: getTextStyle(chartColors.ma10Color)),
      ],
    );
    final tp = layoutText(span);
    tp.paint(canvas, Offset(x, chartRect.top - topPadding));
  }

  @override
  void drawVerticalText(canvas, textStyle, int gridRows) {
    TextSpan span = TextSpan(text: format(maxValue), style: textStyle);
    final tp = layoutText(span);
    tp.paint(canvas,
        Offset(chartRect.width - tp.width - 10.0, chartRect.top - topPadding));
  }

  @override
  void drawGrid(Canvas canvas, int gridRows, int gridColumns) {
    canvas.drawLine(Offset(0, chartRect.bottom),
        Offset(chartRect.width, chartRect.bottom), gridPaint);
    double columnSpace = chartRect.width / gridColumns;
    for (int i = 0; i <= gridColumns; i++) {
      //vol垂直线
      canvas.drawLine(Offset(columnSpace * i, chartRect.top - topPadding),
          Offset(columnSpace * i, chartRect.bottom), gridPaint);
    }
  }
}
// ignore_for_file: type_annotate_public_apis
