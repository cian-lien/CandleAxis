import 'dart:math';

import 'package:candle_axis/candle_axis.dart';

import 'core/enums/timeframe.dart';

class DemoMarket {
  DemoMarket(Timeframe timeframe) {
    final random = Random(23 + Timeframe.values.indexOf(timeframe));
    final intervalMs = timeframe.duration.inMilliseconds;
    final end = DateTime.utc(2026, 11, 23, 4).millisecondsSinceEpoch;
    final initialTime = end - end % intervalMs;
    var close = 64500.0;

    candles = List.generate(960, (index) {
      final open = close;
      final move =
          sin(index / 16) * 48 +
          sin(index / 5) * 32 +
          (random.nextDouble() - .49) * 330;
      close = open + move;
      final volume = 4 + random.nextDouble() * 25 + move.abs() / 7;
      return KLineEntity.fromCustom(
        time: initialTime + (index - firstLiveIndex) * intervalMs,
        open: open,
        high: max(open, close) + 8 + random.nextDouble() * 85,
        low: min(open, close) - 8 - random.nextDouble() * 70,
        close: close,
        vol: volume,
        amount: volume * (open + close) / 2,
        isClosed: true,
      );
    }, growable: false);
    IndicatorCalculator.calculate(
      candles,
      context: IndicatorContext(
        interval: timeframe.duration,
        lastCandleClosed: true,
        quoteAmountReliable: true,
      ),
    );

    trades = [
      _trade(34, TradeMarkerSide.buy, .035),
      _trade(21, TradeMarkerSide.sell, .029),
      _trade(13, TradeMarkerSide.buy, .054),
      _trade(6, TradeMarkerSide.sell, .017),
      _trade(-3, TradeMarkerSide.buy, .021),
      _trade(-8, TradeMarkerSide.sell, .023),
    ];
  }

  static const marketCapFactor = 20000000.0;
  static const firstLiveIndex = 935;

  late final List<KLineEntity> candles;
  late final List<TradeMarkerEntity> trades;

  TradeMarkerEntity _trade(int barsAgo, TradeMarkerSide side, double size) {
    final candle = candles[firstLiveIndex - barsAgo];
    return TradeMarkerEntity(
      time: candle.time!,
      price: candle.close,
      side: side,
      amount: size.toStringAsFixed(3),
      marketCap: candle.close * marketCapFactor,
      usdValue: candle.close * size,
    );
  }
}
