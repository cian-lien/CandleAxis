part of 'base_chart_painter.dart';

/// Recompute auto bounds before resolving the single displayed price range.
extension _BaseChartPainterExtrema on BaseChartPainter {
  void calculateValue() {
    if (datas == null) return;
    if (datas!.isEmpty) return;

    final rangeData = rangeDatas ?? datas!;

    // Recompute extrema from the current viewport on every paint. Without
    // resetting these values, vertical scaling compounds after any rebuild
    // (including a simple tap) and progressively distorts the price axis.
    mMainMaxValue = double.negativeInfinity;
    mMainMinValue = double.maxFinite;
    mVolMaxValue = 0;
    mVolMinValue = 0;
    mMainHighMaxValue = double.negativeInfinity;
    mMainLowMinValue = double.maxFinite;
    mMainMaxIndex = 0;
    mMainMinIndex = 0;
    for (final rect in mSecondaryRectList) {
      rect.mMaxValue = double.negativeInfinity;
      rect.mMinValue = double.infinity;
    }

    BaseChartPainter.maxScrollX = getMinTranslateX().abs() + getMaxTranslateX();
    setTranslateXFromScrollX(scrollX);
    mStartIndex = indexOfTranslateX(xToTranslateX(0));
    mStopIndex = indexOfTranslateX(xToTranslateX(mWidth));
    // RESIST levels come from the final candle, independent of visible index.
    // Include them once rather than rebuilding/scanning the same series for
    // every candle (especially costly at scaleX=0.3 in landscape).
    if (mainStateLi.contains(MainState.RESIST)) {
      for (var line = 0;
          line < mainIndicatorLineCount(MainState.RESIST);
          line++) {
        final value =
            mainIndicatorValue(MainState.RESIST, rangeData.last, line);
        if (value != null && value.isFinite) {
          mMainMaxValue = max(mMainMaxValue, value);
          mMainMinValue = min(mMainMinValue, value);
        }
      }
    }
    final secondaryStates = secondaryStateLi.toList(growable: false);
    for (int i = mStartIndex; i <= mStopIndex; i++) {
      final item = datas![i];
      getMainMaxMinValue(rangeData[i], i, rangeData);
      getVolMaxMinValue(item);
      for (int idx = 0; idx < mSecondaryRectList.length; ++idx) {
        getSecondaryMaxMinValue(idx, item, secondaryStates[idx]);
      }
    }
    for (final rect in mSecondaryRectList) {
      if (!rect.mMaxValue.isFinite || !rect.mMinValue.isFinite) {
        rect.mMaxValue = 1;
        rect.mMinValue = -1;
      }
    }
    if (mMainMaxValue == mMainMinValue) {
      final padding = mMainMaxValue.abs() * 0.05 + 0.01;
      mMainMaxValue += padding;
      mMainMinValue -= padding;
    }
    if (mMainMaxValue > mMainMinValue &&
        mMainMaxValue.isFinite &&
        mMainMinValue.isFinite) {
      autoPriceRange =
          PriceRange(mMainMinValue, mMainMaxValue).scaled(1 / 1.08);
      final target = manualPriceRange ?? autoPriceRange!.scaled(verticalScale);
      final displayed = priceRangeTransition?.resolve(target, viewportAnimation,
              immediate: manualPriceRange != null) ??
          target;
      mMainMinValue = displayed.min;
      mMainMaxValue = displayed.max;
    }
  }

  void getMainMaxMinValue(
      KLineEntity item, int i, List<KLineEntity> rangeData) {
    double maxPrice = item.high;
    double minPrice = item.low;
    for (final state in mainStateLi) {
      if (state == MainState.RESIST) continue;
      for (var line = 0; line < mainIndicatorLineCount(state); line++) {
        final value = mainIndicatorValueAt(state, i, rangeData, line);
        if (value != null && value.isFinite) {
          maxPrice = max(maxPrice, value);
          minPrice = min(minPrice, value);
        }
      }
      if (state == MainState.ICHI && translateXtoX(getX(i + 26)) <= mWidth) {
        for (var line = 0; line < mainIndicatorLineCount(state); line++) {
          if (mainIndicatorOffset(state, line) != 26) continue;
          final value = mainIndicatorValue(state, item, line);
          if (value != null && value.isFinite) {
            maxPrice = max(maxPrice, value);
            minPrice = min(minPrice, value);
          }
        }
      }
    }

    mMainMaxValue = max(mMainMaxValue, maxPrice);
    mMainMinValue = min(mMainMinValue, minPrice);

    if (mMainHighMaxValue < item.high) {
      mMainHighMaxValue = item.high;
      mMainMaxIndex = i;
    }
    if (mMainLowMinValue > item.low) {
      mMainLowMinValue = item.low;
      mMainMinIndex = i;
    }

    if (isLine == true) {
      mMainMaxValue = max(mMainMaxValue, item.close);
      mMainMinValue = min(mMainMinValue, item.close);
    }
  }

  void getVolMaxMinValue(KLineEntity item) {
    if (!item.volumeValid || !item.vol.isFinite || item.vol < 0) return;
    mVolMaxValue = max(mVolMaxValue,
        max(item.vol, max(item.MA5Volume ?? 0, item.MA10Volume ?? 0)));
    mVolMinValue = min(mVolMinValue,
        min(item.vol, min(item.MA5Volume ?? 0, item.MA10Volume ?? 0)));
  }

  void getSecondaryMaxMinValue(int index, KLineEntity item,
      [SecondaryState? panelState]) {
    final state = panelState ?? secondaryStateLi.elementAt(index);
    final rect = mSecondaryRectList[index];
    final bounded = state == SecondaryState.RSI ||
        state == SecondaryState.MFI ||
        state == SecondaryState.StochRSI ||
        state == SecondaryState.DMI;
    if (bounded || state == SecondaryState.WR) {
      rect.mMaxValue = bounded ? 100 : 0;
      rect.mMinValue = bounded ? 0 : -100;
      return;
    }
    final count = secondaryIndicatorLineCount(state);
    for (var line = 0; line < count; line++) {
      final value = secondaryIndicatorValue(state, item, line);
      if (value != null && value.isFinite) {
        rect.mMaxValue = max(rect.mMaxValue, value);
        rect.mMinValue = min(rect.mMinValue, value);
      }
    }
    // Zero is meaningful for momentum, differences, and the MACD histogram.
    if (state == SecondaryState.MACD ||
        state == SecondaryState.ROC ||
        state == SecondaryState.DMA ||
        state == SecondaryState.MTM ||
        state == SecondaryState.EMV) {
      rect.mMaxValue = max(rect.mMaxValue, 0);
      rect.mMinValue = min(rect.mMinValue, 0);
    }
  }
}
