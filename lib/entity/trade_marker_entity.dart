/// 买入/卖出成交点，用于在 K 线上叠加标记。
///
/// 价格与 K 线蜡烛同一 Y 轴 domain（token 价格，非市值），[time] 需与
/// `KLineEntity.time` 同单位（毫秒）以便定位所属蜡烛。
enum TradeMarkerSide { buy, sell }

class TradeMarkerEntity {
  const TradeMarkerEntity({
    required this.time,
    required this.price,
    required this.side,
    required this.amount,
    this.popupAmount,
    this.marketCap,
    this.usdValue,
  });

  /// 成交时间，毫秒（与 KLineEntity.time 对齐）。
  final int time;

  /// 成交价格，与蜡烛同一价格 domain。
  final double price;

  final TradeMarkerSide side;

  /// 成交数量（已格式化的十进制字符串，仅用于浮窗展示，不参与计算）。
  final String amount;

  /// Optional quantity text used only in the crosshair popup.
  final String? popupAmount;

  /// 宿主根据历史成交价和固定流通供给计算出的成交时点市值。
  final double? marketCap;

  /// USD notional for this trade, used in the trade history sheet.
  final double? usdValue;
}
