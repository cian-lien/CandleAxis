import 'package:flutter/material.dart';

import '../chart_style.dart';
import '../chart_translations.dart';
import '../chart_types.dart';
import '../entity/k_line_entity.dart';
import '../entity/trade_marker_entity.dart';
import '../utils/date_format_util.dart';
import '../utils/number_util.dart';

part 'trade_history_sheet.dart';

class PopupInfoView extends StatelessWidget {
  const PopupInfoView({
    super.key,
    required this.entity,
    required this.width,
    required this.chartColors,
    required this.chartStyle,
    required this.chartTranslations,
    required this.materialInfoDialog,
    required this.timeFormat,
    required this.fixedLength,
    this.priceFormatter,
    this.valueType = ChartValueType.price,
    this.mcapFactor = 1.0,
    this.mcapFormatter,
    this.amountFormatter,
    this.popupValueFormatters,
    this.trades = const [],
    this.tokenSymbol = '',
    this.usdFormatter,
    this.tradeHistorySheetBuilder,
  });
  final KLineEntity entity;

  /// Available popup width; content is kept between 120 and 200 logical pixels.
  final double width;
  final ChartColors chartColors;
  final ChartStyle chartStyle;
  final ChartTranslations chartTranslations;
  final bool materialInfoDialog;
  final List<String> timeFormat;
  final int fixedLength;
  final PriceFormatter? priceFormatter;
  final ChartValueType valueType;
  final double mcapFactor;
  final PriceFormatter? mcapFormatter;
  final PriceFormatter? amountFormatter;
  final PopupValueFormatters? popupValueFormatters;

