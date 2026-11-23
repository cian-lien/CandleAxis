import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../infrastructure/datasource/candlestick_settings_storage.dart';

part 'chart_display_state.freezed.dart';

@freezed
sealed class ChartDisplayState with _$ChartDisplayState {
  const factory ChartDisplayState({
    required CandlestickDisplaySettings settings,
  }) = _ChartDisplayState;
}
