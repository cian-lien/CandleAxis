import 'package:candlestick/candlestick_widget.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/presentation/widgets/button/cut_corner_button.dart';
import '../../../../shared/presentation/widgets/sheet/cut_corner_sheet.dart';
import '../../../../themes/colors.dart';
import '../../infrastructure/datasource/candlestick_settings_storage.dart';
import '../cubit/selection/selection_params_state.dart';

const _sheetTitleFontSize = 18.0;
const _sheetTextFontSize = 14.0;
const _visibleMainIndicators = MainState.values;

Future<void> showIndicatorSettingsSheet(
  BuildContext context, {
  required SelectionParamsState selection,
  required void Function({
    required Set<MainState> mainStates,
    required Set<SecondaryState> secondaryStates,
    required bool volHidden,
    required List<String> secondaryOrder,
  })
  onSave,
}) {
  return showCutCornerSheet<void>(
    context,
    constraints: const BoxConstraints(
      minWidth: double.infinity,
      maxWidth: double.infinity,
    ),
    builder: (_) =>
        IndicatorSettingsSheet(selection: selection, onSave: onSave),
  );
}

class IndicatorSettingsSheet extends StatefulWidget {
  const IndicatorSettingsSheet({
    super.key,
    required this.selection,
    required this.onSave,
  });

  final SelectionParamsState selection;
  final void Function({
    required Set<MainState> mainStates,
    required Set<SecondaryState> secondaryStates,
    required bool volHidden,
    required List<String> secondaryOrder,
  })
  onSave;

  @override
  State<IndicatorSettingsSheet> createState() => _IndicatorSettingsSheetState();
}

class _IndicatorSettingsSheetState extends State<IndicatorSettingsSheet> {
  late Set<MainState> _mainStates;
  late Set<SecondaryState> _secondaryStates;
  late bool _volHidden;
  late List<String> _secondaryOrder;

  @override
  void initState() {
    super.initState();
    _restore(widget.selection);
  }

  void _restore(SelectionParamsState selection) {
    _mainStates = CandlestickSelectionSettings.limitIndicators(
      selection.mainStates.where(_visibleMainIndicators.contains),
      CandlestickSelectionSettings.maxMainIndicators,
    );
    _secondaryStates = selection.secondaryStates.toSet();
    _volHidden = selection.volHidden;
    _secondaryOrder = selection.secondaryOrder;
    _normalizeSecondary();
  }

  void _toggleMain(MainState indicator) {
    setState(() {
      if (!_mainStates.remove(indicator)) {
        _mainStates = CandlestickSelectionSettings.limitIndicators({
          ..._mainStates,
          indicator,
        }, CandlestickSelectionSettings.maxMainIndicators);
      }
    });
  }

  void _normalizeSecondary() {
    final selected = CandlestickSelectionSettings.normalizeSecondary(
      states: _secondaryStates,
      volHidden: _volHidden,
      order: _secondaryOrder,
    );
    _secondaryStates = selected.states;
    _volHidden = selected.volHidden;
    _secondaryOrder = selected.order;
  }

  void _toggleVolume() => setState(() {
    _volHidden = !_volHidden;
    _normalizeSecondary();
  });

  void _toggleSecondary(SecondaryState indicator) {
    setState(() {
      if (!_secondaryStates.remove(indicator)) {
        _secondaryStates.add(indicator);
      }
      _normalizeSecondary();
    });
  }

  void _reset() => setState(() => _restore(const SelectionParamsState()));

