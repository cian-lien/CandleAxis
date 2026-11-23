import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/enums/timeframe.dart';
import '../../../../l10n/l10n.dart' as app_l10n;
import '../../../../shared/presentation/widgets/button/cut_corner_button.dart';
import '../../../../shared/presentation/widgets/sheet/cut_corner_sheet.dart';
import '../../../../themes/colors.dart';
import '../../../../utils/toast.dart';
import 'chart_settings_sheet_header.dart';
import 'timeframe_selector.dart';
import 'timeframe_short_label.dart';

// 横屏保持紧凑逻辑像素，避免竖屏 ScreenUtil 宽度比例放大弹层。
double _sheetWidth(BuildContext context, double value, bool compact) =>
    compact ? value : value.w;
double _sheetHeight(BuildContext context, double value, bool compact) =>
    compact ? value : value.h;
double _sheetFont(BuildContext context, double value, bool compact) =>
    compact ? value : value.sp;

const _sheetTitleFontSize = 18.0;
const _sheetTextFontSize = 14.0;

/// Shows the full timeframe settings sheet.
/// 返回的 Future 在弹窗关闭（选币/点遮罩/下滑）时完成。
Future<void> showTimeframeSelectorBottomSheet({
  required BuildContext context,
  required Timeframe currentSelection,
  required ValueChanged<Timeframe> onSelected,
  required List<Timeframe> availableTimeframes,
  required List<Timeframe> customTimeframes,
  required ValueChanged<List<Timeframe>> onCustomTimeframesChanged,
  bool compact = false,
}) {
  return showCutCornerSheet<void>(
    context,
    builder: (context) => TimeframeSelectorBottomSheet(
      currentSelection: currentSelection,
      onSelected: onSelected,
      availableTimeframes: availableTimeframes,
      customTimeframes: customTimeframes,
      onCustomTimeframesChanged: onCustomTimeframesChanged,
      compact: compact,
    ),
  );
}

enum _TimeframeSettingsPage { main, edit }

class TimeframeSelectorBottomSheet extends StatefulWidget {
  const TimeframeSelectorBottomSheet({
    super.key,
    required this.currentSelection,
    required this.onSelected,
    required this.availableTimeframes,
    required this.customTimeframes,
    required this.onCustomTimeframesChanged,
    this.compact = false,
  });

  final Timeframe currentSelection;
  final ValueChanged<Timeframe> onSelected;
  final List<Timeframe> availableTimeframes;
  final List<Timeframe> customTimeframes;
  final ValueChanged<List<Timeframe>> onCustomTimeframesChanged;
  final bool compact;

  @override
  State<TimeframeSelectorBottomSheet> createState() =>
      _TimeframeSelectorBottomSheetState();
}

