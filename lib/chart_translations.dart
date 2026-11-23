class ChartTranslations {
  const ChartTranslations({
    this.indicatorTextFormatter,
    this.date = 'Date',
    this.open = 'Open',
    this.high = 'High',
    this.low = 'Low',
    this.close = 'Close',
    this.changeAmount = 'Change',
    this.change = 'Change%',
    this.amount = 'Amount',
    this.vol = 'Volume',
    this.buy = 'Buy',
    this.sell = 'Sell',
    this.tradeHistory = 'Trade History',
    this.buyHistory,
    this.sellHistory,
    this.buyHistoryLabel,
    this.sellHistoryLabel,
    this.tradeHistoryTime = 'Time',
    this.tradeHistoryAmount = 'Amount',
    this.tradeHistoryValue = 'Trade Amount',
    this.tradeHistoryPrice = 'Price',
    this.tradeHistoryMarketCap = 'Market Cap',
  });
  final String Function(String)? indicatorTextFormatter;
  final String date;
  final String open;
  final String high;
  final String low;
  final String close;
  final String changeAmount;
  final String change;
  final String amount;
  final String vol;

  /// 买卖点浮窗明细的方向文案。
  final String buy;
  final String sell;

  /// 买卖点历史弹窗字段文案。
  final String tradeHistory;
  final String? buyHistory;
  final String? sellHistory;
  final String? buyHistoryLabel;
  final String? sellHistoryLabel;
  final String tradeHistoryTime;
  final String tradeHistoryAmount;
  final String tradeHistoryValue;
  final String tradeHistoryPrice;
  final String tradeHistoryMarketCap;
}

class DepthChartTranslations {
  const DepthChartTranslations({
    this.price = 'Price',
    this.amount = 'Amount',
  });
  final String price;
  final String amount;
}
