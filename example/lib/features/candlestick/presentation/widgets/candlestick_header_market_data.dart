part of 'candlestick.dart';

/// Measured-range statistics shown below both fullscreen headers.
extension _AIGunHeaderMarketData on _AIGunCandlestickState {
  /// 是否存在完整的统计区间。
  bool get _headerMeasuring {
    final controller = _drawingController!;
    return controller.mode == DrawingMode.statistics &&
        controller.rangeStart != null &&
        controller.rangeEnd != null;
  }

  /// Range measurements remain separate from the token's live 24h metrics.
  List<List<(String, String)>> _headerRangeData(
    BuildContext context,
    List<KLineEntity> entities,
  ) {
    final l10n = S.of(context);
    final controller = _drawingController!;
    final statistics = DrawingRangeStatistics.calculate(
      entities,
      controller.rangeStart!,
      controller.rangeEnd!,
      reliableQuoteAmount: (candle) => candle.amount,
    );
    final locale = Localizations.localeOf(context).toLanguageTag();
    String value(double? raw) {
      if (raw == null || !raw.isFinite) return '--';
      return _effectiveValueType == ChartValueType.marketCap
          ? marketCapFormatter(locale)(raw * _validMcapFactor!)
          : formatAmount(raw);
    }

    String quantity(double? raw) => raw == null || !raw.isFinite
        ? '--'
        : formatCompactAmount(raw, locale: locale);
    final change = statistics.changePercent;
    return [
      [
        (l10n.opening, value(statistics.startValue)),
        (l10n.closing, value(statistics.endValue)),
      ],
      [
        (l10n.chartDrawingCount, '${statistics.count}'),
        (
          l10n.change,
          change == null
              ? '--'
              : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
        ),
      ],
      [(l10n.high, value(statistics.high)), (l10n.low, value(statistics.low))],
      [
        (l10n.chartDrawingVolume, quantity(statistics.volume)),
        (l10n.chartDrawingAmount, quantity(statistics.amount)),
      ],
    ];
  }

  /// Compact measured-range statistics; tap to inspect every field.
  Widget _buildRangeStatistics(
    BuildContext context,
    CandlestickState candles, {
    bool compact = false,
  }) => ListenableBuilder(
    listenable: _drawingController!,
    builder: (context, _) {
      final entities = candles.kLineEntities;
      final groups = _headerRangeData(context, entities);
      final labelStyle = TextStyle(
        fontSize: compact ? 11 : 13,
        height: compact ? 1.3 : 1.5,
        color: AppColors.textTertiary(context),
      );
      final valueStyle = TextStyle(
        fontSize: 13,
        height: compact ? 1.3 : 1.5,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary(context),
      );
      Widget cell((String, String) item) => Row(
        mainAxisSize: .min,
        children: [
          Text(item.$1, maxLines: 1, style: labelStyle),
          SizedBox(width: compact ? 6 : 4),
          Text(item.$2, maxLines: 1, style: valueStyle),
        ],
      );
      return Container(
        key: const Key('candlestick-range-statistics'),
        margin: const EdgeInsets.only(top: 8),
        padding: EdgeInsets.only(top: 8, bottom: compact ? 10 : 0),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.borderSecondary(context)),
            bottom: compact
                ? BorderSide(color: AppColors.borderSecondary(context))
                : BorderSide.none,
          ),
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showPortraitMarketDataSheet(context, groups),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Narrow headers drop turnover first; whatever
              // still does not fit scrolls horizontally instead of reaching the X.
              final columns = [
                for (final (index, group) in groups.indexed)
                  index == groups.length - 1 && constraints.maxWidth < 260
                      ? group.take(1).toList()
                      : group,
              ];
              return _MarketDataHorizontalFade(
                child: SingleChildScrollView(
                  scrollDirection: .horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: compact ? constraints.maxWidth : 0,
                    ),
                    child: Row(
                      mainAxisAlignment: .spaceBetween,
                      crossAxisAlignment: .start,
                      children: [
                        for (final (index, column) in columns.indexed) ...[
                          if (index > 0) SizedBox(width: compact ? 24 : 10),
                          Column(
                            crossAxisAlignment: .start,
                            mainAxisSize: .min,
                            children: [
                              for (final (row, item) in column.indexed) ...[
                                if (compact && row > 0)
                                  const SizedBox(height: 6),
                                cell(item),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    },
  );

  /// Full list of header metrics so nothing is clipped by the compact scroll row.
  void _showPortraitMarketDataSheet(
    BuildContext context,
    List<List<(String, String)>> groups,
  ) {
    final l10n = S.of(context);
    final items = [for (final group in groups) ...group];
    final title = l10n.chartDrawingStatistics;
    showCutCornerSheet<void>(
      context,
      useRootNavigator: true,
      barrierColor: AppColors.modalBarrier(context),
      builder: (sheetContext) {
        const fontSize = 16.0;
        final labelStyle = TextStyle(
          fontSize: fontSize,
          height: 1.4,
          color: AppColors.textTertiary(sheetContext),
        );
        final valueStyle = TextStyle(
          fontSize: fontSize,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary(sheetContext),
        );
        return CutCornerSheet(
          key: const Key('candlestick-market-data-detail-sheet'),
          backgroundColor: AppColors.background(sheetContext),
          corners: const {CutCornerPosition.topRight},
          cutSize: 18,
          maxHeightFactor: 0.7,
          title: title,
          titleStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(sheetContext),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          bodyPadding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          body: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (index, item) in items.indexed) ...[
                  if (index > 0)
                    Divider(
                      height: 1,
                      color: AppColors.borderSecondary(sheetContext),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      key: Key('candlestick-market-data-detail-row-$index'),
                      children: [
                        Expanded(child: Text(item.$1, style: labelStyle)),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            item.$2,
                            textAlign: TextAlign.end,
                            style: valueStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 竖屏头部行情横向滚动的右侧渐隐遮罩：还有内容可往右滚时，
/// 在右缘叠一层背景色→透明的渐变；滚到尽头则隐藏。
class _MarketDataHorizontalFade extends StatefulWidget {
  const _MarketDataHorizontalFade({required this.child});

  final Widget child;

  @override
  State<_MarketDataHorizontalFade> createState() =>
      _MarketDataHorizontalFadeState();
}

class _MarketDataHorizontalFadeState extends State<_MarketDataHorizontalFade> {
  static const double _fadeExtent = 18;

  /// 0 = 已到尽头（无遮罩），1 = 仍有足够溢出可滚。
  double _rightFade = 0;

  bool _onMetrics(ScrollMetrics metrics) {
    if (metrics.axis != Axis.horizontal) return false;
    // Soften as the remaining overflow shrinks; hide once past the end.
    final next = metrics.extentAfter <= 0.5
        ? 0.0
        : (metrics.extentAfter / _fadeExtent).clamp(0.0, 1.0);
    if ((next - _rightFade).abs() > 0.01) setState(() => _rightFade = next);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final background = AppColors.background(context);
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => _onMetrics(n.metrics),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => _onMetrics(n.metrics),
        child: Stack(
          children: [
            widget.child,
            if (_rightFade > 0)
              Positioned(
                key: const Key('candlestick-market-data-fade-right'),
                top: 0,
                right: 0,
                bottom: 0,
                width: _fadeExtent,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: _rightFade,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [background.withValues(alpha: 0), background],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
