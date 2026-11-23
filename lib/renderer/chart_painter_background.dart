part of 'chart_painter.dart';

const int _dateAxisVisibleIntervals = 4;
const int _dateAxisBufferedIntervals = 2;

/// 背景层绘制：背景矩形 + 品牌水印、网格、日期行、副图刻度与最值标签。
extension _ChartBackgroundDrawing on ChartPainter {
  void drawBgImpl(Canvas canvas, Size size) {
    final mBgPaint = _backgroundPaint..color = chartColors.bgColor;
    Rect mainRect =
        Rect.fromLTRB(0, 0, mMainRect.width, mMainRect.height + mTopPadding);
    canvas.drawRect(mainRect, mBgPaint);

    // 品牌水印：叠加在主图内部左下角（背景层），K 线/指标绘制在其上方。
    final picture = watermarkPicture;
    if (picture != null && picture.size.height > 0) {
      final scale = picture.height / picture.size.height;
      final drawSize = Size(picture.size.width * scale, picture.height);
      final offset = Offset(
        mMainRect.left + 8,
        mMainRect.bottom - drawSize.height - watermarkBottomInset,
      );
      final rect = offset & drawSize;
      final tint = Paint()
        ..colorFilter = ColorFilter.mode(watermarkColor, BlendMode.srcIn);
      final cache = watermarkCache;
      if (cache != null && drawSize.width.isFinite && drawSize.width > 0) {
        final image = cache.resolve(picture, pixelRatio);
        canvas.drawImageRect(
            image,
            Rect.fromLTWH(0, 0, drawSize.width * pixelRatio,
                drawSize.height * pixelRatio),
            rect,
            tint..filterQuality = FilterQuality.low);
      } else {
        // Direct painter users may omit the widget-owned raster cache.
        canvas
          ..saveLayer(rect, tint)
          ..translate(offset.dx, offset.dy)
          ..scale(scale)
          ..drawPicture(picture.picture)
          ..restore();
      }
      mWatermarkRect = rect;
    } else if (watermarkText?.isNotEmpty == true) {
      final painter = TextPainter(
        text: TextSpan(
          text: watermarkText,
          style: TextStyle(
            color: watermarkColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: math.max(0, mMainRect.width - 16));
      final offset = Offset(
        mMainRect.left + 8,
        mMainRect.bottom - painter.height - watermarkBottomInset,
      );
      painter.paint(canvas, offset);
      mWatermarkRect = offset & painter.size;
    } else {
      mWatermarkRect = null;
    }

    if (showDateAxis) {
      Rect dateRect = Rect.fromLTRB(
        0,
        mMainRect.bottom + BaseChartPainter.dateRowGap,
        size.width,
        mMainRect.bottom + BaseChartPainter.dateRowGap + mDateRowHeight,
      );
      canvas.drawRect(dateRect, mBgPaint);
    }

    if (mVolRect != null) {
      Rect volRect = Rect.fromLTRB(
          0, mVolRect!.top - mChildPadding, mVolRect!.width, mVolRect!.bottom);
      canvas.drawRect(volRect, mBgPaint);
    }

    for (int i = 0; i < mSecondaryRectList.length; ++i) {
      Rect? mSecondaryRect = mSecondaryRectList[i].mRect;
      Rect secondaryRect = Rect.fromLTRB(0, mSecondaryRect.top - mChildPadding,
          mSecondaryRect.width, mSecondaryRect.bottom);
      canvas.drawRect(secondaryRect, mBgPaint);
    }
  }

  void drawGridImpl(Canvas canvas, {bool mainOnly = false}) {
    final dateBottom =
        mMainRect.bottom + BaseChartPainter.dateRowGap + mDateRowHeight;
    final hasChildren = mSecondaryRectList.isNotEmpty || mVolRect != null;
    final lastPlotBottom = mSecondaryRectList.isNotEmpty
        ? mSecondaryRectList.last.mRect.bottom
        : mVolRect?.bottom ?? dateBottom;
    // 指标栏紧接画布底边；边框不能落在含有底部留白的绘图区底边。
    final borders = showDateAxis
        ? <double>{
            mMainRect.bottom,
            if (hasChildren) dateBottom,
            mDisplayHeight + mTopPadding + mBottomPadding - .5,
          }
        : <double>{};
    canvas.save();
    for (final y in {...borders, if (showDateAxis) lastPlotBottom}) {
      canvas.clipRect(Rect.fromLTRB(0, y - 4, mWidth, y + 4),
          clipOp: ClipOp.difference);
    }
    if (!hideGrid) {
      mMainRenderer.drawGrid(canvas, mGridRows, mGridColumns);
      if (!mainOnly) {
        mVolRenderer?.drawGrid(canvas, mGridRows, mGridColumns);
        for (var element in mSecondaryRendererList) {
          element.drawGrid(canvas, mGridRows, mGridColumns);
        }
      }
    }
    canvas.restore();
    for (final y in borders) {
      drawChartSectionDivider(canvas, mWidth, y, chartColors.gridColor);
    }
  }

  void drawVerticalTextImpl(Canvas canvas) {
    var textStyle = getTextStyle(chartColors.defaultTextColor);
    mVolRenderer?.drawVerticalText(canvas, textStyle, mGridRows);
    for (var element in mSecondaryRendererList) {
      element.drawVerticalText(canvas, textStyle, mGridRows);
    }
  }

  void drawDateImpl(Canvas canvas, Size size) {
    if (datas == null || datas!.isEmpty || mGridColumns <= 0) {
      dateAxisLabels = const <ChartDateLabel>[];
      return;
    }

    final labels = <ChartDateLabel>[];
    final visibleSlotCount = math.max(1.0, size.width / (mPointWidth * scaleX));
    final indexStep =
        math.max(1, (visibleSlotCount / _dateAxisVisibleIntervals).ceil());
    final firstVisibleIndex = (mStartIndex ~/ indexStep) * indexStep;
    final firstIndex =
        firstVisibleIndex - indexStep * _dateAxisBufferedIntervals;
    final lastIndex = mStopIndex + indexStep * _dateAxisBufferedIntervals;

    double previousRight = double.negativeInfinity;
    for (var index = firstIndex; index <= lastIndex; index += indexStep) {
      if (index < 0 || index >= datas!.length) continue;

      final text = getDate(datas![index].time);
      final span = TextSpan(
          text: text,
          style:
              getTextStyle(chartColors.defaultTextColor).copyWith(height: 1));
      final tp = textCache?.layout(span) ??
          (TextPainter(text: span, textDirection: TextDirection.ltr)..layout());
      final centerX = translateXtoX(getX(index));
      final x = centerX - tp.width / 2;
      final right = x + tp.width;
      if (x < previousRight + 8) continue;

      final y = mMainRect.bottom +
          // 顶部间隔也在日期栏分隔线内，文字按完整栏高居中。
          (BaseChartPainter.dateRowGap + mDateRowHeight - tp.height) / 2;
      tp.paint(canvas, Offset(x, y));
      labels.add(ChartDateLabel(
        index: index,
        text: text,
        centerX: centerX,
        paintX: x,
      ));
      previousRight = right;
    }
    dateAxisLabels = labels;
  }

  void drawTextImpl(Canvas canvas, KLineEntity data, double x) {
    // Readouts show the latest calculated values, like the current-price tag.
    // Only geometry interpolates; no synthetic intermediate numbers to lay out.
    final labelData = rangeDatas ?? datas;
    if (labelData != null && labelData.isNotEmpty) data = labelData.last;
    if (isLongPress || isCrossLocked || (isTapShowInfoDialog && isOnTap)) {
      var index = calculateSelectedX(selectX);
      data = labelData?[index] ?? getItem(index);
    }

    mMainRenderer.drawText(canvas, data, x);
    mVolRenderer?.drawText(canvas, data, x);
    for (var element in mSecondaryRendererList) {
      element.drawText(canvas, data, x);
    }
  }

  void drawMaxAndMinImpl(Canvas canvas) {
    if (isLine == true) return;

    double x = translateXtoX(getX(mMainMinIndex));
    double y = getMainY(mMainLowMinValue);
    if (x < mWidth / 2) {
      TextPainter tp = getTextPainter(
          '── ${formatPrice(mMainLowMinValue)}', chartColors.minColor);
      tp.paint(canvas, Offset(x, y - tp.height / 2));
    } else {
      TextPainter tp = getTextPainter(
          '${formatPrice(mMainLowMinValue)} ──', chartColors.minColor);
      tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
    }
    x = translateXtoX(getX(mMainMaxIndex));
    y = getMainY(mMainHighMaxValue);
    if (x < mWidth / 2) {
      TextPainter tp = getTextPainter(
          '── ${formatPrice(mMainHighMaxValue)}', chartColors.maxColor);
      tp.paint(canvas, Offset(x, y - tp.height / 2));
    } else {
      TextPainter tp = getTextPainter(
          '${formatPrice(mMainHighMaxValue)} ──', chartColors.maxColor);
      tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
    }
  }
}
