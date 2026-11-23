import 'package:candlestick/candlestick.dart';

import '../../../../../core/enums/candle_source.dart';
import '../history/history_candlestick_state.dart';

class CandlestickState {
  CandlestickState(this.kLineEntities, this.trades)
    : status = HistoryCandlestickStatus.success(kLineEntities);

  final List<KLineEntity> kLineEntities;
  final List<TradeMarkerEntity> trades;
  final HistoryCandlestickStatus status;
  CandleSource get source => CandleSource.okx;
}
