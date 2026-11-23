import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:candle_axis/candle_axis.dart';

part 'history_candlestick_state.freezed.dart';

@freezed
sealed class HistoryCandlestickStatus with _$HistoryCandlestickStatus {
  const factory HistoryCandlestickStatus.initial() = _HistoryCandlestickInitial;
  const factory HistoryCandlestickStatus.loading() = _HistoryCandlestickLoading;
  const factory HistoryCandlestickStatus.success(
    List<KLineEntity> candles,
  ) = _HistoryCandlestickSuccess;
  const factory HistoryCandlestickStatus.error(String message) =
      _HistoryCandlestickError;
}