  void _save() {
    widget.onSave(
      mainStates: _mainStates,
      secondaryStates: _secondaryStates,
      volHidden: _volHidden,
      secondaryOrder: _secondaryOrder,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return CutCornerSheet(
      panelKey: const Key('indicator-settings-panel'),
      backgroundColor: AppColors.background(context),
      corners: const {CutCornerPosition.topRight},
      cutWidth: 25.sheetW(context),
      cutHeight: 21.5.sheetH(context),
      maxHeightFactor: 0.78,
      sectionSpacing: 0,
      title: l10n.indicatorSettingsTitle,
      titlePadding: EdgeInsets.fromLTRB(
        20.sheetW(context),
        24.sheetH(context),
        20.sheetW(context),
        0,
      ),
      titleStyle: TextStyle(
        color: AppColors.textPrimary(context),
        fontSize: _sheetTitleFontSize.sheetSp(context),
        fontWeight: FontWeight.w700,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20.sheetW(context),
          22.sheetH(context),
          20.sheetW(context),
          20.sheetH(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              label:
                  '${l10n.indicatorMainChart} '
                  '(${_mainStates.length}/${CandlestickSelectionSettings.maxMainIndicators})',
            ),
            SizedBox(height: 12.sheetH(context)),
            _IndicatorGrid(
              indicators: _visibleMainIndicators.map((indicator) {
                return _IndicatorOption(
                  label: indicator.name,
                  isSelected: _mainStates.contains(indicator),
                  onPressed: () => _toggleMain(indicator),
                );
              }).toList(),
            ),
            SizedBox(height: 26.sheetH(context)),
            _SectionHeader(
              label:
                  '${l10n.indicatorSecondaryChart} '
                  '(${_secondaryStates.length + (_volHidden ? 0 : 1)}/${CandlestickSelectionSettings.maxSecondaryIndicators})',
            ),
            SizedBox(height: 12.sheetH(context)),
            _IndicatorGrid(
              indicators: [
                _IndicatorOption(
                  label: 'VOL',
                  isSelected: !_volHidden,
                  onPressed: _toggleVolume,
                ),
                ...SecondaryState.values.map(
                  (indicator) => _IndicatorOption(
                    label: indicator.name,
                    isSelected: _secondaryStates.contains(indicator),
                    onPressed: () => _toggleSecondary(indicator),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      footerPadding: EdgeInsets.fromLTRB(
        20.sheetW(context),
        0,
        20.sheetW(context),
        20.sheetH(context),
      ),
      footer: Row(
        children: [
          Expanded(
            child: _ActionButton(
              key: const Key('indicator-settings-reset'),
              label: l10n.reset,
              backgroundColor: AppColors.accentTint(context),
              foregroundColor: AppColors.textPrimary(context),
              corner: ButtonCorner.topLeft,
              onPressed: _reset,
            ),
          ),
          SizedBox(width: 12.sheetW(context)),
          Expanded(
            child: _ActionButton(
              key: const Key('indicator-settings-save'),
              label: l10n.settingSave,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              corner: ButtonCorner.topRight,
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: AppColors.textSecondary(context),
      fontSize: _sheetTextFontSize.sheetSp(context),
      fontWeight: FontWeight.w700,
    );
    return Text(label, style: style);
  }
}

class _IndicatorGrid extends StatelessWidget {
  const _IndicatorGrid({required this.indicators});

  final List<Widget> indicators;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      mainAxisSpacing: 10.sheetH(context),
      crossAxisSpacing: 10.sheetW(context),
      childAspectRatio: 1.7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: indicators,
    );
  }
}

class _IndicatorOption extends StatelessWidget {
  const _IndicatorOption({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CutCornerButton(
      key: ValueKey('indicator-option-$label'),
      onPressed: onPressed,
      corners: const {ButtonCorner.topRight},
      cutSize: 9.sheetR(context),
      backgroundColor: isSelected
          ? AppColors.primary.withValues(alpha: 0.1)
          : AppColors.surface(context),
      foregroundColor: AppColors.textPrimary(context),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.transparent,
        width: 1.5,
      ),
      padding: EdgeInsets.symmetric(horizontal: 4.sheetW(context)),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontSize: _sheetTextFontSize.sheetSp(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.corner,
    required this.onPressed,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final ButtonCorner corner;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CutCornerButton(
      onPressed: onPressed,
      corners: {corner},
      cutSize: 14.sheetR(context),
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      padding: EdgeInsets.zero,
      minimumSize: Size(0, 48.sheetH(context)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: _sheetTextFontSize.sheetSp(context),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
