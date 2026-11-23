# CandleX

CandleX is a Flutter package for interactive financial charts. It includes the candlestick chart renderer and a standalone iOS and Android demo based on AIGun's chart interface. The demo replays local BTC/USD sample data.

## Run the mobile demo

From the repository root, start an iOS simulator or Android emulator, or connect a phone. Use the device ID listed by `flutter devices`.

```sh
cd example
flutter pub get
flutter devices
flutter run -d DEVICE_ID
```

The mobile demo was verified with Flutter 3.47.5. Use JDK 21 for the Android build with the included Gradle 8.14 wrapper.

- **Timeframes and indicators** — Open the timeframe menu to choose among 15 intervals from 30 seconds to 3 months or edit the shortcuts. Use the indicator bar to toggle overlays and lower panels, or open indicator settings to select several at once.
- **Chart settings** — Switch between candlesticks and a line chart, display prices or market cap, and adjust chart height, candle colors, and filled or hollow candle bodies. Toggle buy and sell markers and average-price lines independently, and open trade history from the selected candle's details.
- **Fullscreen and drawing** — Use the button in the lower-left corner of the chart to open landscape fullscreen. Enable portrait fullscreen in chart settings to open in portrait. Both views support drawing tools, range statistics, undo and redo, and screenshot sharing or saving to Photos. Drawings and chart preferences are saved on the device.
- **Simulated orders** — Tap the crosshair price label to open a simulated limit order with the selected price filled in.

## Use the chart package

Add the local checkout to your Flutter app's `pubspec.yaml`. Adjust the path relative to that file.

```yaml
dependencies:
  candlestick:
    path: ../candlex
```

Supply `KLineEntity` candles in chronological order, oldest first, with timestamps in Unix milliseconds. Populate open, high, low, close, and volume. Run `IndicatorCalculator.calculate(candles)` when you load or update the series so the selected indicators have values to render.

```dart
import 'package:candlestick/candlestick.dart';
import 'package:flutter/widgets.dart';

Widget buildPriceChart(List<KLineEntity> candles) {
  return SizedBox(
    height: 420,
    child: CandlestickWidget(
      candles,
      ChartStyle(),
      ChartColors(),
      isTrendLine: false,
      isTapShowInfoDialog: true,
      mBaseHeight: 300,
      mainStateLi: const {MainState.MA},
      secondaryStateLi: const {SecondaryState.MACD},
    ),
  );
}
```

The widget supports drag-to-pan, pinch-to-zoom, crosshair inspection, and price-axis scaling. Set `isLine` for a line chart, supply `onReachBoundary` to load more candles, or attach a `ChartDrawingController` to enable drawing. `DepthChart` is available for order book visualization.

## Repository layout

| Path | Contents |
| --- | --- |
| [`lib/candlestick.dart`](lib/candlestick.dart) | Package entry point and public exports |
| [`lib/renderer/`](lib/renderer/) | Candlestick, volume, indicator, and overlay rendering |
| [`lib/indicators/`](lib/indicators/) | Indicator calculation and presentation |
| [`lib/drawing/`](lib/drawing/) | Drawing tools, editing, and measurements |
| [`example/`](example/) | Mobile demo, sample market data, local preferences, and interaction tests |

## Acknowledgments

CandleX builds on OpenFlutter's [k_chart](https://github.com/OpenFlutter/k_chart). The current chart implementation and mobile interface were ported from AIGun.
