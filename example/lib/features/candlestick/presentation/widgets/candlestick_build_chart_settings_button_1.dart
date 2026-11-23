part of 'candlestick.dart';

extension _AIGunCandlestickStateBuildChartSettingsButton1
    on _AIGunCandlestickState {
  /// 打开图表设置底部弹窗，切换市值/价格展示维度与叠加层显示。
  Widget _buildChartSettingsButton(BuildContext context) {
    return Semantics(
      button: true,
      label: S.of(context).chartSettingsTitle,
      child: GestureDetector(
        key: const Key('candlestick-chart-settings'),
        onTap: () => showChartSettingsBottomSheet(
          context: context,
          currentValueType: _valueType,
          supportsMarketCap: _validMcapFactor != null,
          showTradeMarkers: _showTradeMarkers,
          showAvgPriceLines: _showAvgPriceLines,
          preferPortraitFullscreen: _preferPortraitFullscreen,
          chartHeightScale: _chartHeightScale,
          showChartHeightSetting:
              !widget.isLandscape && !widget.isPortraitFullscreen,
          riseColor: _riseColor,
          fallColor: _fallColor,
          riseCandleBodyStyle: _riseCandleBodyStyle,
          fallCandleBodyStyle: _fallCandleBodyStyle,
          // 点选立即生效，弹窗保持打开由用户关闭
          onSelected: (type) {
            _updateView(() => _valueType = type);
            _persistDisplaySettings();
          },
          onShowTradeMarkersChanged: (value) {
            _updateView(() => _showTradeMarkers = value);
            _persistDisplaySettings();
          },
          onShowAvgPriceLinesChanged: (value) {
            _updateView(() => _showAvgPriceLines = value);
            _persistDisplaySettings();
          },
          onPreferPortraitFullscreenChanged: (value) {
            _updateView(() => _preferPortraitFullscreen = value);
            _persistDisplaySettings();
          },
          onChartHeightScaleChanged: (value) {
            _updateView(() => _chartHeightScale = value);
            _persistDisplaySettings();
          },
          onRiseColorChanged: (value) {
            _updateView(() => _riseColor = value);
            _persistDisplaySettings();
          },
          onFallColorChanged: (value) {
            _updateView(() => _fallColor = value);
            _persistDisplaySettings();
          },
          onRiseCandleBodyStyleChanged: (value) {
            _updateView(() => _riseCandleBodyStyle = value);
            _persistDisplaySettings();
          },
          onFallCandleBodyStyleChanged: (value) {
            _updateView(() => _fallCandleBodyStyle = value);
            _persistDisplaySettings();
          },
        ),
        child: Container(
          padding: EdgeInsets.all(
            widget.isLandscape || widget.isPortraitFullscreen
                ? KlineButtonMetrics.landscapePadding
                : KlineButtonMetrics.padding,
          ),
          child: Icon(
            LucideIcons.slidersHorizontal,
            size: widget.isLandscape || widget.isPortraitFullscreen
                ? KlineButtonMetrics.landscapeIconSize
                : KlineButtonMetrics.iconSize,
            color: AppColors.textSecondary(context),
          ),
        ),
      ),
    );
  }

  Widget _buildChartTypeToggle(BuildContext context) {
    return Semantics(
      button: true,
      label: S.of(context).chartTypeToggle,
      child: GestureDetector(
        key: const Key('candlestick-type-toggle'),
        onTap: () {
          _updateView(() => _isTrendLine = !_isTrendLine);
          _persistDisplaySettings();
        },
        child: Container(
          // 工具图标只保留内边距扩大点击区，不铺圆形底色。
          padding: EdgeInsets.all(
            (widget.isLandscape || widget.isPortraitFullscreen)
                ? KlineButtonMetrics.landscapePadding
                : KlineButtonMetrics.padding,
          ),
          child: Icon(
            _isTrendLine
                ? LucideIcons.alignHorizontalDistributeCenter
                : LucideIcons.chartLine,
            size: (widget.isLandscape || widget.isPortraitFullscreen)
                ? KlineButtonMetrics.landscapeIconSize
                : KlineButtonMetrics.iconSize,
            color: AppColors.textSecondary(context),
          ),
        ),
      ),
    );
  }
}
