import '../entity/k_line_entity.dart';
import '../entity/trade_marker_entity.dart';

class InfoWindowEntity {
  InfoWindowEntity(
    this.kLineEntity, {
    this.isLeft = false,
    this.trades = const [],
  });
  KLineEntity kLineEntity;
  bool isLeft;

  /// 落在该蜡烛区间内的成交点，供浮窗展示买卖明细。
  List<TradeMarkerEntity> trades;
}
