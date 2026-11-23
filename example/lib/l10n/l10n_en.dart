// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get commonBack => 'Back';

  @override
  String get commonOk => 'OK';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get expand => 'Expand';

  @override
  String get collapse => 'Collapse';

  @override
  String get buyIn => 'Buy';

  @override
  String get sellOut => 'Sell';

  @override
  String get buy => 'Buy';

  @override
  String get sell => 'Sell';

  @override
  String get reset => 'Reset';

  @override
  String get copy => 'Copy';

  @override
  String get marketCap => 'MCap';

  @override
  String get liquidity => 'Liquidity';

  @override
  String get volume24h => '24h Vol';

  @override
  String get copied => 'Copied';

  @override
  String get chartPeriod30sec => '30s';

  @override
  String get chartPeriod1min => '1m';

  @override
  String get chartPeriod3min => '3m';

  @override
  String get chartPeriod15min => '15m';

  @override
  String get chartPeriod30min => '30m';

  @override
  String get chartPeriod1hour => '1h';

  @override
  String get chartPeriod2hour => '2h';

  @override
  String get chartPeriod4hour => '4h';

  @override
  String get chartPeriod6hour => '6h';

  @override
  String get chartPeriod12hour => '12h';

  @override
  String get chartPeriod1day => '1D';

  @override
  String get chartPeriod5min => '5m';

  @override
  String get chartPeriod1week => '1w';

  @override
  String get chartPeriod1month => '1M';

  @override
  String get chartPeriod3month => '3M';

  @override
  String get retry => 'Retry';

  @override
  String get commonMore => 'More';

  @override
  String get date => 'date';

  @override
  String get opening => 'open';

  @override
  String get high => 'high';

  @override
  String get low => 'low';

  @override
  String get closing => 'close';

  @override
  String get changeAmount => 'change amount';

  @override
  String get change => 'change';

  @override
  String get amount => 'amount';

  @override
  String get vol => 'vol';

  @override
  String get transactionHistory => 'Transaction History';

  @override
  String get chartBuyRecords => 'Buy Records';

  @override
  String get chartSellRecords => 'Sell Records';

  @override
  String get chartPrice => 'Price';

  @override
  String get chartMarketCap => 'MCap';

  @override
  String get chartAvgBuyLabel => 'Avg Buy Price';

  @override
  String get chartAvgSellLabel => 'Avg Sell Price';

  @override
  String get chartAvgBuyMarketCapLabel => 'Avg Buy MCap';

  @override
  String get chartAvgSellMarketCapLabel => 'Avg Sell MCap';

  @override
  String get chartDataDisplay => 'Data display';

  @override
  String get chartSettingsSection => 'Settings';

  @override
  String get chartTradeDisplay => 'Trade display';

  @override
  String get chartHeight => 'Chart height';

  @override
  String get chartBuySellPrice => 'Trade markers';

  @override
  String get chartBuySellAveragePrice => 'Avg. trade price';

  @override
  String get chartCandlestickOnlyHint =>
      '* These settings only apply to candlestick charts';

  @override
  String get chartRiseFallColor => 'Rise/fall colors';

  @override
  String get chartRiseColor => 'Rise';

  @override
  String get chartFallColor => 'Fall';

  @override
  String get indicatorSettingsTitle => 'Indicators';

  @override
  String get chartSettingsTitle => 'Chart Settings';

  @override
  String get chartTimeSettings => 'Time settings';

  @override
  String get chartCustomTimeframes => 'Custom timeframes';

  @override
  String get chartTimeframes => 'Timeframes';

  @override
  String get chartEditTimeframes => 'Edit timeframes';

  @override
  String chartTimeframesAdded(Object count, Object max) {
    return '$count/$max added';
  }

  @override
  String get chartTimeframeMaxToast => 'You can only add up to 5 timeframes.';

  @override
  String get chartTypeToggle => 'Toggle chart type';

  @override
  String get indicatorMainChart => 'Main chart';

  @override
  String get indicatorSecondaryChart => 'Secondary chart';

  @override
  String get settingSave => 'Save';

  @override
  String get chartFullscreen => 'Full screen chart';

  @override
  String get chartShareKline => 'Share K-line';

  @override
  String get chartShareFailed => 'Unable to capture chart. Please try again.';

  @override
  String get chartCloseFullscreen => 'Close full screen';

  @override
  String get chartHolderCount => 'Holders';

  @override
  String get chartClosePortraitFullscreen => 'Exit full screen';

  @override
  String get chartPreferPortraitFullscreen => 'Portrait fullscreen chart';

  @override
  String get chartSwitchToLandscapeFullscreen =>
      'Switch to landscape fullscreen';

  @override
  String get chartExitFullscreenCorner => 'Exit fullscreen';

  @override
  String get chartPriceScaleAuto => 'Auto-scale price axis';

  @override
  String get chartNoCandles => 'No candlestick data';

  @override
  String get chartDrawingCategoryLines => 'Lines';

  @override
  String get chartDrawingCategoryWaves => 'Waves';

  @override
  String get chartDrawingCategoryShapes => 'Shapes';

  @override
  String get chartDrawingCategoryFibonacci => 'Fibonacci';

  @override
  String get chartDrawingCategoryBrush => 'Brush';

  @override
  String get chartDrawingCategoryText => 'Text';

  @override
  String get chartDrawingErase => 'Erase drawings';

  @override
  String get chartDrawingExit => 'Exit drawing mode';

  @override
  String get chartDrawingTools => 'Drawing tools';

  @override
  String get chartDrawingSnap => 'Snap';

  @override
  String get chartDrawingContinuous => 'Continuous drawing';

  @override
  String get chartDrawingHide => 'Hide drawings';

  @override
  String get chartDrawingShow => 'Show drawings';

  @override
  String get chartDrawingUndo => 'Undo';

  @override
  String get chartDrawingRedo => 'Redo';

  @override
  String get chartDrawingClear => 'Clear all';

  @override
  String get chartDrawingClearConfirmation =>
      'Clear all drawings for this token?';

  @override
  String get chartDrawingConfirm => 'Clear';

  @override
  String get chartDrawingCompleted => 'Completed';

  @override
  String get chartDrawingInvalidGeometry => 'Adjust the last point';

  @override
  String get chartDrawingStatistics => 'Range statistics';

  @override
  String get chartDrawingExitStatistics => 'Close statistics';

  @override
  String get chartDrawingLock => 'Lock';

  @override
  String get chartDrawingUnlock => 'Unlock';

  @override
  String get chartDrawingDelete => 'Delete';

  @override
  String get chartDrawingColor => 'Border color';

  @override
  String get chartDrawingFill => 'Fill color';

  @override
  String get chartDrawingNoFill => 'No fill';

  @override
  String get chartDrawingWidth => 'Line width';

  @override
  String get chartDrawingLineStyle => 'Line style';

  @override
  String get chartDrawingExtend => 'Extend';

  @override
  String get chartDrawingReverse => 'Reverse';

  @override
  String get chartDrawingShowPrice => 'Price label';

  @override
  String get chartDrawingCancel => 'Cancel';

  @override
  String get chartDrawingPrice => 'Price';

  @override
  String get chartDrawingMarketCap => 'Market cap';

  @override
  String get chartDrawingTime => 'Time';

  @override
  String get chartDrawingCount => 'Periods';

  @override
  String get chartDrawingStart => 'Start';

  @override
  String get chartDrawingEnd => 'End';

  @override
  String get chartDrawingHigh => 'High';

  @override
  String get chartDrawingLow => 'Low';

  @override
  String get chartDrawingChange => 'Change';

  @override
  String get chartDrawingVolume => 'Volume';

  @override
  String get chartDrawingAmount => 'Amount';

  @override
  String get chartDrawingIncludesUnclosed => 'Includes unclosed candle';

  @override
  String get chartDrawingDrag => 'Move toolbar';

  @override
  String get chartDrawingTrendLine => 'Trend line';

  @override
  String get chartDrawingExtendedLine => 'Extended trend line';

  @override
  String get chartDrawingRay => 'Ray';

  @override
  String get chartDrawingHorizontalLine => 'Horizontal line';

  @override
  String get chartDrawingVerticalLine => 'Vertical line';

  @override
  String get chartDrawingParallelChannel => 'Track lines';

  @override
  String get chartDrawingPriceLine => 'Price line';

  @override
  String get chartDrawingSelected => 'selected';

  @override
  String chartDrawingPlacePoints(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Place $count points to finish',
      one: 'Place 1 point to finish',
    );
    return '$_temp0';
  }

  @override
  String get chartDrawingFreehandHint => 'Drag on the chart to draw';

  @override
  String get chartDrawingEraseOnNotice => 'Eraser on';

  @override
  String get chartDrawingEraseOffNotice => 'Eraser off';

  @override
  String get chartDrawingHiddenNotice => 'Hide drawings';

  @override
  String get chartDrawingShownNotice => 'Show drawings';

  @override
  String get chartDrawingStatisticsNotice => 'Entered range statistics mode';

  @override
  String get chartDrawingSnapOnNotice => 'Snap on';

  @override
  String get chartDrawingSnapOffNotice => 'Snap off';

  @override
  String get chartDrawingContinuousOnNotice => 'Continuous drawing on';

  @override
  String get chartDrawingContinuousOffNotice => 'Continuous drawing off';

  @override
  String get chartDrawingTextPlacementHint =>
      'Tap the chart where the text should go';

  @override
  String get chartDrawingFontSize => 'Font size';

  @override
  String get chartDrawingBold => 'Bold';

  @override
  String get chartDrawingItalic => 'Italic';

  @override
  String get chartDrawingTextBackground => 'Background';

  @override
  String get chartDrawingNoBackground => 'None';

  @override
  String get chartDrawingRectangle => 'Rectangle';

  @override
  String get chartDrawingFibonacci => 'Fibonacci retracement';

  @override
  String get chartDrawingThreeWave => 'Three wave';

  @override
  String get chartDrawingFiveWave => 'Five wave';

  @override
  String get chartDrawingBrush => 'Brush';

  @override
  String get chartDrawingText => 'Text';

  @override
  String get chartDrawingTextHint => 'Enter text';

  @override
  String get chartDrawingSolid => 'Solid';

  @override
  String get chartDrawingDashed => 'Dashed';

  @override
  String get chartDrawingDotted => 'Dotted';

  @override
  String get chartDrawingSaveFailed =>
      'Drawings could not be saved. Your edits remain available; retry saving.';

  @override
  String get chartDrawingHiddenPromptTitle => 'Drawings are hidden';

  @override
  String get chartDrawingHiddenPromptBody =>
      '\"Hide drawings\" is on, so anything you draw now won\'t be visible. Show drawings and continue?';

  @override
  String get chartDrawingHiddenPromptDontShowAgain => 'Don\'t show again';

  @override
  String get chartDrawingHiddenPromptConfirm => 'Show & continue';

  @override
  String get chartDrawingHiddenPromptCancel => 'Cancel';

  @override
  String get chartDrawingShownToast => 'Drawings shown';

  @override
  String get chartIndicatorInvalidTimestamp => 'Candle timestamp unavailable';

  @override
  String get chartIndicatorIntervalUnknown => 'Candle interval unavailable';

  @override
  String get chartIndicatorIntradayOnly =>
      'Available on intraday intervals only';

  @override
  String get chartIndicatorIncompleteUtcSession =>
      'Complete history from UTC 00:00 required';

  @override
  String get chartIndicatorInvalidVolumeOrPrice =>
      'Reliable volume and price required';

  @override
  String get chartIndicatorZeroCumulativeVolume =>
      'No cumulative session volume';

  @override
  String get chartIndicatorEstimatedAverage => 'Based on K-line estimates';

  @override
  String get chartIndicatorQuoteBaseAverage => 'Quote amount / base volume';

  @override
  String get chartIndicatorUnavailable => 'Indicator unavailable';

  @override
  String get chartDrawingMeasure => 'Measure / price range';

  @override
  String chartDrawingMeasureDuration(String duration) {
    return '$duration';
  }
}
