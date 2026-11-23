part of 'chart_painter.dart';

/// 十字光标标签共用深色背景，浅色与暗黑主题均使用白字。
const Color _crossTagBgColor = Color(0xFF222223);

/// 十字线绘制：横竖虚线与右侧黑底药丸标签（加号 + 价格/涨跌% + 分割线）。
extension _ChartCrosshairDrawing on ChartPainter {
  /// 十字横线的绘制 Y：跟随手指时 clamp 在主图内，否则钉在收盘价。
  double _crossLineY(KLineEntity point) {
    if (crossY != null) {
      return crossY!.clamp(mMainRect.top, mMainRect.bottom);
    }
    return getMainY(point.close);
  }

  void drawCrossLineTextImpl(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    KLineEntity point = getItem(index);

    bool infoWindowIsLeft = translateXtoX(getX(index)) >= mWidth / 2;

    bool priceTagOnLeft;
    if (crossPriceAlignment == CrossPriceAlignment.left) {
      priceTagOnLeft = true;
    } else if (crossPriceAlignment == CrossPriceAlignment.right) {
      priceTagOnLeft = false;
    } else {
      priceTagOnLeft = infoWindowIsLeft;
    }

    // 十字横线：锁定拖动/长按时跟随手指（clamp 在主图内），
    // 否则钉在所选 K 线收盘价（保持旧行为）。
    final double y = _crossLineY(point);

    // 标签布局：[白色圆形+黑色加号] + 两行数据（价格 / 涨跌%），黑底。
    final crossPrice = priceFromY(y);
    _lastCrossTagPrice = crossPrice;
    final priceTp = getTextPainter(formatPrice(crossPrice), Colors.white);
    final percentText =
        ChartPainter.crosshairChangePercent(crossPrice, datas!.last.close);
    final percentTp =
        percentText == null ? null : getTextPainter(percentText, Colors.white);

    const hPadding = 5.0;
    const vPadding = 6.0;
    const rowGap = 2.0;
    // 加号与数值同属一个黑色标签，中间由 1px 白色分割线隔开：
    // 分割线纵贯 tag 全高，左右各留 5px 间距。
    const plusDiameter = 12.0;
    const dividerSideGap = 5.0;
    const dividerWidth = 1.0;

    final dataWidth = math.max(priceTp.width, percentTp?.width ?? 0);
    final dataHeight = priceTp.height +
        (percentTp?.height ?? 0) +
        (percentTp == null ? 0.0 : rowGap);
    final pillWidth = hPadding +
        plusDiameter +
        dividerSideGap +
        dividerWidth +
        dividerSideGap +
        dataWidth +
        hPadding;
    final pillHeight = math.max(plusDiameter, dataHeight) + vPadding * 2;

    // 右缘与价格轴刻度对齐（MainRenderer.drawVerticalText 右对齐同款 10px）。
    const tagRightInset = 10.0;
    final pillLeft = priceTagOnLeft ? 1.0 : mWidth - tagRightInset - pillWidth;
    // 标签可覆盖价格刻度，但整体不超出主图上下边界。
    final maxTagTop = math.max(mMainRect.top, mMainRect.bottom - pillHeight);
    final tagTop = (y - pillHeight / 2).clamp(mMainRect.top, maxTagTop);
    final tagRect = Rect.fromLTRB(
        pillLeft, tagTop, pillLeft + pillWidth, tagTop + pillHeight);
    crossTagHitRect = tagRect;

    canvas.drawRRect(
      RRect.fromRectAndRadius(tagRect, const Radius.circular(8)),
      Paint()..color = _crossTagBgColor,
    );

    // 加号：黑底白色笔画（无白圆底），位于标签内侧；
    // 标签贴左边缘时镜像到数据行右侧。
    final plusLeft = priceTagOnLeft
        ? pillLeft + pillWidth - hPadding - plusDiameter
        : pillLeft + hPadding;
    final plusCenter = Offset(plusLeft + plusDiameter / 2, tagRect.center.dy);
    crossPlusCircleRect =
        Rect.fromCircle(center: plusCenter, radius: plusDiameter / 2);
    final plusPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    const plusArm = 3.0;
    canvas.drawLine(plusCenter - const Offset(plusArm, 0),
        plusCenter + const Offset(plusArm, 0), plusPaint);
    canvas.drawLine(plusCenter - const Offset(0, plusArm),
        plusCenter + const Offset(0, plusArm), plusPaint);

    // 1px 白色竖分割线：纵贯 tag 全高，加号侧与数据侧各留 5px。
    final dividerLeft = priceTagOnLeft
        ? plusLeft - dividerSideGap - dividerWidth
        : plusLeft + plusDiameter + dividerSideGap;
    crossDividerRect = Rect.fromLTWH(
      dividerLeft,
      tagTop,
      dividerWidth,
      pillHeight,
    );
    canvas.drawRect(
      crossDividerRect!,
      Paint()
        ..color = Colors.white
        ..isAntiAlias = true,
    );

    // 数据两行在标签内垂直居中，位于分割线另一侧 5px 处。
    final dataLeft = priceTagOnLeft
        ? pillLeft + hPadding
        : crossDividerRect!.right + dividerSideGap;
    final dataTop = tagTop + (pillHeight - dataHeight) / 2;
    priceTp.paint(canvas, Offset(dataLeft, dataTop));
    if (percentTp != null) {
      percentTp.paint(
        canvas,
        Offset(dataLeft, dataTop + priceTp.height + rowGap),
      );
    }

    if (showDateAxis) {
      final dateTp = TextPainter(
        text: TextSpan(
          text: getDate(point.time),
          style: getTextStyle(Colors.white).copyWith(height: 1),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      const horizontalPadding = 5.0;
      const verticalPadding = 2.0;
      final halfWidth = dateTp.width / 2 + horizontalPadding;
      final x = translateXtoX(getX(index)).clamp(
        1 + halfWidth,
        mWidth - 1 - halfWidth,
      );
      // 与普通日期共用完整时间栏的垂直中心，避免选中后文字下跳。
      final centerY =
          mMainRect.bottom + (BaseChartPainter.dateRowGap + mDateRowHeight) / 2;
      final dateRect = Rect.fromCenter(
        center: Offset(x, centerY),
        width: halfWidth * 2,
        height: dateTp.height + verticalPadding * 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(dateRect, const Radius.circular(4)),
        Paint()..color = _crossTagBgColor,
      );
      dateTp.paint(
        canvas,
        Offset(x - dateTp.width / 2, centerY - dateTp.height / 2),
      );
    }

    sink.add(InfoWindowEntity(
      point,
      isLeft: infoWindowIsLeft,
      trades: tradesAtIndex(index),
    ));
  }

  void drawCrossLineImpl(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    KLineEntity point = getItem(index);
    double x = getX(index);
    double y = _crossLineY(point);

    Paint paintY = Paint()
      ..color = chartColors.vCrossColor
      ..strokeWidth = chartStyle.vCrossWidth / scaleX
      ..isAntiAlias = true;

    Paint paintX = Paint()
      ..color = chartColors.hCrossColor
      ..strokeWidth = chartStyle.hCrossWidth
      ..isAntiAlias = true;

    if (chartStyle.crossLineDash) {
      _drawDashedLineCompensated(
        canvas,
        Offset(x, mTopPadding),
        Offset(x, size.height - mBottomPadding),
        paintY,
        scaleX,
      );

      _drawDashedLineHorizontalCompensated(canvas, Offset(-mTranslateX, y),
          Offset(-mTranslateX + mWidth / scaleX, y), paintX, scaleX);
    } else {
      canvas.drawLine(Offset(x, mTopPadding),
          Offset(x, size.height - mBottomPadding), paintY);
      canvas.drawLine(Offset(-mTranslateX, y),
          Offset(-mTranslateX + mWidth / scaleX, y), paintX);
    }

    Paint paintDot = Paint()
      ..color = chartColors.hCrossColor
      ..style = PaintingStyle.fill;
    double radius = 3.0;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x, y),
        width: radius * 2 / scaleX,
        height: radius * 2,
      ),
      paintDot,
    );
  }

  void _drawDashedLineCompensated(
      Canvas canvas, Offset start, Offset end, Paint paint, double scaleX) {
    final dashLength = chartStyle.crossLineDashLength;
    final dashSpace = chartStyle.crossLineDashSpace;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final unitX = dx / distance;
    final unitY = dy / distance;

    double currentDistance = 0;
    while (currentDistance < distance) {
      final segmentEnd = (currentDistance + dashLength).clamp(0.0, distance);
      canvas.drawLine(
        Offset(start.dx + unitX * currentDistance,
            start.dy + unitY * currentDistance),
        Offset(start.dx + unitX * segmentEnd, start.dy + unitY * segmentEnd),
        paint,
      );
      currentDistance += dashLength + dashSpace;
    }
  }

  void _drawDashedLineHorizontalCompensated(
      Canvas canvas, Offset start, Offset end, Paint paint, double scaleX) {
    final dashLength = chartStyle.crossLineDashLength / scaleX;
    final dashSpace = chartStyle.crossLineDashSpace / scaleX;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final unitX = dx / distance;
    final unitY = dy / distance;

    double currentDistance = 0;
    while (currentDistance < distance) {
      final segmentEnd = (currentDistance + dashLength).clamp(0.0, distance);
      canvas.drawLine(
        Offset(start.dx + unitX * currentDistance,
            start.dy + unitY * currentDistance),
        Offset(start.dx + unitX * segmentEnd, start.dy + unitY * segmentEnd),
        paint,
      );
      currentDistance += dashLength + dashSpace;
    }
  }
}
