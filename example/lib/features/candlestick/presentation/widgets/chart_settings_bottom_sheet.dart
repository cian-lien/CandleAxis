import 'dart:math' as math;

import 'package:candlestick/candlestick_widget.dart';
import 'package:candlestick/chart_style.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/presentation/widgets/button/cut_corner_button.dart';
import '../../../../shared/presentation/widgets/sheet/cut_corner_sheet.dart';
import '../../../../themes/colors.dart';
import 'chart_settings_sheet_header.dart';

part 'chart_settings_bottom_sheet_support_1.dart';
part 'chart_settings_color_picker.dart';

part 'chart_settings_bottom_sheet_main_body_1.dart';

const _sheetTextFontSize = 14.0;

/// Shows a bottom sheet to switch the chart value type (market cap / price).
/// 点选立即生效且弹窗保持打开，由用户下滑或点外部关闭。
void showChartSettingsBottomSheet({
  required BuildContext context,
  required ChartValueType currentValueType,
  required bool supportsMarketCap,
  required bool showTradeMarkers,
  required bool showAvgPriceLines,
  required bool preferPortraitFullscreen,
  required double chartHeightScale,
  bool showChartHeightSetting = true,
  required Color riseColor,
  required Color fallColor,
  required CandleBodyStyle riseCandleBodyStyle,
  required CandleBodyStyle fallCandleBodyStyle,
  required ValueChanged<ChartValueType> onSelected,
  required ValueChanged<bool> onShowTradeMarkersChanged,
  required ValueChanged<bool> onShowAvgPriceLinesChanged,
  required ValueChanged<bool> onPreferPortraitFullscreenChanged,
  required ValueChanged<double> onChartHeightScaleChanged,
  required ValueChanged<Color> onRiseColorChanged,
  required ValueChanged<Color> onFallColorChanged,
  required ValueChanged<CandleBodyStyle> onRiseCandleBodyStyleChanged,
  required ValueChanged<CandleBodyStyle> onFallCandleBodyStyleChanged,
}) {
  final modalBarrierColor = AppColors.modalBarrier(context);
  final barrierColorNotifier = ValueNotifier<Color?>(modalBarrierColor);

  showCutCornerSheet<void>(
    context,
    barrierColor: modalBarrierColor,
    barrierColorListenable: barrierColorNotifier,
    builder: (context) => _ChartSettingsBottomSheet(
      currentValueType: currentValueType,
      supportsMarketCap: supportsMarketCap,
      showTradeMarkers: showTradeMarkers,
      showAvgPriceLines: showAvgPriceLines,
      preferPortraitFullscreen: preferPortraitFullscreen,
      chartHeightScale: chartHeightScale,
      showChartHeightSetting: showChartHeightSetting,
      riseColor: riseColor,
      fallColor: fallColor,
      riseCandleBodyStyle: riseCandleBodyStyle,
      fallCandleBodyStyle: fallCandleBodyStyle,
      onSelected: onSelected,
      onShowTradeMarkersChanged: onShowTradeMarkersChanged,
      onShowAvgPriceLinesChanged: onShowAvgPriceLinesChanged,
      onPreferPortraitFullscreenChanged: onPreferPortraitFullscreenChanged,
      onChartHeightScaleChanged: onChartHeightScaleChanged,
      onRiseColorChanged: onRiseColorChanged,
      onFallColorChanged: onFallColorChanged,
      onRiseCandleBodyStyleChanged: onRiseCandleBodyStyleChanged,
      onFallCandleBodyStyleChanged: onFallCandleBodyStyleChanged,
      onChartHeightAdjustmentChanged: (isAdjusting) {
        barrierColorNotifier.value = isAdjusting
            ? AppColors.transparent
            : modalBarrierColor;
      },
    ),
  ).whenComplete(barrierColorNotifier.dispose);
}

enum _ChartSettingsPage { main, tradeDisplay, riseFallColor }

class _ChartSettingsBottomSheetState extends State<_ChartSettingsBottomSheet> {
  void _updateView(VoidCallback update) => setState(update);

  static const Key _titleVisibilityKey = Key('chart_settings_title_visibility');
  static const Key _nonHeightContentVisibilityKey = Key(
    'chart_settings_non_height_content_visibility',
  );
  static const Key _heightTitleVisibilityKey = Key(
    'chart_height_title_visibility',
  );
  static const Key _heightSliderKey = Key('chart_height_slider');

  _ChartSettingsPage _page = _ChartSettingsPage.main;
  late ChartValueType _selected = widget.currentValueType;
  late bool _showTradeMarkers = widget.showTradeMarkers;
  late bool _showAvgPriceLines = widget.showAvgPriceLines;
  late bool _preferPortraitFullscreen = widget.preferPortraitFullscreen;
  late double _chartHeightScale = widget.chartHeightScale.clamp(0.8, 1.25);
  late Color _riseColor = widget.riseColor;
  late Color _fallColor = widget.fallColor;
  late CandleBodyStyle _riseCandleBodyStyle = widget.riseCandleBodyStyle;
  late CandleBodyStyle _fallCandleBodyStyle = widget.fallCandleBodyStyle;
  bool _isAdjustingChartHeight = false;

