import '../chart_types.dart';
import '../entity/k_line_entity.dart';
import 'indicator_values.dart';

class IndicatorSeries {
  const IndicatorSeries(this.label, this.value,
      {this.unit = IndicatorUnit.price, this.offset = 0});
  final String label;
  final double? value;
  final IndicatorUnit unit;
  final int offset;
  double? displayValue(ChartValueType type, double factor) => value == null
      ? null
      : unit == IndicatorUnit.price &&
              type == ChartValueType.marketCap &&
              factor.isFinite &&
              factor > 0
          ? value! * factor
          : value;
}

List<IndicatorSeries> mainIndicatorSeries(MainState state, KLineEntity c,
    {List<int> maPeriods = const [5, 10, 20]}) {
  switch (state) {
    case MainState.MA:
      return [
        for (var i = 0; i < maPeriods.length; i++)
          IndicatorSeries(
              'MA${maPeriods[i]}',
              c.maValueList != null &&
                      i < c.maValueList!.length &&
                      c.maValueList![i] != 0
                  ? c.maValueList![i]
                  : null)
      ];
    case MainState.BOLL:
      return [
        IndicatorSeries('BOLL(20,2)', c.mb),
        IndicatorSeries('UB', c.up),
        IndicatorSeries('LB', c.dn)
      ];
    case MainState.SAR:
      return [IndicatorSeries('SAR(0.02,0.02,0.2)', c.sar)];
    default:
      return [for (final line in _mainLines[state]!) _typed(line, c)];
  }
}

const _mainLines = {
  MainState.EMA: [IndicatorLine.ema5, IndicatorLine.ema10, IndicatorLine.ema20],
  MainState.AVL: [IndicatorLine.avl],
  MainState.RESIST: [IndicatorLine.resistance, IndicatorLine.support],
  MainState.SUPER: [IndicatorLine.superTrend],
  MainState.VWAP: [IndicatorLine.vwap],
  MainState.ICHI: [
    IndicatorLine.tenkan,
    IndicatorLine.kijun,
    IndicatorLine.senkouA,
    IndicatorLine.senkouB,
    IndicatorLine.chikou
  ],
};

/// Numeric access for paint/extrema loops; labels are only built for headers.
int mainIndicatorLineCount(MainState state, {int maCount = 3}) =>
    switch (state) {
      MainState.MA => maCount,
      MainState.BOLL => 3,
      MainState.SAR => 1,
      _ => _mainLines[state]!.length,
    };

double? mainIndicatorValue(MainState state, KLineEntity candle, int line) {
  if (state == MainState.MA) {
    final values = candle.maValueList;
    final value = values != null && line < values.length ? values[line] : null;
    return value == 0 ? null : value;
  }
  return switch (state) {
    MainState.BOLL => switch (line) {
        0 => candle.mb,
        1 => candle.up,
        _ => candle.dn,
      },
    MainState.SAR => candle.sar,
    _ => candle.indicators[_mainLines[state]![line]],
  };
}

int mainIndicatorOffset(MainState state, int line) =>
    state == MainState.ICHI ? _mainLines[state]![line].offset : 0;

double? mainIndicatorValueAt(
    MainState state, int position, List<KLineEntity> candles, int line) {
  if (position < 0 || position >= candles.length) return null;
  final source = position - mainIndicatorOffset(state, line);
  if (source < 0 || source >= candles.length) return null;
  return mainIndicatorValue(state, candles[source], line);
}

List<IndicatorSeries> secondaryIndicatorSeries(
    SecondaryState state, KLineEntity c) {
  switch (state) {
    case SecondaryState.MACD:
      return [
        IndicatorSeries('MACD(12,26,9)×2', c.macd),
        IndicatorSeries('DIF', c.dif),
        IndicatorSeries('DEA', c.dea)
      ];
    case SecondaryState.KDJ:
      return [
        IndicatorSeries('K(9,3,3)', c.k, unit: IndicatorUnit.oscillator),
        IndicatorSeries('D', c.d, unit: IndicatorUnit.oscillator),
        IndicatorSeries('J', c.j, unit: IndicatorUnit.oscillator)
      ];
    case SecondaryState.RSI:
      return [
        IndicatorSeries('RSI(14)', c.rsi, unit: IndicatorUnit.oscillator)
      ];
    case SecondaryState.WR:
      return [IndicatorSeries('WR(14)', c.r, unit: IndicatorUnit.oscillator)];
    case SecondaryState.CCI:
      return [
        IndicatorSeries('CCI(14)', c.cci, unit: IndicatorUnit.oscillator)
      ];
    default:
      return [for (final line in _secondaryLines[state]!) _typed(line, c)];
  }
}

