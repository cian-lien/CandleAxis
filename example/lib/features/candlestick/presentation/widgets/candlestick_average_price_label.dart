part of 'candlestick.dart';

extension _AIGunAveragePriceLabel on _AIGunCandlestickState {
  /// 构建均价参考线的文字标签，价格为空或非正时不绘制标签（对应包内 null 处理）。
  ///
  /// 两行文案（标签 + 价格）交给渲染层的圆角徽标居中显示，故用换行符拼接。
  String? _avgPriceLabel(BuildContext context, String prefix, double? price) {
    if (price == null || price <= 0) return null;
    if (_effectiveValueType == ChartValueType.marketCap) {
      final mcap = price * (widget.mcapFactor ?? 1.0);
      final formatted = NumberFormatCore.marketCap(
        mcap,
        symbol: '',
        locale: Localizations.localeOf(context).toLanguageTag(),
      );
      return '$prefix\n$formatted';
    }
    return '$prefix\n${formatAmount(price)}';
  }
}