class _TimeframeSelectorBottomSheetState
    extends State<TimeframeSelectorBottomSheet> {
  _TimeframeSettingsPage _page = _TimeframeSettingsPage.main;
  late List<Timeframe> _customTimeframes = List.of(widget.customTimeframes);
  late Set<Timeframe> _editingTimeframes = widget.customTimeframes.toSet();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _normalizeCustomTimeframesForLocale();
  }

  @override
  void didUpdateWidget(TimeframeSelectorBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.availableTimeframes, widget.availableTimeframes)) {
      _customTimeframes = List.of(widget.customTimeframes);
      _editingTimeframes = _editingTimeframes.intersection(
        widget.availableTimeframes.toSet(),
      );
      if (_editingTimeframes.isEmpty) {
        _editingTimeframes = _customTimeframes.toSet();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CutCornerSheet(
      backgroundColor: AppColors.background(context),
      corners: const {CutCornerPosition.topRight},
      cutSize: 18,
      maxHeightFactor: 0.86,
      sectionSpacing: _sheetHeight(context, 18, widget.compact),
      // 横屏只保留周期网格与标题，不显示分组。
      titleWidget: _title(context),
      titlePadding: EdgeInsets.fromLTRB(
        _sheetWidth(context, 20, widget.compact),
        _sheetHeight(context, 22, widget.compact),
        _sheetWidth(context, 20, widget.compact),
        0,
      ),
      bodyPadding: EdgeInsets.fromLTRB(
        _sheetWidth(context, 20, widget.compact),
        0,
        _sheetWidth(context, 20, widget.compact),
        _sheetHeight(context, 20, widget.compact),
      ),
      body: SingleChildScrollView(
        child: _page == _TimeframeSettingsPage.main
            ? _mainBody(context)
            : _editBody(context),
      ),
      footer: _page == _TimeframeSettingsPage.edit
          ? _editFooter(context)
          : null,
      footerPadding: EdgeInsets.fromLTRB(
        _sheetWidth(context, 20, widget.compact),
        0,
        _sheetWidth(context, 20, widget.compact),
        _sheetHeight(context, 20, widget.compact),
      ),
    );
  }

  Widget _title(BuildContext context) {
    final s = app_l10n.S.of(context);
    final title = _page == _TimeframeSettingsPage.main
        ? s.chartTimeSettings
        : s.chartEditTimeframes;
    return ChartSettingsSheetHeader(
      title: title,
      onBack: _page == _TimeframeSettingsPage.edit
          ? () => setState(() => _page = _TimeframeSettingsPage.main)
          : null,
      crossAxisAlignment: CrossAxisAlignment.start,
      iconSize: _sheetFont(context, 20, widget.compact),
      spacing: _sheetWidth(context, 12, widget.compact),
      textStyle: TextStyle(
        color: AppColors.textPrimary(context),
        fontSize: _sheetFont(context, _sheetTitleFontSize, widget.compact),
        fontWeight: FontWeight.w700,
        height: 1,
      ),
    );
  }

  Widget _mainBody(BuildContext context) {
    if (widget.compact) {
      return Padding(
        padding: EdgeInsets.only(top: _sheetHeight(context, 20, true)),
        child: _TimeframeGrid(
          compact: true,
          timeframes: widget.availableTimeframes,
          selected: {widget.currentSelection},
          onTap: widget.onSelected,
        ),
      );
    }
    final s = app_l10n.S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle(context, s.chartCustomTimeframes)),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  _editingTimeframes = _customTimeframes.toSet();
                  _page = _TimeframeSettingsPage.edit;
                });
              },
              child: Padding(
                padding: EdgeInsets.all(
                  _sheetWidth(context, 4, widget.compact),
                ),
                child: Icon(
                  LucideIcons.penLine,
                  size: _sheetFont(context, 16, widget.compact),
                  color: AppColors.textSecondary(context),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: _sheetHeight(context, 12, widget.compact)),
        _TimeframeGrid(
          compact: widget.compact,
          timeframes: _customTimeframes,
          selected: {widget.currentSelection},
          onTap: (timeframe) => widget.onSelected(timeframe),
        ),
        SizedBox(height: _sheetHeight(context, 26, widget.compact)),
        _sectionTitle(context, s.chartTimeframes),
        SizedBox(height: _sheetHeight(context, 12, widget.compact)),
        _TimeframeGrid(
          compact: widget.compact,
          timeframes: widget.availableTimeframes,
          selected: {widget.currentSelection},
          onTap: (timeframe) => widget.onSelected(timeframe),
        ),
      ],
    );
  }

  Widget _editBody(BuildContext context) {
    final s = app_l10n.S.of(context);
    final maxCustomTimeframes = _maxCustomTimeframes(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          s.chartTimeframesAdded(
            _editingTimeframes.length,
            maxCustomTimeframes,
          ),
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: _sheetFont(context, _sheetTextFontSize, widget.compact),
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: _sheetHeight(context, 18, widget.compact)),
        _TimeframeGrid(
          compact: widget.compact,
          timeframes: widget.availableTimeframes,
          selected: _editingTimeframes,
          onTap: _toggleEditingTimeframe,
        ),
      ],
    );
  }

  Widget _editFooter(BuildContext context) {
    final defaultTimeframes = TimeframeSelector.primaryTimeframesForLocale(
      Localizations.localeOf(context),
    ).where(widget.availableTimeframes.contains).toList();
    final isDefault = _listEquals(
      _editingTimeframes.toList()..sort(_compareTimeframes),
      defaultTimeframes,
    );
    final s = app_l10n.S.of(context);
    return Row(
      children: [
        Expanded(
          child: CutCornerButton(
            onPressed: isDefault
                ? null
                : () => setState(
                    () => _editingTimeframes = defaultTimeframes.toSet(),
                  ),
            corners: const {ButtonCorner.topLeft},
            cutSize: 12,
            padding: EdgeInsets.symmetric(
              vertical: _sheetHeight(context, 14, widget.compact),
            ),
            backgroundColor: AppColors.accentTint(context),
            foregroundColor: isDefault
                ? AppColors.textTertiary(context)
                : AppColors.textPrimary(context),
            side: BorderSide.none,
            child: Text(
              s.reset,
              style: TextStyle(
                fontSize: _sheetFont(
                  context,
                  _sheetTextFontSize,
                  widget.compact,
                ),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SizedBox(width: _sheetWidth(context, 12, widget.compact)),
        Expanded(
          child: CutCornerButton(
            onPressed: _confirmEditing,
            corners: const {ButtonCorner.topRight},
            cutSize: 12,
            padding: EdgeInsets.symmetric(
              vertical: _sheetHeight(context, 14, widget.compact),
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            side: BorderSide.none,
            child: Text(
              s.commonConfirm,
              style: TextStyle(
                fontSize: _sheetFont(
                  context,
                  _sheetTextFontSize,
                  widget.compact,
                ),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _toggleEditingTimeframe(Timeframe timeframe) {
    setState(() {
      final maxCustomTimeframes = _maxCustomTimeframes(context);
      if (_editingTimeframes.contains(timeframe)) {
        if (_editingTimeframes.length == 1) return;
        _editingTimeframes.remove(timeframe);
        return;
      }

      if (_editingTimeframes.length >= maxCustomTimeframes) {
        ToastUtils.showFailureToast(
          context,
          message: app_l10n.S.of(context).chartTimeframeMaxToast,
        );
        return;
      }
      _editingTimeframes.add(timeframe);
    });
  }

  void _confirmEditing() {
    final next = widget.availableTimeframes
        .where(_editingTimeframes.contains)
        .toList(growable: false);
    widget.onCustomTimeframesChanged(next);
    setState(() {
      _customTimeframes = next;
      _page = _TimeframeSettingsPage.main;
    });
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textSecondary(context),
        fontSize: _sheetFont(context, _sheetTextFontSize, widget.compact),
        fontWeight: FontWeight.w700,
      ),
    );
  }

  int _compareTimeframes(Timeframe a, Timeframe b) =>
      a.duration.compareTo(b.duration);

  bool _listEquals(List<Timeframe> a, List<Timeframe> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  int _maxCustomTimeframes(BuildContext context) {
    return TimeframeSelector.customTimeframeLimit(
      Localizations.localeOf(context),
    );
  }

  void _normalizeCustomTimeframesForLocale() {
    final maxCustomTimeframes = _maxCustomTimeframes(context);
    if (_customTimeframes.length > maxCustomTimeframes) {
      _customTimeframes = _customTimeframes
          .take(maxCustomTimeframes)
          .toList(growable: false);
    }
    if (_editingTimeframes.length > maxCustomTimeframes) {
      _editingTimeframes = widget.availableTimeframes
          .where(_editingTimeframes.contains)
          .take(maxCustomTimeframes)
          .toSet();
    }
  }
}

class _TimeframeGrid extends StatelessWidget {
  const _TimeframeGrid({
    required this.compact,
    required this.timeframes,
    required this.selected,
    required this.onTap,
  });

  final bool compact;
  final List<Timeframe> timeframes;
  final Set<Timeframe> selected;
  final ValueChanged<Timeframe> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 4;
        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: _sheetHeight(context, spacing, compact),
          children: timeframes.map((timeframe) {
            // 宽高都固定，格子尺寸不随文案长短（30秒 / 12小时）变化。
            return SizedBox(
              key: ValueKey('timeframe-grid-item-${timeframe.name}'),
              width: itemWidth,
              height: _sheetHeight(context, 42, compact),
              child: _TimeframeGridItem(
                compact: compact,
                timeframe: timeframe,
                isSelected: selected.contains(timeframe),
                onTap: () => onTap(timeframe),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _TimeframeGridItem extends StatelessWidget {
  const _TimeframeGridItem({
    required this.compact,
    required this.timeframe,
    required this.isSelected,
    required this.onTap,
  });

  final bool compact;
  final Timeframe timeframe;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CutCornerButton(
      onPressed: onTap,
      corners: const {ButtonCorner.topRight},
      cutSize: 8,
      padding: EdgeInsets.symmetric(
        horizontal: _sheetWidth(context, 14, compact),
        vertical: _sheetHeight(context, 11, compact),
      ),
      backgroundColor: isSelected
          ? AppColors.primary.withValues(alpha: 0.1)
          : AppColors.surface(context),
      foregroundColor: isSelected
          ? AppColors.primary
          : AppColors.textPrimary(context),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.transparent,
        width: isSelected ? 1.5 : 1,
      ),
      minimumSize: const Size.fromHeight(0),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(
          timeframe.shortLabel(context),
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.clip,
          style: TextStyle(
            fontSize: _sheetFont(context, _sheetTextFontSize, compact),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
