part of 'candlestick.dart';

extension _AIGunLandscapeHeader on _AIGunCandlestickState {
  Widget _buildLandscapeHeader(BuildContext context, CandlestickState candles) {
    return CandlestickTokenMarketHeader(
      key: const Key('candlestick-landscape-header'),
      compact: true,
      symbol: widget.tokenSymbol,
      latestPrice: candles.kLineEntities.lastOrNull?.close,
      statistics: _headerMeasuring
          ? _buildRangeStatistics(context, candles, compact: true)
          : null,
      actions: [
        IconButton(
          key: const Key('candlestick-share-kline'),
          style: KlineButtonMetrics.circleStyle,
          padding: EdgeInsets.zero,
          tooltip: S.of(context).chartShareKline,
          onPressed: () => KlineShareCapture.share(context),
          icon: Icon(
            LucideIcons.share2,
            size: KlineButtonMetrics.landscapeIconSize,
            color: AppColors.textSecondary(context),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: _landscapeRailWidth,
          child: Center(
            child: IconButton(
              key: const Key('candlestick-close-fullscreen'),
              style: KlineButtonMetrics.circleStyle,
              padding: EdgeInsets.zero,
              tooltip: S.of(context).chartCloseFullscreen,
              onPressed: () => LandscapeCandlestickPage.close(context),
              icon: Icon(
                LucideIcons.x,
                size: KlineButtonMetrics.landscapeCloseIconSize,
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