const _secondaryLines = {
  SecondaryState.ROC: [IndicatorLine.roc, IndicatorLine.rocMa],
  SecondaryState.OBV: [IndicatorLine.obv],
  SecondaryState.StochRSI: [IndicatorLine.stochK, IndicatorLine.stochD],
  SecondaryState.MFI: [IndicatorLine.mfi],
  SecondaryState.DMI: [
    IndicatorLine.pdi,
    IndicatorLine.mdi,
    IndicatorLine.adx,
    IndicatorLine.adxr
  ],
  SecondaryState.DMA: [IndicatorLine.dma, IndicatorLine.ama],
  SecondaryState.MTM: [IndicatorLine.mtm, IndicatorLine.mtmMa],
  SecondaryState.EMV: [IndicatorLine.emv, IndicatorLine.emvMa],
};

// Paint/extrema loops need only numbers, not freshly allocated labels and units
// for every candle in every panel.
int secondaryIndicatorLineCount(SecondaryState state) => switch (state) {
      SecondaryState.MACD || SecondaryState.KDJ => 3,
      SecondaryState.RSI || SecondaryState.WR || SecondaryState.CCI => 1,
      _ => _secondaryLines[state]!.length,
    };

double? secondaryIndicatorValue(
        SecondaryState state, KLineEntity candle, int line) =>
    switch (state) {
      SecondaryState.MACD => switch (line) {
          0 => candle.macd,
          1 => candle.dif,
          _ => candle.dea,
        },
      SecondaryState.KDJ => switch (line) {
          0 => candle.k,
          1 => candle.d,
          _ => candle.j,
        },
      SecondaryState.RSI => candle.rsi,
      SecondaryState.WR => candle.r,
      SecondaryState.CCI => candle.cci,
      _ => candle.indicators[_secondaryLines[state]![line]],
    };

IndicatorSeries _typed(IndicatorLine line, KLineEntity c) => IndicatorSeries(
    (line == IndicatorLine.vwap || line == IndicatorLine.avl) &&
            !c.indicators.sessionAverageEstimated
        ? '${line.name.toUpperCase()} UTC (quote/base)'
        : _labels[line]!,
    c.indicators[line],
    unit: line.unit,
    offset: line.offset);
const _labels = {
  IndicatorLine.ema5: 'EMA5',
  IndicatorLine.ema10: 'EMA10',
  IndicatorLine.ema20: 'EMA20',
  IndicatorLine.avl: 'AVL UTC (K-line estimate)',
  IndicatorLine.vwap: 'VWAP UTC (K-line estimate)',
  IndicatorLine.resistance: 'Resistance',
  IndicatorLine.support: 'Support',
  IndicatorLine.superTrend: 'SuperTrend(10,3.0)',
  IndicatorLine.tenkan: 'Tenkan(9)',
  IndicatorLine.kijun: 'Kijun(26)',
  IndicatorLine.senkouA: 'Span A (+26)',
  IndicatorLine.senkouB: 'Span B(52,+26)',
  IndicatorLine.chikou: 'Chikou (-26)',
  IndicatorLine.roc: 'ROC(12)%',
  IndicatorLine.rocMa: 'MA(6)%',
  IndicatorLine.obv: 'OBV (loaded history)',
  IndicatorLine.stochK: 'StochRSI K(14,14,3,3)',
  IndicatorLine.stochD: 'D',
  IndicatorLine.mfi: 'MFI(14)',
  IndicatorLine.pdi: 'PDI(14,6)',
  IndicatorLine.mdi: 'MDI',
  IndicatorLine.adx: 'ADX',
  IndicatorLine.adxr: 'ADXR',
  IndicatorLine.dma: 'DMA(10,50)',
  IndicatorLine.ama: 'AMA(10)',
  IndicatorLine.mtm: 'MTM(12)',
  IndicatorLine.mtmMa: 'MA(6)',
  IndicatorLine.emv: 'EMV(14) P²/V',
  IndicatorLine.emvMa: 'MA(9)',
};

/// Values at a chart position; source offsets do not insert market candles.
List<IndicatorSeries> mainIndicatorSeriesAt(
    MainState state, int position, List<KLineEntity> candles,
    {List<int> maPeriods = const [5, 10, 20]}) {
  if (position < 0 || position >= candles.length) return const [];
  final raw =
      mainIndicatorSeries(state, candles[position], maPeriods: maPeriods);
  if (state != MainState.ICHI) return raw;
  return [
    for (var i = 0; i < raw.length; i++)
      if (raw[i].offset == 0)
        raw[i]
      else
        IndicatorSeries(
            raw[i].label,
            position - raw[i].offset < 0 ||
                    position - raw[i].offset >= candles.length
                ? null
                : mainIndicatorSeries(state, candles[position - raw[i].offset],
                        maPeriods: maPeriods)[i]
                    .value,
            unit: raw[i].unit,
            offset: raw[i].offset)
  ];
}

String indicatorUnavailableText(String reason) => switch (reason) {
      'invalidTimestamp' => 'Candle timestamp unavailable',
      'intervalUnknown' => 'Candle interval unavailable',
      'intradayOnly' => 'Available on intraday intervals only',
      'incompleteUtcSession' => 'Complete history from UTC 00:00 required',
      'invalidVolumeOrPrice' => 'Reliable volume and price required',
      'zeroCumulativeVolume' => 'No cumulative session volume',
      _ => 'Indicator unavailable',
    };