  @override
  Widget build(BuildContext context) {
    return CutCornerSheet(
      backgroundColor: _isAdjustingChartHeight
          ? AppColors.transparent
          : AppColors.background(context),
      corners: const {CutCornerPosition.topRight},
      cutSize: 18,
      maxHeightFactor: 0.94,
      sectionSpacing: 18.sheetH(context),
      titleWidget: _fadingContent(
        key: _titleVisibilityKey,
        child: _title(context),
      ),
      titlePadding: EdgeInsets.fromLTRB(
        20.sheetW(context),
        22.sheetH(context),
        20.sheetW(context),
        0,
      ),
      bodyPadding: EdgeInsets.fromLTRB(
        20.sheetW(context),
        0,
        20.sheetW(context),
        32.sheetH(context),
      ),
      body: SingleChildScrollView(child: _body(context)),
    );
  }

  Widget _fadingContent({required Key key, required Widget child}) {
    return AnimatedOpacity(
      key: key,
      opacity: _isAdjustingChartHeight ? 0 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: child,
    );
  }

  Widget _title(BuildContext context) {
    final title = switch (_page) {
      _ChartSettingsPage.main => S.of(context).chartSettingsTitle,
      _ChartSettingsPage.tradeDisplay => S.of(context).chartTradeDisplay,
      _ChartSettingsPage.riseFallColor => S.of(context).chartRiseFallColor,
    };

    return ChartSettingsSheetHeader(
      title: title,
      onBack: _page == _ChartSettingsPage.main
          ? null
          : () => setState(() => _page = _ChartSettingsPage.main),
    );
  }

  Widget _body(BuildContext context) {
    return switch (_page) {
      _ChartSettingsPage.main => _mainBody(context),
      _ChartSettingsPage.tradeDisplay => _tradeDisplayBody(context),
      _ChartSettingsPage.riseFallColor => _riseFallColorBody(context),
    };
  }

  Widget _tradeDisplayBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _switchRow(
          context,
          label: S.of(context).chartBuySellPrice,
          value: _showTradeMarkers,
          onChanged: (value) {
            setState(() => _showTradeMarkers = value);
            widget.onShowTradeMarkersChanged(value);
          },
        ),
        SizedBox(height: 14.sheetH(context)),
        _switchRow(
          context,
          label: S.of(context).chartBuySellAveragePrice,
          value: _showAvgPriceLines,
          onChanged: (value) {
            setState(() => _showAvgPriceLines = value);
            widget.onShowAvgPriceLinesChanged(value);
          },
        ),
        SizedBox(height: 18.sheetH(context)),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            S.of(context).chartCandlestickOnlyHint,
            style: TextStyle(
              color: AppColors.textTertiary(context),
              fontSize: _sheetTextFontSize.sheetSp(context),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _riseFallColorBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _colorRow(
          context,
          label: S.of(context).chartRiseColor,
          value: _riseColor,
          bodyStyle: _riseCandleBodyStyle,
          onChanged: (value) {
            setState(() => _riseColor = value);
            widget.onRiseColorChanged(value);
          },
          onBodyStyleChanged: (value) {
            setState(() => _riseCandleBodyStyle = value);
            widget.onRiseCandleBodyStyleChanged(value);
          },
        ),
        SizedBox(height: 18.sheetH(context)),
        _colorRow(
          context,
          label: S.of(context).chartFallColor,
          value: _fallColor,
          bodyStyle: _fallCandleBodyStyle,
          onChanged: (value) {
            setState(() => _fallColor = value);
            widget.onFallColorChanged(value);
          },
          onBodyStyleChanged: (value) {
            setState(() => _fallCandleBodyStyle = value);
            widget.onFallCandleBodyStyleChanged(value);
          },
        ),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Text(text, style: _sectionTitleStyle(context));
  }

  TextStyle _sectionTitleStyle(BuildContext context) {
    return TextStyle(
      color: AppColors.textSecondary(context),
      fontSize: _sheetTextFontSize.sheetSp(context),
      fontWeight: FontWeight.w700,
    );
  }

  TextStyle _optionTextStyle(BuildContext context, {Color? color}) {
    return TextStyle(
      color: color,
      fontSize: _sheetTextFontSize.sheetSp(context),
      fontWeight: FontWeight.w400,
    );
  }

  Widget _settingsRow(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: _optionTextStyle(
                context,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 24.sheetSp(context),
            color: AppColors.textSecondary(context),
          ),
        ],
      ),
    );
  }

  Widget _switchRow(
    BuildContext context, {
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: _optionTextStyle(
              context,
              color: AppColors.textPrimary(context),
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.onPrimary,
          activeTrackColor: AppColors.primary,
          inactiveThumbColor: AppColors.onPrimary,
          inactiveTrackColor: AppColors.borderSecondary(context),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }

  Widget _segment(BuildContext context, ChartValueType type, String label) {
    final isSelected = type == _selected;
    return CutCornerButton(
      onPressed: () {
        setState(() => _selected = type);
        widget.onSelected(type);
      },
      corners: type == ChartValueType.price
          ? const {ButtonCorner.topLeft}
          : const {ButtonCorner.topRight},
      cutSize: 8,
      padding: EdgeInsets.symmetric(
        horizontal: 18.sheetW(context),
        vertical: 10.sheetH(context),
      ),
      backgroundColor: isSelected
          ? AppColors.primary.withValues(alpha: 0.1)
          : AppColors.background(context),
      foregroundColor: isSelected
          ? AppColors.primary
          : AppColors.textPrimary(context),
      side: BorderSide(
        color: isSelected
            ? AppColors.primary
            : AppColors.borderSecondary(context),
        width: isSelected ? 1.5 : 1,
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      child: Text(label, style: _optionTextStyle(context)),
    );
  }

  Widget _candleStyleToggle(
    BuildContext context, {
    required CandleBodyStyle value,
    required ValueChanged<CandleBodyStyle> onChanged,
  }) {
    return _CandleStyleToggle(value: value, onChanged: onChanged);
  }
}