  /// 落在该蜡烛上的买卖点明细，随浮窗一起展示（不再单独绘制在图表上）。
  final List<TradeMarkerEntity> trades;
  final String tokenSymbol;
  final PriceFormatter? usdFormatter;
  final Future<void> Function(BuildContext context, Widget content)?
      tradeHistorySheetBuilder;
  String formatPrice(double price, {bool popup = false}) {
    final formatMcap =
        (popup ? popupValueFormatters?.marketCap : null) ?? mcapFormatter;
    if (valueType == ChartValueType.marketCap) {
      final mcapValue = price * mcapFactor;
      if (formatMcap != null) return formatMcap(mcapValue);
      if (priceFormatter != null) return priceFormatter!(mcapValue);
      return mcapValue.toStringAsFixed(fixedLength);
    }
    if (priceFormatter != null) return priceFormatter!(price);
    return price.toStringAsFixed(fixedLength);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minWidth: 120,
        maxWidth: width.clamp(120.0, 200.0),
      ),
      padding: chartStyle.popupPadding,
      decoration: BoxDecoration(
        color: chartColors.selectFillColor,
        border: chartStyle.popupBorderWidth > 0
            ? Border.all(
                color: chartColors.selectBorderColor,
                width: chartStyle.popupBorderWidth,
              )
            : null,
        borderRadius: chartStyle.popupBorderRadius > 0
            ? BorderRadius.circular(chartStyle.popupBorderRadius)
            : null,
      ),
      child: IntrinsicWidth(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    double upDown = entity.change ?? entity.close - entity.open;
    double upDownPercent = entity.ratio ?? (upDown / entity.open) * 100;
    final double? entityAmount = entity.amount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildItem(chartTranslations.date, getDate(entity.time)),
        _buildItem(chartTranslations.open, formatPrice(entity.open)),
        _buildItem(chartTranslations.high, formatPrice(entity.high)),
        _buildItem(chartTranslations.low, formatPrice(entity.low)),
        _buildItem(chartTranslations.close, formatPrice(entity.close)),
        _buildColorItem(
            chartTranslations.changeAmount, formatPrice(upDown), upDown > 0),
        _buildColorItem(chartTranslations.change,
            '${upDownPercent.toStringAsFixed(2)}%', upDownPercent > 0),
        _buildItem(
          chartTranslations.vol,
          amountFormatter?.call(entity.vol) ??
              priceFormatter?.call(entity.vol) ??
              NumberUtil.format(entity.vol),
        ),
        if (entityAmount != null)
          _buildItem(
            chartTranslations.amount,
            amountFormatter?.call(entityAmount) ??
                priceFormatter?.call(entityAmount) ??
                NumberUtil.format(entityAmount),
          ),
        ..._buildTradeItems(context),
      ],
    );
  }

  List<Widget> _buildTradeItems(BuildContext context) {
    final buyTrades = trades
        .where((trade) => trade.side == TradeMarkerSide.buy)
        .toList(growable: false);
    final sellTrades = trades
        .where((trade) => trade.side == TradeMarkerSide.sell)
        .toList(growable: false);
    return [
      if (buyTrades.isNotEmpty)
        _buildTradeItem(
          context,
          _TradeGroup(side: TradeMarkerSide.buy, trades: buyTrades),
          additionalCount: buyTrades.length - 1,
        ),
      if (sellTrades.isNotEmpty)
        _buildTradeItem(
          context,
          _TradeGroup(side: TradeMarkerSide.sell, trades: sellTrades),
          additionalCount: sellTrades.length - 1,
        ),
    ];
  }

  /// 每个方向展示一笔，后缀标明同方向未展示的笔数。
  Widget _buildTradeItem(
    BuildContext context,
    _TradeGroup group, {
    int additionalCount = 0,
  }) {
    final trade = group.trades.first;
    final isBuy = group.side == TradeMarkerSide.buy;
    final label = isBuy ? chartTranslations.buy : chartTranslations.sell;
    final amount = (trade.popupAmount ?? trade.amount).trim();
    final price = _formatTradePrice(trade, popup: true);
    final value = amount.isEmpty ? price : '@$price';
    final count = additionalCount > 0 ? ' $additionalCount+' : '';
    final row = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showTradeHistorySheet(context, group),
      child: Padding(
        padding: EdgeInsets.only(bottom: chartStyle.popupItemSpacing),
        child: Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                      color: chartColors.infoWindowNormalColor,
                      fontSize: chartStyle.popupValueFontSize,
                    ),
                    children: [
                      TextSpan(
                        text: '$label$amount',
                        style: TextStyle(
                          color: isBuy
                              ? chartColors.infoWindowUpColor
                              : chartColors.infoWindowDnColor,
                        ),
                      ),
                      TextSpan(text: '$value$count'),
                    ],
                  ),
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: chartStyle.popupValueFontSize + 4,
              color: chartColors.infoWindowTitleColor,
            ),
          ],
        ),
      ),
    );
    return materialInfoDialog
        ? Material(color: Colors.transparent, child: row)
        : row;
  }

  String _formatExecutionPrice(TradeMarkerEntity trade, {bool popup = false}) {
    // Execution prices are always USD, regardless of the chart dimension.
    if (priceFormatter != null) return '\$${priceFormatter!(trade.price)}';
    final formatUsd =
        (popup ? popupValueFormatters?.usd : null) ?? usdFormatter;
    if (formatUsd != null) return formatUsd(trade.price);
    return '\$${trade.price.toStringAsFixed(fixedLength)}';
  }

  String _formatTradePrice(TradeMarkerEntity trade, {bool popup = false}) {
    final formatUsd =
        (popup ? popupValueFormatters?.usd : null) ?? usdFormatter;
    final formatMcap =
        (popup ? popupValueFormatters?.marketCap : null) ?? mcapFormatter;
    if (valueType == ChartValueType.marketCap) {
      final marketCap = trade.marketCap;
      if (marketCap != null && marketCap > 0 && marketCap.isFinite) {
        if (formatUsd != null) return formatUsd(marketCap);
        if (formatMcap != null) return formatMcap(marketCap);
        if (priceFormatter != null) return priceFormatter!(marketCap);
        return marketCap.toStringAsFixed(fixedLength);
      }
    }
    return valueType == ChartValueType.price
        ? _formatExecutionPrice(trade, popup: popup)
        : formatPrice(trade.price, popup: popup);
  }

  Future<void> _showTradeHistorySheet(
    BuildContext context,
    _TradeGroup group,
  ) {
    final isBuy = group.side == TradeMarkerSide.buy;
    final label = isBuy
        ? chartTranslations.buyHistoryLabel ?? chartTranslations.buy
        : chartTranslations.sellHistoryLabel ?? chartTranslations.sell;
    final accentColor =
        isBuy ? chartColors.infoWindowUpColor : chartColors.infoWindowDnColor;

    final content = _TradeHistorySheet(
      info: this,
      label: label,
      title: (isBuy
              ? chartTranslations.buyHistory
              : chartTranslations.sellHistory) ??
          '$label ${chartTranslations.tradeHistory}',
      accentColor: accentColor,
      trades: group.trades,
    );
    final showSheet = tradeHistorySheetBuilder;
    if (showSheet != null) return showSheet(context, content);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
        ),
        child: SafeArea(child: content),
      ),
    );
  }

  Widget _buildColorItem(String label, String info, bool isUp) {
    if (isUp) {
      return _buildItem(label, '+$info',
          textColor: chartColors.infoWindowUpColor);
    }
    return _buildItem(label, info, textColor: chartColors.infoWindowDnColor);
  }

  Widget _buildItem(
    String label,
    String info, {
    Color? textColor,
  }) {
    final infoWidget = Padding(
      padding: EdgeInsets.only(bottom: chartStyle.popupItemSpacing),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: chartColors.infoWindowTitleColor,
              fontSize: chartStyle.popupTitleFontSize,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              info,
              style: TextStyle(
                color: textColor ?? chartColors.infoWindowNormalColor,
                fontSize: chartStyle.popupValueFontSize,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
    return materialInfoDialog
        ? Material(color: Colors.transparent, child: infoWidget)
        : infoWidget;
  }

  String getDate(int? date) => dateFormat(
        DateTime.fromMillisecondsSinceEpoch(
            date ?? DateTime.now().millisecondsSinceEpoch),
        timeFormat,
      );
}

class _TradeGroup {
  const _TradeGroup({required this.side, required this.trades});

  final TradeMarkerSide side;
  final List<TradeMarkerEntity> trades;
}
