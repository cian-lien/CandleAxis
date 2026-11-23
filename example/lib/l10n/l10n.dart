import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'l10n_en.dart';
import 'l10n_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @expand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expand;

  /// No description provided for @collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// No description provided for @buyIn.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buyIn;

  /// No description provided for @sellOut.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get sellOut;

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// No description provided for @sell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get sell;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @marketCap.
  ///
  /// In en, this message translates to:
  /// **'MCap'**
  String get marketCap;

  /// No description provided for @liquidity.
  ///
  /// In en, this message translates to:
  /// **'Liquidity'**
  String get liquidity;

  /// No description provided for @volume24h.
  ///
  /// In en, this message translates to:
  /// **'24h Vol'**
  String get volume24h;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @chartPeriod30sec.
  ///
  /// In en, this message translates to:
  /// **'30s'**
  String get chartPeriod30sec;

  /// No description provided for @chartPeriod1min.
  ///
  /// In en, this message translates to:
  /// **'1m'**
  String get chartPeriod1min;

  /// No description provided for @chartPeriod3min.
  ///
  /// In en, this message translates to:
  /// **'3m'**
  String get chartPeriod3min;

  /// No description provided for @chartPeriod15min.
  ///
  /// In en, this message translates to:
  /// **'15m'**
  String get chartPeriod15min;

  /// No description provided for @chartPeriod30min.
  ///
  /// In en, this message translates to:
  /// **'30m'**
  String get chartPeriod30min;

  /// No description provided for @chartPeriod1hour.
  ///
  /// In en, this message translates to:
  /// **'1h'**
  String get chartPeriod1hour;

  /// No description provided for @chartPeriod2hour.
  ///
  /// In en, this message translates to:
  /// **'2h'**
  String get chartPeriod2hour;

  /// No description provided for @chartPeriod4hour.
  ///
  /// In en, this message translates to:
  /// **'4h'**
  String get chartPeriod4hour;

  /// No description provided for @chartPeriod6hour.
  ///
  /// In en, this message translates to:
  /// **'6h'**
  String get chartPeriod6hour;

  /// No description provided for @chartPeriod12hour.
  ///
  /// In en, this message translates to:
  /// **'12h'**
  String get chartPeriod12hour;

  /// No description provided for @chartPeriod1day.
  ///
  /// In en, this message translates to:
  /// **'1D'**
  String get chartPeriod1day;

  /// No description provided for @chartPeriod5min.
  ///
  /// In en, this message translates to:
  /// **'5m'**
  String get chartPeriod5min;

  /// No description provided for @chartPeriod1week.
  ///
  /// In en, this message translates to:
  /// **'1w'**
  String get chartPeriod1week;

  /// No description provided for @chartPeriod1month.
  ///
  /// In en, this message translates to:
  /// **'1M'**
  String get chartPeriod1month;

  /// No description provided for @chartPeriod3month.
  ///
  /// In en, this message translates to:
  /// **'3M'**
  String get chartPeriod3month;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @commonMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get commonMore;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'date'**
  String get date;

  /// No description provided for @opening.
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get opening;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'high'**
  String get high;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'low'**
  String get low;

  /// No description provided for @closing.
  ///
  /// In en, this message translates to:
  /// **'close'**
  String get closing;

  /// No description provided for @changeAmount.
  ///
  /// In en, this message translates to:
  /// **'change amount'**
  String get changeAmount;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'change'**
  String get change;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'amount'**
  String get amount;

  /// No description provided for @vol.
  ///
  /// In en, this message translates to:
  /// **'vol'**
  String get vol;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @chartBuyRecords.
  ///
  /// In en, this message translates to:
  /// **'Buy Records'**
  String get chartBuyRecords;

  /// No description provided for @chartSellRecords.
  ///
  /// In en, this message translates to:
  /// **'Sell Records'**
  String get chartSellRecords;

  /// No description provided for @chartPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get chartPrice;

  /// No description provided for @chartMarketCap.
  ///
  /// In en, this message translates to:
  /// **'MCap'**
  String get chartMarketCap;

  /// No description provided for @chartAvgBuyLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg Buy Price'**
  String get chartAvgBuyLabel;

  /// No description provided for @chartAvgSellLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg Sell Price'**
  String get chartAvgSellLabel;

  /// No description provided for @chartAvgBuyMarketCapLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg Buy MCap'**
  String get chartAvgBuyMarketCapLabel;

  /// No description provided for @chartAvgSellMarketCapLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg Sell MCap'**
  String get chartAvgSellMarketCapLabel;

  /// No description provided for @chartDataDisplay.
  ///
  /// In en, this message translates to:
  /// **'Data display'**
  String get chartDataDisplay;

  /// No description provided for @chartSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get chartSettingsSection;

  /// No description provided for @chartTradeDisplay.
  ///
  /// In en, this message translates to:
  /// **'Trade display'**
  String get chartTradeDisplay;

  /// No description provided for @chartHeight.
  ///
  /// In en, this message translates to:
  /// **'Chart height'**
  String get chartHeight;

  /// No description provided for @chartBuySellPrice.
  ///
  /// In en, this message translates to:
  /// **'Trade markers'**
  String get chartBuySellPrice;

  /// No description provided for @chartBuySellAveragePrice.
  ///
  /// In en, this message translates to:
  /// **'Avg. trade price'**
  String get chartBuySellAveragePrice;

  /// No description provided for @chartCandlestickOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'* These settings only apply to candlestick charts'**
  String get chartCandlestickOnlyHint;

  /// No description provided for @chartRiseFallColor.
  ///
  /// In en, this message translates to:
  /// **'Rise/fall colors'**
  String get chartRiseFallColor;

  /// No description provided for @chartRiseColor.
  ///
  /// In en, this message translates to:
  /// **'Rise'**
  String get chartRiseColor;

  /// No description provided for @chartFallColor.
  ///
  /// In en, this message translates to:
  /// **'Fall'**
  String get chartFallColor;

  /// No description provided for @indicatorSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Indicators'**
  String get indicatorSettingsTitle;

  /// No description provided for @chartSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Chart Settings'**
  String get chartSettingsTitle;

  /// No description provided for @chartTimeSettings.
  ///
  /// In en, this message translates to:
  /// **'Time settings'**
  String get chartTimeSettings;

  /// No description provided for @chartCustomTimeframes.
  ///
  /// In en, this message translates to:
  /// **'Custom timeframes'**
  String get chartCustomTimeframes;

  /// No description provided for @chartTimeframes.
  ///
  /// In en, this message translates to:
  /// **'Timeframes'**
  String get chartTimeframes;

  /// No description provided for @chartEditTimeframes.
  ///
  /// In en, this message translates to:
  /// **'Edit timeframes'**
  String get chartEditTimeframes;

  /// No description provided for @chartTimeframesAdded.
  ///
  /// In en, this message translates to:
  /// **'{count}/{max} added'**
  String chartTimeframesAdded(Object count, Object max);

  /// No description provided for @chartTimeframeMaxToast.
  ///
  /// In en, this message translates to:
  /// **'You can only add up to 5 timeframes.'**
  String get chartTimeframeMaxToast;

  /// No description provided for @chartTypeToggle.
  ///
  /// In en, this message translates to:
  /// **'Toggle chart type'**
  String get chartTypeToggle;

  /// No description provided for @indicatorMainChart.
  ///
  /// In en, this message translates to:
  /// **'Main chart'**
  String get indicatorMainChart;

  /// No description provided for @indicatorSecondaryChart.
  ///
  /// In en, this message translates to:
  /// **'Secondary chart'**
  String get indicatorSecondaryChart;

  /// No description provided for @settingSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingSave;

  /// No description provided for @chartFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Full screen chart'**
  String get chartFullscreen;

  /// No description provided for @chartShareKline.
  ///
  /// In en, this message translates to:
  /// **'Share K-line'**
  String get chartShareKline;

  /// No description provided for @chartShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to capture chart. Please try again.'**
  String get chartShareFailed;

  /// No description provided for @chartCloseFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Close full screen'**
  String get chartCloseFullscreen;

  /// No description provided for @chartHolderCount.
  ///
  /// In en, this message translates to:
  /// **'Holders'**
  String get chartHolderCount;

  /// No description provided for @chartClosePortraitFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Exit full screen'**
  String get chartClosePortraitFullscreen;

  /// No description provided for @chartPreferPortraitFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Portrait fullscreen chart'**
  String get chartPreferPortraitFullscreen;

  /// No description provided for @chartSwitchToLandscapeFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Switch to landscape fullscreen'**
  String get chartSwitchToLandscapeFullscreen;

  /// No description provided for @chartExitFullscreenCorner.
  ///
  /// In en, this message translates to:
  /// **'Exit fullscreen'**
  String get chartExitFullscreenCorner;

  /// No description provided for @chartPriceScaleAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto-scale price axis'**
  String get chartPriceScaleAuto;

  /// No description provided for @chartNoCandles.
  ///
  /// In en, this message translates to:
  /// **'No candlestick data'**
  String get chartNoCandles;

  /// No description provided for @chartDrawingCategoryLines.
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get chartDrawingCategoryLines;

  /// No description provided for @chartDrawingCategoryWaves.
  ///
  /// In en, this message translates to:
  /// **'Waves'**
  String get chartDrawingCategoryWaves;

  /// No description provided for @chartDrawingCategoryShapes.
  ///
  /// In en, this message translates to:
  /// **'Shapes'**
  String get chartDrawingCategoryShapes;

  /// No description provided for @chartDrawingCategoryFibonacci.
  ///
  /// In en, this message translates to:
  /// **'Fibonacci'**
  String get chartDrawingCategoryFibonacci;

  /// No description provided for @chartDrawingCategoryBrush.
  ///
  /// In en, this message translates to:
  /// **'Brush'**
  String get chartDrawingCategoryBrush;

  /// No description provided for @chartDrawingCategoryText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get chartDrawingCategoryText;

  /// No description provided for @chartDrawingErase.
  ///
  /// In en, this message translates to:
  /// **'Erase drawings'**
  String get chartDrawingErase;

  /// No description provided for @chartDrawingExit.
  ///
  /// In en, this message translates to:
  /// **'Exit drawing mode'**
  String get chartDrawingExit;

  /// No description provided for @chartDrawingTools.
  ///
  /// In en, this message translates to:
  /// **'Drawing tools'**
  String get chartDrawingTools;

  /// No description provided for @chartDrawingSnap.
  ///
  /// In en, this message translates to:
  /// **'Snap'**
  String get chartDrawingSnap;

  /// No description provided for @chartDrawingContinuous.
  ///
  /// In en, this message translates to:
  /// **'Continuous drawing'**
  String get chartDrawingContinuous;

  /// No description provided for @chartDrawingHide.
  ///
  /// In en, this message translates to:
  /// **'Hide drawings'**
  String get chartDrawingHide;

  /// No description provided for @chartDrawingShow.
  ///
  /// In en, this message translates to:
  /// **'Show drawings'**
  String get chartDrawingShow;

  /// No description provided for @chartDrawingUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get chartDrawingUndo;

  /// No description provided for @chartDrawingRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get chartDrawingRedo;

  /// No description provided for @chartDrawingClear.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get chartDrawingClear;

  /// No description provided for @chartDrawingClearConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Clear all drawings for this token?'**
  String get chartDrawingClearConfirmation;

  /// No description provided for @chartDrawingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get chartDrawingConfirm;

  /// No description provided for @chartDrawingCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get chartDrawingCompleted;

  /// No description provided for @chartDrawingInvalidGeometry.
  ///
  /// In en, this message translates to:
  /// **'Adjust the last point'**
  String get chartDrawingInvalidGeometry;

  /// No description provided for @chartDrawingStatistics.
  ///
  /// In en, this message translates to:
  /// **'Range statistics'**
  String get chartDrawingStatistics;

  /// No description provided for @chartDrawingExitStatistics.
  ///
  /// In en, this message translates to:
  /// **'Close statistics'**
  String get chartDrawingExitStatistics;

  /// No description provided for @chartDrawingLock.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get chartDrawingLock;

  /// No description provided for @chartDrawingUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get chartDrawingUnlock;

  /// No description provided for @chartDrawingDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get chartDrawingDelete;

  /// No description provided for @chartDrawingColor.
  ///
  /// In en, this message translates to:
  /// **'Border color'**
  String get chartDrawingColor;

  /// No description provided for @chartDrawingFill.
  ///
  /// In en, this message translates to:
  /// **'Fill color'**
  String get chartDrawingFill;

  /// No description provided for @chartDrawingNoFill.
  ///
  /// In en, this message translates to:
  /// **'No fill'**
  String get chartDrawingNoFill;

  /// No description provided for @chartDrawingWidth.
  ///
  /// In en, this message translates to:
  /// **'Line width'**
  String get chartDrawingWidth;

  /// No description provided for @chartDrawingLineStyle.
  ///
  /// In en, this message translates to:
  /// **'Line style'**
  String get chartDrawingLineStyle;

  /// No description provided for @chartDrawingExtend.
  ///
  /// In en, this message translates to:
  /// **'Extend'**
  String get chartDrawingExtend;

  /// No description provided for @chartDrawingReverse.
  ///
  /// In en, this message translates to:
  /// **'Reverse'**
  String get chartDrawingReverse;

  /// No description provided for @chartDrawingShowPrice.
  ///
  /// In en, this message translates to:
  /// **'Price label'**
  String get chartDrawingShowPrice;

  /// No description provided for @chartDrawingCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get chartDrawingCancel;

  /// No description provided for @chartDrawingPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get chartDrawingPrice;

  /// No description provided for @chartDrawingMarketCap.
  ///
  /// In en, this message translates to:
  /// **'Market cap'**
  String get chartDrawingMarketCap;

  /// No description provided for @chartDrawingTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get chartDrawingTime;

  /// No description provided for @chartDrawingCount.
  ///
  /// In en, this message translates to:
  /// **'Periods'**
  String get chartDrawingCount;

  /// No description provided for @chartDrawingStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get chartDrawingStart;

  /// No description provided for @chartDrawingEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get chartDrawingEnd;

  /// No description provided for @chartDrawingHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get chartDrawingHigh;

  /// No description provided for @chartDrawingLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get chartDrawingLow;

  /// No description provided for @chartDrawingChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get chartDrawingChange;

  /// No description provided for @chartDrawingVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get chartDrawingVolume;

  /// No description provided for @chartDrawingAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get chartDrawingAmount;

  /// No description provided for @chartDrawingIncludesUnclosed.
  ///
  /// In en, this message translates to:
  /// **'Includes unclosed candle'**
  String get chartDrawingIncludesUnclosed;

  /// No description provided for @chartDrawingDrag.
  ///
  /// In en, this message translates to:
  /// **'Move toolbar'**
  String get chartDrawingDrag;

  /// No description provided for @chartDrawingTrendLine.
  ///
  /// In en, this message translates to:
  /// **'Trend line'**
  String get chartDrawingTrendLine;

  /// No description provided for @chartDrawingExtendedLine.
  ///
  /// In en, this message translates to:
  /// **'Extended trend line'**
  String get chartDrawingExtendedLine;

  /// No description provided for @chartDrawingRay.
  ///
  /// In en, this message translates to:
  /// **'Ray'**
  String get chartDrawingRay;

  /// No description provided for @chartDrawingHorizontalLine.
  ///
  /// In en, this message translates to:
  /// **'Horizontal line'**
  String get chartDrawingHorizontalLine;

  /// No description provided for @chartDrawingVerticalLine.
  ///
  /// In en, this message translates to:
  /// **'Vertical line'**
  String get chartDrawingVerticalLine;

  /// No description provided for @chartDrawingParallelChannel.
  ///
  /// In en, this message translates to:
  /// **'Track lines'**
  String get chartDrawingParallelChannel;

  /// No description provided for @chartDrawingPriceLine.
  ///
  /// In en, this message translates to:
  /// **'Price line'**
  String get chartDrawingPriceLine;

  /// No description provided for @chartDrawingSelected.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get chartDrawingSelected;

  /// No description provided for @chartDrawingPlacePoints.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Place 1 point to finish} other{Place {count} points to finish}}'**
  String chartDrawingPlacePoints(int count);

  /// No description provided for @chartDrawingFreehandHint.
  ///
  /// In en, this message translates to:
  /// **'Drag on the chart to draw'**
  String get chartDrawingFreehandHint;

  /// No description provided for @chartDrawingEraseOnNotice.
  ///
  /// In en, this message translates to:
  /// **'Eraser on'**
  String get chartDrawingEraseOnNotice;

  /// No description provided for @chartDrawingEraseOffNotice.
  ///
  /// In en, this message translates to:
  /// **'Eraser off'**
  String get chartDrawingEraseOffNotice;

  /// No description provided for @chartDrawingHiddenNotice.
  ///
  /// In en, this message translates to:
  /// **'Hide drawings'**
  String get chartDrawingHiddenNotice;

  /// No description provided for @chartDrawingShownNotice.
  ///
  /// In en, this message translates to:
  /// **'Show drawings'**
  String get chartDrawingShownNotice;

  /// No description provided for @chartDrawingStatisticsNotice.
  ///
  /// In en, this message translates to:
  /// **'Entered range statistics mode'**
  String get chartDrawingStatisticsNotice;

  /// No description provided for @chartDrawingSnapOnNotice.
  ///
  /// In en, this message translates to:
  /// **'Snap on'**
  String get chartDrawingSnapOnNotice;

  /// No description provided for @chartDrawingSnapOffNotice.
  ///
  /// In en, this message translates to:
  /// **'Snap off'**
  String get chartDrawingSnapOffNotice;

  /// No description provided for @chartDrawingContinuousOnNotice.
  ///
  /// In en, this message translates to:
  /// **'Continuous drawing on'**
  String get chartDrawingContinuousOnNotice;

  /// No description provided for @chartDrawingContinuousOffNotice.
  ///
  /// In en, this message translates to:
  /// **'Continuous drawing off'**
  String get chartDrawingContinuousOffNotice;

  /// No description provided for @chartDrawingTextPlacementHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the chart where the text should go'**
  String get chartDrawingTextPlacementHint;

  /// No description provided for @chartDrawingFontSize.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get chartDrawingFontSize;

  /// No description provided for @chartDrawingBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get chartDrawingBold;

  /// No description provided for @chartDrawingItalic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get chartDrawingItalic;

  /// No description provided for @chartDrawingTextBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get chartDrawingTextBackground;

  /// No description provided for @chartDrawingNoBackground.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get chartDrawingNoBackground;

  /// No description provided for @chartDrawingRectangle.
  ///
  /// In en, this message translates to:
  /// **'Rectangle'**
  String get chartDrawingRectangle;

  /// No description provided for @chartDrawingFibonacci.
  ///
  /// In en, this message translates to:
  /// **'Fibonacci retracement'**
  String get chartDrawingFibonacci;

  /// No description provided for @chartDrawingThreeWave.
  ///
  /// In en, this message translates to:
  /// **'Three wave'**
  String get chartDrawingThreeWave;

  /// No description provided for @chartDrawingFiveWave.
  ///
  /// In en, this message translates to:
  /// **'Five wave'**
  String get chartDrawingFiveWave;

  /// No description provided for @chartDrawingBrush.
  ///
  /// In en, this message translates to:
  /// **'Brush'**
  String get chartDrawingBrush;

  /// No description provided for @chartDrawingText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get chartDrawingText;

  /// No description provided for @chartDrawingTextHint.
  ///
  /// In en, this message translates to:
  /// **'Enter text'**
  String get chartDrawingTextHint;

  /// No description provided for @chartDrawingSolid.
  ///
  /// In en, this message translates to:
  /// **'Solid'**
  String get chartDrawingSolid;

  /// No description provided for @chartDrawingDashed.
  ///
  /// In en, this message translates to:
  /// **'Dashed'**
  String get chartDrawingDashed;

  /// No description provided for @chartDrawingDotted.
  ///
  /// In en, this message translates to:
  /// **'Dotted'**
  String get chartDrawingDotted;

  /// No description provided for @chartDrawingSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Drawings could not be saved. Your edits remain available; retry saving.'**
  String get chartDrawingSaveFailed;

  /// No description provided for @chartDrawingHiddenPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Drawings are hidden'**
  String get chartDrawingHiddenPromptTitle;

  /// No description provided for @chartDrawingHiddenPromptBody.
  ///
  /// In en, this message translates to:
  /// **'\"Hide drawings\" is on, so anything you draw now won\'t be visible. Show drawings and continue?'**
  String get chartDrawingHiddenPromptBody;

  /// No description provided for @chartDrawingHiddenPromptDontShowAgain.
  ///
  /// In en, this message translates to:
  /// **'Don\'t show again'**
  String get chartDrawingHiddenPromptDontShowAgain;

  /// No description provided for @chartDrawingHiddenPromptConfirm.
  ///
  /// In en, this message translates to:
  /// **'Show & continue'**
  String get chartDrawingHiddenPromptConfirm;

  /// No description provided for @chartDrawingHiddenPromptCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get chartDrawingHiddenPromptCancel;

  /// No description provided for @chartDrawingShownToast.
  ///
  /// In en, this message translates to:
  /// **'Drawings shown'**
  String get chartDrawingShownToast;

  /// No description provided for @chartIndicatorInvalidTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Candle timestamp unavailable'**
  String get chartIndicatorInvalidTimestamp;

  /// No description provided for @chartIndicatorIntervalUnknown.
  ///
  /// In en, this message translates to:
  /// **'Candle interval unavailable'**
  String get chartIndicatorIntervalUnknown;

  /// No description provided for @chartIndicatorIntradayOnly.
  ///
  /// In en, this message translates to:
  /// **'Available on intraday intervals only'**
  String get chartIndicatorIntradayOnly;

  /// No description provided for @chartIndicatorIncompleteUtcSession.
  ///
  /// In en, this message translates to:
  /// **'Complete history from UTC 00:00 required'**
  String get chartIndicatorIncompleteUtcSession;

  /// No description provided for @chartIndicatorInvalidVolumeOrPrice.
  ///
  /// In en, this message translates to:
  /// **'Reliable volume and price required'**
  String get chartIndicatorInvalidVolumeOrPrice;

  /// No description provided for @chartIndicatorZeroCumulativeVolume.
  ///
  /// In en, this message translates to:
  /// **'No cumulative session volume'**
  String get chartIndicatorZeroCumulativeVolume;

  /// No description provided for @chartIndicatorEstimatedAverage.
  ///
  /// In en, this message translates to:
  /// **'Based on K-line estimates'**
  String get chartIndicatorEstimatedAverage;

  /// No description provided for @chartIndicatorQuoteBaseAverage.
  ///
  /// In en, this message translates to:
  /// **'Quote amount / base volume'**
  String get chartIndicatorQuoteBaseAverage;

  /// No description provided for @chartIndicatorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Indicator unavailable'**
  String get chartIndicatorUnavailable;

  /// No description provided for @chartDrawingMeasure.
  ///
  /// In en, this message translates to:
  /// **'Measure / price range'**
  String get chartDrawingMeasure;

  /// No description provided for @chartDrawingMeasureDuration.
  ///
  /// In en, this message translates to:
  /// **'{duration}'**
  String chartDrawingMeasureDuration(String duration);
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'zh':
      return SZh();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
