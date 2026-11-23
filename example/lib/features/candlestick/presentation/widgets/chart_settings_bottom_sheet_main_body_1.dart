part of 'chart_settings_bottom_sheet.dart';

extension _ChartSettingsBottomSheetStateMainBody1
    on _ChartSettingsBottomSheetState {
  Widget _mainBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _fadingContent(
          key: _ChartSettingsBottomSheetState._nonHeightContentVisibilityKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.supportsMarketCap) ...[
                _sectionTitle(context, S.of(context).chartDataDisplay),
                SizedBox(height: 10.sheetH(context)),
                Row(
                  children: [
                    Expanded(
                      child: _segment(
                        context,
                        ChartValueType.price,
                        S.of(context).chartPrice,
                      ),
                    ),
                    SizedBox(width: 10.sheetW(context)),
                    Expanded(
                      child: _segment(
                        context,
                        ChartValueType.marketCap,
                        S.of(context).chartMarketCap,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 22.sheetH(context)),
              ],
              _sectionTitle(context, S.of(context).chartSettingsSection),
              SizedBox(height: 16.sheetH(context)),
              _settingsRow(
                context,
                label: S.of(context).chartRiseFallColor,
                onTap: () =>
                    _updateView(() => _page = _ChartSettingsPage.riseFallColor),
              ),
              SizedBox(height: 18.sheetH(context)),
              _settingsRow(
                context,
                label: S.of(context).chartTradeDisplay,
                onTap: () =>
                    _updateView(() => _page = _ChartSettingsPage.tradeDisplay),
              ),
              SizedBox(height: 18.sheetH(context)),
              _switchRow(
                context,
                label: S.of(context).chartPreferPortraitFullscreen,
                value: _preferPortraitFullscreen,
                onChanged: (value) {
                  _updateView(() => _preferPortraitFullscreen = value);
                  widget.onPreferPortraitFullscreenChanged(value);
                },
              ),
              if (widget.showChartHeightSetting)
                SizedBox(height: 22.sheetH(context)),
            ],
          ),
        ),
        if (widget.showChartHeightSetting) ...[
          _fadingContent(
            key: _ChartSettingsBottomSheetState._heightTitleVisibilityKey,
            child: Text(
              S.of(context).chartHeight,
              style: _sectionTitleStyle(context),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: SizedBox(
              height: _isAdjustingChartHeight ? 0 : 10.sheetH(context),
            ),
          ),
          AnimatedContainer(
            width: double.infinity,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(
              horizontal: 8.sheetW(context),
              vertical: 4.sheetH(context),
            ),
            decoration: BoxDecoration(
              color: _isAdjustingChartHeight
                  ? AppColors.card(context)
                  : AppColors.transparent,
              borderRadius: BorderRadius.circular(18.sheetR(context)),
              boxShadow: _isAdjustingChartHeight
                  ? [
                      BoxShadow(
                        color: AppColors.shadow(context),
                        blurRadius: 18,
                        offset: Offset(0, 6.sheetH(context)),
                      ),
                    ]
                  : const [],
            ),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.borderSecondary(context),
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withValues(alpha: 0.12),
                trackHeight: 4.sheetH(context),
              ),
              child: Slider(
                key: _ChartSettingsBottomSheetState._heightSliderKey,
                value: _chartHeightScale,
                min: 0.8,
                max: 1.25,
                padding: EdgeInsets.zero,
                onChangeStart: (_) {
                  _updateView(() => _isAdjustingChartHeight = true);
                  widget.onChartHeightAdjustmentChanged(true);
                },
                onChanged: (value) {
                  _updateView(() => _chartHeightScale = value);
                  widget.onChartHeightScaleChanged(value);
                },
                onChangeEnd: (_) {
                  _updateView(() => _isAdjustingChartHeight = false);
                  widget.onChartHeightAdjustmentChanged(false);
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
