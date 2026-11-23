part of 'chart_painter.dart';

/// 现价标签（白底胶囊）几何常量：绘制与命中检测共用，禁止在方法内重复声明。
const _buttonPadding = 6.0; // 左右内边距
const _buttonTopPadding = 4.5; // 上内边距
const _buttonBottomPadding = 4.5; // 下内边距
const _arrowGap = 4.0; // 文字与箭头的间距
const _arrowWidth = 5.0; // 箭头槽位宽 = chevron 绘制宽（±2.5），不留空槽
const _candlesRightInset = 70.0; // auto 模式停靠时的右侧缩进
const _rightEdgeGap = 10.0; // 距右缘的间距

/// 现价绘制：屏幕横贯虚线、右缘现价按钮（含箭头淡入）与线图端点光点。
extension _ChartNowPriceDrawing on ChartPainter {
  double get _currentPrice => (rangeDatas ?? datas)!.last.close;

  void drawNowPriceImpl(
    Canvas canvas, {
    bool drawLine = true,
    bool drawLabel = true,
  }) {
    if (!showNowPrice) {
      return;
    }

    if (datas == null) {
      return;
    }

    final value = _currentPrice;
    final tp = _getNowPriceTextPainter(
      formatPrice(value),
      chartColors.nowPriceTextColor,
    );
    final y = _nowPriceY(tp);

    nowPricePaint.color = chartColors.nowPriceColor;

    if (drawLine) {
      canvas.save();
      canvas.clipRect(mMainRect);
      // 使用屏幕坐标绘制虚线，确保覆盖整个可见宽度
      nowPricePaint
        ..color = chartColors.nowPriceLineColor
        ..strokeWidth = chartStyle.nowPriceDashWidth;
      dashCache.draw(canvas, mWidth, y, chartStyle.nowPriceDashLength,
          chartStyle.nowPriceDashSpan, nowPricePaint);

      canvas.restore();

      // Line-mode endpoint marker, painted before the price button so the
      // button stays on top when they overlap. It is welded to the polyline's
      // last vertex (captured in drawChart), so it always marks the line's
      // latest-price tip — the now-price dashed line/tag never influences it.
      // When the tip scrolls out of the viewport the canvas clip hides the dot
      // together with the line end, so it can never sit on historical wiggles.
      final Offset? endpointOffset = isLine ? endpointDotOffset : null;

      if (endpointOffset != null) {
        final color = chartColors.kLineColor;
        final glowPaint = Paint()
          ..color = color.withValues(alpha: 0.15)
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;
        canvas.drawCircle(endpointOffset, 7.5, glowPaint);

        // Radar-ping halo: a ring expanding and fading out each cycle.
        if (endpointPulse != null) {
          final t = endpointPulse!.value.clamp(0.0, 1.0);
          final ringPaint = Paint()
            ..color = color.withValues(alpha: 0.4 * (1.0 - t))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..isAntiAlias = true;
          canvas.drawCircle(endpointOffset, 4.5 + 9.0 * t, ringPaint);
        }

        final dotPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;
        canvas.drawCircle(endpointOffset, 4.5, dotPaint);
      }
    }

    if (!drawLabel) return;

    double offsetX;
    final positionProgress = nowPriceAlignment == NowPriceAlignment.auto
        ? nowPricePositionProgress.clamp(0.0, 1.0)
        : 1.0;
    final arrowExtra = (_arrowGap + _arrowWidth) * positionProgress;
    final buttonWidth = tp.width + _buttonPadding * 2 + arrowExtra;

    if (nowPriceAlignment != null) {
      switch (nowPriceAlignment!) {
        case NowPriceAlignment.left:
          offsetX = 0;
          break;
        case NowPriceAlignment.right:
          offsetX = mWidth - buttonWidth - _rightEdgeGap;
          break;
        case NowPriceAlignment.auto:
          final rightInset = _rightEdgeGap +
              (_candlesRightInset - _rightEdgeGap) * positionProgress;
          offsetX = (mWidth - rightInset - buttonWidth)
              .clamp(
                0.0,
                math.max(0.0, mWidth - buttonWidth - _rightEdgeGap),
              )
              .toDouble();
          break;
      }
    } else {
      switch (verticalTextAlignment) {
        case VerticalTextAlignment.left:
          offsetX = mWidth - tp.width;
          break;
        case VerticalTextAlignment.right:
          offsetX = 0;
          break;
      }
    }

    canvas.save();
    canvas.clipRect(mMainRect);
    final top = y - tp.height / 2 - _buttonTopPadding;
    final bottom = y + tp.height / 2 + _buttonBottomPadding;
    final right = offsetX + buttonWidth;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTRB(offsetX, top, right, bottom),
      const Radius.circular(4),
    );
    final buttonFillPaint = Paint()
      ..color = chartColors.selectFillColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final buttonBorderPaint = Paint()
      ..color = chartColors.nowPriceLineColor
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
    canvas.drawRRect(rect, buttonFillPaint);
    canvas.drawRRect(rect, buttonBorderPaint);
    nowPriceTagRect = rect.outerRect;
    final rectCenterY = rect.outerRect.center.dy;
    tp.paint(
      canvas,
      Offset(offsetX + _buttonPadding, rectCenterY - tp.height / 2),
    );

