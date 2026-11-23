part of 'chart_settings_bottom_sheet.dart';

class _ChartSettingsBottomSheet extends StatefulWidget {
  const _ChartSettingsBottomSheet({
    required this.currentValueType,
    required this.supportsMarketCap,
    required this.showTradeMarkers,
    required this.showAvgPriceLines,
    required this.preferPortraitFullscreen,
    required this.chartHeightScale,
    required this.showChartHeightSetting,
    required this.riseColor,
    required this.fallColor,
    required this.riseCandleBodyStyle,
    required this.fallCandleBodyStyle,
    required this.onSelected,
    required this.onShowTradeMarkersChanged,
    required this.onShowAvgPriceLinesChanged,
    required this.onPreferPortraitFullscreenChanged,
    required this.onChartHeightScaleChanged,
    required this.onRiseColorChanged,
    required this.onFallColorChanged,
    required this.onRiseCandleBodyStyleChanged,
    required this.onFallCandleBodyStyleChanged,
    required this.onChartHeightAdjustmentChanged,
  });

  final ChartValueType currentValueType;
  final bool supportsMarketCap;
  final bool showTradeMarkers;
  final bool showAvgPriceLines;
  final bool preferPortraitFullscreen;
  final double chartHeightScale;
  final bool showChartHeightSetting;
  final Color riseColor;
  final Color fallColor;
  final CandleBodyStyle riseCandleBodyStyle;
  final CandleBodyStyle fallCandleBodyStyle;
  final ValueChanged<ChartValueType> onSelected;
  final ValueChanged<bool> onShowTradeMarkersChanged;
  final ValueChanged<bool> onShowAvgPriceLinesChanged;
  final ValueChanged<bool> onPreferPortraitFullscreenChanged;
  final ValueChanged<double> onChartHeightScaleChanged;
  final ValueChanged<Color> onRiseColorChanged;
  final ValueChanged<Color> onFallColorChanged;
  final ValueChanged<CandleBodyStyle> onRiseCandleBodyStyleChanged;
  final ValueChanged<CandleBodyStyle> onFallCandleBodyStyleChanged;
  final ValueChanged<bool> onChartHeightAdjustmentChanged;

  @override
  State<_ChartSettingsBottomSheet> createState() =>
      _ChartSettingsBottomSheetState();
}

class _CandleStyleToggle extends StatefulWidget {
  const _CandleStyleToggle({required this.value, required this.onChanged});

  final CandleBodyStyle value;
  final ValueChanged<CandleBodyStyle> onChanged;

  @override
  State<_CandleStyleToggle> createState() => _CandleStyleToggleState();
}

class _CandleStyleToggleState extends State<_CandleStyleToggle>
    with SingleTickerProviderStateMixin {
  static const _animationDuration = Duration(milliseconds: 280);
  late final AnimationController _sliderController;

  @override
  void initState() {
    super.initState();
    _sliderController = AnimationController(
      vsync: this,
      duration: _animationDuration,
      value: widget.value == CandleBodyStyle.filled ? 0 : 1,
    );
  }

  @override
  void didUpdateWidget(covariant _CandleStyleToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == oldWidget.value) return;

    _sliderController.animateTo(
      widget.value == CandleBodyStyle.filled ? 0 : 1,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _sliderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72.sheetW(context),
      height: 34.sheetH(context),
      padding: EdgeInsets.all(2.sheetW(context)),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(18.sheetR(context)),
        border: Border.all(color: AppColors.borderSecondary(context)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _sliderController,
            builder: (context, child) {
              final progress = _sliderController.value;
              final stretch = math.sin(math.pi * progress);

              return Align(
                alignment: Alignment.lerp(
                  Alignment.centerLeft,
                  Alignment.centerRight,
                  progress,
                )!,
                child: FractionallySizedBox(
                  widthFactor: 0.5 + (0.14 * stretch),
                  heightFactor: 1 - (0.08 * stretch),
                  child: child,
                ),
              );
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.background(context),
                borderRadius: BorderRadius.circular(16.sheetR(context)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow(context),
                    blurRadius: 8.sheetR(context),
                    offset: Offset(0, 2.sheetH(context)),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              _CandleStyleIconButton(
                style: CandleBodyStyle.filled,
                selected: widget.value == CandleBodyStyle.filled,
                onTap: () => widget.onChanged(CandleBodyStyle.filled),
              ),
              _CandleStyleIconButton(
                style: CandleBodyStyle.hollow,
                selected: widget.value == CandleBodyStyle.hollow,
                onTap: () => widget.onChanged(CandleBodyStyle.hollow),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CandleStyleIconButton extends StatelessWidget {
  const _CandleStyleIconButton({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final CandleBodyStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected
        ? AppColors.textPrimary(context)
        : AppColors.textTertiary(context);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.expand(
          child: CustomPaint(
            painter: _CandleStyleIconPainter(
              color: iconColor,
              filled: style == CandleBodyStyle.filled,
            ),
          ),
        ),
      ),
    );
  }
}

class _CandleStyleIconPainter extends CustomPainter {
  const _CandleStyleIconPainter({required this.color, required this.filled});

  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final bodyWidth = size.width * 0.2;
    final bodyTop = size.height * 0.25;
    final bodyBottom = size.height * 0.77;
    final wickTop = size.height * 0.16;
    final wickBottom = size.height * 0.86;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        centerX - bodyWidth / 2,
        bodyTop,
        centerX + bodyWidth / 2,
        bodyBottom,
      ),
      Radius.circular(size.width * 0.04),
    );
    final paint = Paint()
      ..isAntiAlias = true
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.4, size.width * 0.055);

    canvas.drawLine(
      Offset(centerX, wickTop),
      Offset(centerX, wickBottom),
      paint,
    );
    canvas.drawRRect(
      body,
      paint..style = filled ? PaintingStyle.fill : PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _CandleStyleIconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.filled != filled;
}
