/// A line's unit controls display conversion; coordinates stay in raw values.
enum IndicatorUnit {
  price,
  percentage,
  oscillator,
  volume,
  priceSquaredPerVolume
}

enum IndicatorLine {
  ema5,
  ema10,
  ema20,
  avl,
  resistance,
  support,
  superTrend,
  vwap,
  tenkan,
  kijun,
  senkouA,
  senkouB,
  chikou,
  roc,
  rocMa,
  obv,
  stochK,
  stochD,
  mfi,
  pdi,
  mdi,
  adx,
  adxr,
  dma,
  ama,
  mtm,
  mtmMa,
  emv,
  emvMa;

  int get offset => switch (this) {
        senkouA || senkouB => 26,
        chikou => -26,
        _ => 0,
      };

  IndicatorUnit get unit => switch (this) {
        roc || rocMa => IndicatorUnit.percentage,
        obv => IndicatorUnit.volume,
        stochK ||
        stochD ||
        mfi ||
        pdi ||
        mdi ||
        adx ||
        adxr =>
          IndicatorUnit.oscillator,
        emv || emvMa => IndicatorUnit.priceSquaredPerVolume,
        _ => IndicatorUnit.price,
      };
}

/// Immutable computed values. Missing windows are absent, never synthetic zero.
class IndicatorValues {
  const IndicatorValues(this.values,
      {this.unavailableReason, this.sessionAverageEstimated = true});
  final Map<IndicatorLine, double?> values;

  /// Reason the UTC day average cannot be computed from this history.
  final String? unavailableReason;
  final bool sessionAverageEstimated;
  double? operator [](IndicatorLine line) => values[line];

  IndicatorValues snapshot() => IndicatorValues(Map.unmodifiable(values),
      unavailableReason: unavailableReason,
      sessionAverageEstimated: sessionAverageEstimated);

  static IndicatorValues lerp(IndicatorValues a, IndicatorValues b, double t) =>
      IndicatorValues(
          Map.unmodifiable({
            for (final line in IndicatorLine.values)
              line: a[line] == null || b[line] == null
                  ? b[line]
                  : a[line]! + (b[line]! - a[line]!) * t
          }),
          unavailableReason: b.unavailableReason,
          sessionAverageEstimated: b.sessionAverageEstimated);
}
