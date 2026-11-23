import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/enums/timeframe.dart';
import '../../../../../demo_market.dart';
import '../selection/selection_params_cubit.dart';
import 'candlestick_state.dart';

/// Supplies the copied chart UI with an offline playback of the sample market.
class CandlestickCubit extends Cubit<CandlestickState> {
  CandlestickCubit(SelectionParamsCubit selection, {required bool autoplay})
    : _autoplay = autoplay,
      _timeframe = selection.state.selectedTimeframe,
      super(CandlestickState(const [], const [])) {
    refresh();
    _selection = selection.stream.listen((state) {
      if (state.selectedTimeframe == _timeframe) return;
      _timeframe = state.selectedTimeframe;
      refresh();
    });
    startPolling();
  }

  final bool _autoplay;
  final _markets = <Timeframe, DemoMarket>{};
  late final StreamSubscription<Object?> _selection;
  Timer? _timer;
  Timeframe _timeframe;
  int _start = 0;
  int _end = 0;

  DemoMarket get _market =>
      _markets.putIfAbsent(_timeframe, () => DemoMarket(_timeframe));

  void _publish() {
    final data = _market.candles.sublist(_start, _end);
    final latest = data.last.time!;
    emit(
      CandlestickState(data, [
        for (final trade in _market.trades)
          if (trade.time <= latest) trade,
      ]),
    );
  }

  void refresh() {
    _end = DemoMarket.firstLiveIndex + 1;
    _start = max(0, _end - max(120, _timeframe.defaultDataCount));
    _publish();
  }

  void loadMore() {
    if (_start == 0) return;
    _start = max(0, _start - 120);
    _publish();
  }

  void startPolling() {
    if (!_autoplay || _timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_end == _market.candles.length) return;
      _end++;
      _publish();
    });
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> close() async {
    stopPolling();
    await _selection.cancel();
    await super.close();
  }
}