    final arrowPaint = Paint()
      ..color = chartColors.nowPriceTextColor
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
    if (positionProgress > 0) {
      canvas.save();
      canvas.clipRRect(rect);
      // chevron 高 7（±3.5，与数字字高等高、同以 y 居中 → 垂直对齐），
      // 宽 5（±2.5）恰好填满槽位，右侧与内边距齐平，不再有空槽。
      final arrowCenterX = right - _buttonPadding - _arrowWidth / 2;
      final arrowCenterY = rectCenterY;
      arrowPaint.color = chartColors.nowPriceTextColor.withValues(
        alpha: positionProgress,
      );
      final arrowPath = Path()
        ..moveTo(arrowCenterX - 2.5, arrowCenterY - 3.5)
        ..lineTo(arrowCenterX + 2.5, arrowCenterY)
        ..lineTo(arrowCenterX - 2.5, arrowCenterY + 3.5);
      canvas.drawPath(arrowPath, arrowPaint);
      canvas.restore();
    }
    canvas.restore();
  }

  void drawNowPriceLineImpl(Canvas canvas) {
    drawNowPriceImpl(canvas, drawLabel: false);
  }

  void drawNowPriceLabelImpl(Canvas canvas) {
    drawNowPriceImpl(canvas, drawLine: false);
  }

  TextPainter _getNowPriceTextPainter(String text, Color color) {
    final span = TextSpan(
      text: text,
      style: getTextStyle(color).copyWith(height: 1),
    );
    return textCache?.layout(span) ??
        (TextPainter(text: span, textDirection: TextDirection.ltr)..layout());
  }

  double _nowPriceY(TextPainter tp) => clampMainPlotY(
        getMainY(_currentPrice),
        tp.height + _buttonTopPadding + _buttonBottomPadding,
        padding: 0.4,
      );

  bool isNowPriceButtonHitImpl(Offset position) {
    if (!showNowPrice || datas == null || datas!.isEmpty) return false;
    final tp = _getNowPriceTextPainter(
        formatPrice(_currentPrice), chartColors.nowPriceTextColor);
    final positionProgress = nowPriceAlignment == NowPriceAlignment.auto
        ? nowPricePositionProgress.clamp(0.0, 1.0)
        : 1.0;
    final arrowExtra = (_arrowGap + _arrowWidth) * positionProgress;
    final buttonWidth = tp.width + _buttonPadding * 2 + arrowExtra;
    final left = nowPriceAlignment == NowPriceAlignment.left
        ? 0.0
        : (nowPriceAlignment == NowPriceAlignment.right
            ? mWidth - buttonWidth - _rightEdgeGap
            : (mWidth -
                    (_rightEdgeGap +
                        (_candlesRightInset - _rightEdgeGap) *
                            positionProgress) -
                    buttonWidth)
                .clamp(0.0, math.max(0.0, mWidth - buttonWidth - _rightEdgeGap))
                .toDouble());
    final y = _nowPriceY(tp);
    return Rect.fromLTWH(
      left,
      y - tp.height / 2 - _buttonTopPadding,
      buttonWidth,
      tp.height + _buttonTopPadding + _buttonBottomPadding,
    ).contains(position);
  }
}
