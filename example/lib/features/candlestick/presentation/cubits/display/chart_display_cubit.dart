import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../infrastructure/datasource/candlestick_settings_storage.dart';
import 'chart_display_state.dart';

/// 一次图表会话持有，横屏页面借用，不创建第二份偏好。
class ChartDisplayCubit extends Cubit<ChartDisplayState> {
  ChartDisplayCubit(this.storage)
    : super(
        ChartDisplayState(
          settings:
              storage?.displaySettings ?? CandlestickDisplaySettings.defaults(),
        ),
      );

  final CandlestickSettingsStorage? storage;

  void update(CandlestickDisplaySettings settings) {
    emit(state.copyWith(settings: settings));
    if (storage != null) unawaited(storage!.saveDisplaySettings(settings));
  }
}
