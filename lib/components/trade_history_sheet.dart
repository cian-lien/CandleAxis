part of 'popup_info_view.dart';

class _TradeHistorySheet extends StatefulWidget {
  const _TradeHistorySheet({
    required this.info,
    required this.label,
    required this.title,
    required this.accentColor,
    required this.trades,
  });

  final PopupInfoView info;
  final String label;
  final String title;
  final Color accentColor;
  final List<TradeMarkerEntity> trades;

  @override
  State<_TradeHistorySheet> createState() => _TradeHistorySheetState();
}

class _TradeHistorySheetState extends State<_TradeHistorySheet> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final colors = info.chartColors;
    final textColor = colors.infoWindowNormalColor;
    final muted = colors.infoWindowTitleColor;
    final trades = [...widget.trades]..sort((a, b) => b.time.compareTo(a.time));
    final days = <DateTime, List<TradeMarkerEntity>>{};
    for (final trade in trades) {
      final date = DateTime.fromMillisecondsSinceEpoch(trade.time);
      days
          .putIfAbsent(DateTime(date.year, date.month, date.day), () => [])
          .add(trade);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: muted.withValues(alpha: .3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  key: const Key('trade-history-title'),
                  TextSpan(children: [
                    if (widget.title.startsWith(widget.label)) ...[
                      TextSpan(
                          text: widget.label,
                          style: TextStyle(color: widget.accentColor)),
                      TextSpan(
                          text: widget.title.substring(widget.label.length)),
                    ] else
                      TextSpan(text: widget.title),
                    TextSpan(
                      text: ' (${trades.length})',
                      style: TextStyle(
                          color: muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w400),
                    ),
                  ]),
                  style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                key: const Key('trade-history-close'),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: Icon(Icons.close, color: muted, size: 22),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Divider(
              height: 16, thickness: .5, color: muted.withValues(alpha: .25)),
          Flexible(
            child: Scrollbar(
              controller: _scrollController,
              child: CustomScrollView(
                key: const Key('trade-history-list'),
                controller: _scrollController,
                shrinkWrap: true,
                slivers: [
                  for (final day in days.keys)
                    SliverMainAxisGroup(slivers: [
                      _dateHeader(context, day, muted),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _entry(context, days[day]![index],
                              hasPrevious: index > 0,
                              connects: index < days[day]!.length - 1),
                          childCount: days[day]!.length,
                        ),
                      ),
                    ]),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateHeader(BuildContext context, DateTime day, Color muted) {
    final label = MaterialLocalizations.of(context)
        .formatFullDate(day)
        .replaceFirstMapped(
            RegExp(r'(?<!\s)(星期|週|周)'), (match) => ' ${match[0]}');
    final style = DefaultTextStyle.of(context).style.merge(TextStyle(
          color: muted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ));
    return SliverLayoutBuilder(builder: (context, constraints) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: constraints.crossAxisExtent);
      final height = painter.height + 22;
      painter.dispose();
      return SliverPersistentHeader(
        pinned: true,
        delegate: _TradeDateHeader(
          height: height,
          child: ColoredBox(
            color: widget.info.chartColors.bgColor,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 18),
              child: Text(
                label,
                key: Key('trade-history-date-${dateFormat(day, const [
                      yyyy,
                      '-',
                      mm,
                      '-',
                      dd
                    ])}'),
                style: style,
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _entry(BuildContext context, TradeMarkerEntity trade,
      {required bool hasPrevious, required bool connects}) {
    final info = widget.info;
    final color = info.chartColors.infoWindowNormalColor;
    final muted = info.chartColors.infoWindowTitleColor;
    final time = dateFormat(DateTime.fromMillisecondsSinceEpoch(trade.time),
        const [HH, ':', nn, ':', ss]);
    final timeStyle = DefaultTextStyle.of(context).style.merge(TextStyle(
        color: color, fontSize: 13, height: 1.4, fontWeight: FontWeight.w600));
    final timeWidth = TextPainter.computeWidth(
      text: TextSpan(text: '00:00:00', style: timeStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    );
    final amount = trade.amount.trim();
    final symbol = info.tokenSymbol.trim();
    final quantity =
        amount.isEmpty ? '-' : '$amount${symbol.isEmpty ? '' : ' $symbol'}';
    return Stack(
      children: [
        if (hasPrevious || connects)
          Positioned.directional(
            textDirection: Directionality.of(context),
            start: timeWidth + 15.5,
            top: hasPrevious ? 0 : 9,
            bottom: connects ? 0 : null,
            height: connects ? null : 9,
            child: ColoredBox(
              key: const Key('trade-history-connector'),
              color: muted.withValues(alpha: .25),
              child: const SizedBox(width: 1),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                  width: timeWidth,
                  child: Text(time,
                      key: const Key('trade-history-time'),
                      maxLines: 1,
                      softWrap: false,
                      style: timeStyle)),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                child: DecoratedBox(
                  key: const Key('trade-history-dot'),
                  decoration: BoxDecoration(
                      color: widget.accentColor, shape: BoxShape.circle),
                  child: const SizedBox.square(dimension: 8),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(quantity,
                        style: TextStyle(
                            color: color,
                            fontSize: 15,
                            height: 1.3,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    _detail(info.chartTranslations.tradeHistoryValue,
                        _usd(trade.usdValue), muted, color),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 16,
                      runSpacing: 6,
                      children: [
                        _detail(info.chartTranslations.tradeHistoryPrice,
                            info._formatExecutionPrice(trade), muted, color),
                        if (info.valueType == ChartValueType.marketCap)
                          _detail(info.chartTranslations.tradeHistoryMarketCap,
                              info._formatTradePrice(trade), muted, color),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detail(String label, String value, Color muted, Color color) => Wrap(
        spacing: 6,
        runSpacing: 2,
        children: [
          Text(label,
              style: TextStyle(color: muted, fontSize: 12, height: 1.4)),
          Text(value,
              style: TextStyle(color: color, fontSize: 12, height: 1.4)),
        ],
      );

  String _usd(double? value) {
    if (value == null || value < 0 || !value.isFinite) return '-';
    if (value > 0 && value < .01) return '< \$0.01';
    return widget.info.usdFormatter?.call(value) ??
        '\$${value.toStringAsFixed(widget.info.fixedLength)}';
  }
}

/// Limit each pinned date to its own day group so the next date pushes it away.
class _TradeDateHeader extends SliverPersistentHeaderDelegate {
  const _TradeDateHeader({required this.height, required this.child});
  final double height;
  final Widget child;
  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox.expand(child: child);
  @override
  bool shouldRebuild(_TradeDateHeader oldDelegate) =>
      height != oldDelegate.height || child != oldDelegate.child;
}
