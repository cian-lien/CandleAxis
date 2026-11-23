part of 'chart_settings_bottom_sheet.dart';

extension _ChartSettingsColors on _ChartSettingsBottomSheetState {
  Widget _colorRow(
    BuildContext context, {
    required String label,
    required Color value,
    required CandleBodyStyle bodyStyle,
    required ValueChanged<Color> onChanged,
    required ValueChanged<CandleBodyStyle> onBodyStyleChanged,
  }) {
    final trigger = SizedBox(
      height: 34.sheetH(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 10.sheetW(context),
          vertical: 6.sheetH(context),
        ),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(18.sheetR(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _colorSwatch(context, color: value, isSelected: false),
            SizedBox(width: 8.sheetW(context)),
            Icon(
              Icons.arrow_drop_down,
              size: 20.sheetSp(context),
              color: AppColors.textSecondary(context),
            ),
          ],
        ),
      ),
    );
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
        _candleStyleToggle(
          context,
          value: bodyStyle,
          onChanged: onBodyStyleChanged,
        ),
        SizedBox(width: 8.sheetW(context)),
        if (SideSheetScope.of(context))
          GestureDetector(
            key: Key('chart-color-picker-$label'),
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              final color = await showCutCornerSheet<Color>(
                context,
                builder: (context) => CutCornerSheet(
                  titleWidget: ChartSettingsSheetHeader(
                    title: label,
                    onBack: () => Navigator.of(context).pop<Color>(),
                  ),
                  titlePadding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  bodyPadding: const EdgeInsets.all(20),
                  backgroundColor: AppColors.background(context),
                  body: _colorGridMenu(context, selectedColor: value),
                ),
              );
              if (context.mounted && color != null) onChanged(color);
            },
            child: trigger,
          )
        else
          PopupMenuButton<Color>(
            padding: EdgeInsets.zero,
            color: AppColors.card(context),
            onSelected: onChanged,
            itemBuilder: (popupContext) => [
              PopupMenuItem<Color>(
                enabled: false,
                padding: EdgeInsets.symmetric(
                  horizontal: 10.sheetW(context),
                  vertical: 8.sheetH(context),
                ),
                child: _colorGridMenu(popupContext, selectedColor: value),
              ),
            ],
            child: trigger,
          ),
      ],
    );
  }

  List<Color> get _colorOptions {
    final defaults = ChartColors();
    return [
      defaults.upColor,
      defaults.dnColor,
      AppColors.riseGreen,
      AppColors.fallRed,
      AppColors.primary,
      AppColors.quaternary,
    ];
  }

  Widget _colorGridMenu(BuildContext context, {required Color selectedColor}) {
    return SizedBox(
      width: SideSheetScope.of(context) ? double.infinity : 86.sheetW(context),
      child: Wrap(
        spacing: 7.sheetW(context),
        runSpacing: 8.sheetH(context),
        children: _colorOptions
            .map(
              (color) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop<Color>(context, color),
                child: _colorSwatch(
                  context,
                  color: color,
                  isSelected: color == selectedColor,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _colorSwatch(
    BuildContext context, {
    required Color color,
    required bool isSelected,
  }) {
    return Container(
      width: 24.sheetW(context),
      height: 24.sheetW(context),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6.sheetR(context)),
        border: Border.all(
          color: isSelected ? AppColors.textPrimary(context) : color,
          width: isSelected ? 2 : 1,
        ),
      ),
    );
  }
}
