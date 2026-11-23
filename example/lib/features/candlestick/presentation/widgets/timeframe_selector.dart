// ignore_for_file: flutter_style_todos

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/candle_source.dart';
import '../../../../core/enums/timeframe.dart';
import '../../../../infrastructure/di/service_locator.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/presentation/widgets/sheet/cut_corner_sheet.dart';
import '../../infrastructure/datasource/candlestick_settings_storage.dart';
import '../cubit/selection/selection_params_cubit.dart';
import '../cubit/selection/selection_params_state.dart';
import 'more_button.dart';
import 'timeframe_button.dart';
import 'timeframe_selector_bottom_sheet.dart';
import 'timeframe_short_label.dart';

class TimeframeSelector extends StatefulWidget {
  const TimeframeSelector({
    super.key,
    required this.source,
    this.compact = false,
    this.extraVisibleCount = 0,
  });

  final CandleSource source;
  final bool compact;

  /// 在自定义周期之外额外外显的周期数（横屏宽度更充裕）。
  final int extraVisibleCount;

  /// Timeframes shown directly in the compact chart toolbar.
  static const List<Timeframe> primaryTimeframes = [
    Timeframe.m1,
    Timeframe.m5,
    Timeframe.h1,
    Timeframe.h4,
    Timeframe.d1,
  ];

  static int customTimeframeLimit(Locale locale) {
    return locale.languageCode.toLowerCase() == 'zh' ? 4 : 5;
  }

  static List<Timeframe> primaryTimeframesForLocale(Locale locale) {
    return primaryTimeframes
        .where((t) => customTimeframeLimit(locale) == 5 || t != Timeframe.h4)
        .toList(growable: false);
  }

  /// All timeframes available from the "More" sheet.
  static const List<Timeframe> allTimeframes = [
    Timeframe.s30,
    Timeframe.m1,
    Timeframe.m3,
    Timeframe.m5,
    Timeframe.m15,
    Timeframe.m30,
    Timeframe.h1,
    Timeframe.h2,
    Timeframe.h4,
    Timeframe.h6,
    Timeframe.h12,
    Timeframe.d1,
    Timeframe.w1,
    Timeframe.mo1,
    Timeframe.mo3,
  ];

  /// Get available timeframes based on source
  static List<Timeframe> getAvailableTimeframes(
    CandleSource source, [
    List<Timeframe>? serverTimeframes,
  ]) {
    final timeframes = serverTimeframes ?? allTimeframes;
    if (source == CandleSource.cmc) {
      return timeframes
          .where((t) => t.duration >= const Duration(minutes: 15))
          .toList();
    }
    return timeframes;
  }

  @override
  State<TimeframeSelector> createState() => _TimeframeSelectorState();
}

class _TimeframeSelectorState extends State<TimeframeSelector> {
  late List<Timeframe> _availableTimeframes;
  late List<Timeframe> _customTimeframes;
  CandlestickSettingsStorage? _settingsStorage;

  /// 「更多」底部弹窗是否处于打开状态，驱动箭头旋转动画
  bool _isMoreSheetOpen = false;

  @override
  void initState() {
    super.initState();
    _settingsStorage = _registeredSettingsStorage();
    _customTimeframes =
        _settingsStorage?.selectionSettings.customTimeframes ??
        TimeframeSelector.primaryTimeframes;
    _updateAvailableTimeframes();
    unawaited(context.read<SelectionParamsCubit>().loadTimeframes());
  }

  @override
  void didUpdateWidget(TimeframeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      _updateAvailableTimeframes();
    }
  }

  void _updateAvailableTimeframes([SelectionParamsState? state]) {
    _availableTimeframes = TimeframeSelector.getAvailableTimeframes(
      widget.source,
      (state ?? context.read<SelectionParamsCubit>().state).availableTimeframes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectionParamsCubit, SelectionParamsState>(
      builder: (context, state) {
        _updateAvailableTimeframes(state);
        final selectedTimeframe =
            widget.source == CandleSource.cmc &&
                state.selectedTimeframe.duration < const Duration(minutes: 15)
            ? (_availableTimeframes.firstOrNull ?? Timeframe.m15)
            : state.selectedTimeframe;
        final displayTimeframe =
            _availableTimeframes
                .where((t) => t == selectedTimeframe)
                .firstOrNull ??
            selectedTimeframe;

        final locale = Localizations.localeOf(context);
        if (widget.compact) {
          return LayoutBuilder(
            builder: (context, constraints) {
              // 为「更多」的当前周期标签和放大文字预留同等宽度，避免
              // 切换到隐藏周期后挤压相邻按钮；剩余周期仍可在弹窗选择。
              final capacity = math.max(
                0,
                (constraints.maxWidth / _compactSlotWidth(context)).floor() - 1,
              );
              return _buildButtons(
                context,
                displayTimeframe,
                _visibleTimeframes(locale, maxCount: capacity),
              );
            },
          );
        }
        return _buildButtons(
          context,
          displayTimeframe,
          _visibleTimeframes(locale),
        );
      },
    );
  }

  Widget _buildButtons(
    BuildContext context,
    Timeframe displayTimeframe,
    List<Timeframe> visibleTimeframes,
  ) {
    final isSelectedInVisible = visibleTimeframes.contains(displayTimeframe);
    final buttons = [
      for (final timeframe in visibleTimeframes)
        TimeframeButton(
          compact: widget.compact,
          timeframe: timeframe,
          isSelected: displayTimeframe == timeframe,
          onPressed: () => _onTimeframeSelected(context, timeframe),
        ),
    ];
    final more = MoreButton(
      compact: widget.compact,
      isHighlighted: !isSelectedInVisible,
      selectedTimeframe: isSelectedInVisible ? null : displayTimeframe,
      isExpanded: _isMoreSheetOpen,
      onPressed: _showMoreSheet,
    );
    if (!widget.compact) {
      // 竖屏：周期按钮与「更多」紧挨成一组靠左；宽度不足时整组一起
      // 横向滚动，不会挤到右侧工具图标上，也不会溢出。
      return Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          key: const Key('timeframe-cluster'),
          scrollDirection: Axis.horizontal,
          child: Row(children: [...buttons, more]),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [...buttons, more],
    );
  }

  double _compactSlotWidth(BuildContext context) {
    final painter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    );
    final style = DefaultTextStyle.of(
      context,
    ).style.merge(const TextStyle(fontSize: 12, fontWeight: FontWeight.w700));
    var width = TimeframeButton.compactWidth;
    for (final label in [
      S.of(context).commonMore,
      for (final timeframe in _availableTimeframes)
        timeframe.shortLabel(context),
    ]) {
      painter.text = TextSpan(text: label, style: style);
      painter.layout();
      // 为「更多」的箭头、间隔及按钮之间的空隙留出余量。
      width = math.max(width, painter.width + 30);
    }
    painter.dispose();
    return width;
  }

  List<Timeframe> _timeframesForLocale(Locale locale) {
    final preferred =
        listEquals(_customTimeframes, TimeframeSelector.primaryTimeframes)
        ? TimeframeSelector.primaryTimeframesForLocale(locale)
        : _customTimeframes;
    final custom = preferred
        .expand((t) => _availableTimeframes.where((value) => value == t))
        .toList();
    // 后端可能只返回默认组合之外的新周期，至少外显一个可选项。
    return custom.isEmpty && _availableTimeframes.isNotEmpty
        ? [_availableTimeframes.first]
        : custom;
  }

  /// 自定义周期优先，额外名额按周期时长补齐并整体升序排列。
  List<Timeframe> _visibleTimeframes(Locale locale, {int? maxCount}) {
    final custom = _timeframesForLocale(locale)
        .where(_availableTimeframes.contains)
        .take(
          math.min(
            TimeframeSelector.customTimeframeLimit(locale),
            maxCount ?? TimeframeSelector.customTimeframeLimit(locale),
          ),
        )
        .toList();
    if (widget.extraVisibleCount <= 0) return custom;
    final extras = {..._landscapeExtraOrder, ..._availableTimeframes}
        .where((t) => _availableTimeframes.contains(t) && !custom.contains(t))
        .take(
          math.min(
            widget.extraVisibleCount,
            (maxCount ?? (custom.length + widget.extraVisibleCount)) -
                custom.length,
          ),
        );
    return [
      ...custom,
      ...extras.map(
        (t) => _availableTimeframes.firstWhere((value) => value == t),
      ),
    ]..sort((a, b) => a.duration.compareTo(b.duration));
  }

  /// 横屏补位优先级：常用的分钟级与日内周期在前。
  static const _landscapeExtraOrder = [
    Timeframe.m1,
    Timeframe.m30,
    Timeframe.s30,
    Timeframe.h2,
    Timeframe.d1,
    Timeframe.m5,
    Timeframe.m15,
    Timeframe.h1,
    Timeframe.h4,
    Timeframe.h12,
    Timeframe.w1,
  ];

  void _onTimeframeSelected(BuildContext context, Timeframe timeframe) {
    BlocProvider.of<SelectionParamsCubit>(context).updateTimeframe(timeframe);
  }

  /// 打开「更多」周期弹窗。箭头展开由弹窗自身 Future 完成（选币/点遮罩/下滑
  /// 三条关闭路径一致）驱动复位，无需订阅或定时器
  Future<void> _showMoreSheet() async {
    unawaited(context.read<SelectionParamsCubit>().loadTimeframes());
    setState(() => _isMoreSheetOpen = true);
    final selection = context.read<SelectionParamsCubit>();
    await showCutCornerSheet<void>(
      context,
      builder: (sheetContext) =>
          BlocBuilder<SelectionParamsCubit, SelectionParamsState>(
            bloc: selection,
            builder: (context, state) {
              _updateAvailableTimeframes(state);
              return TimeframeSelectorBottomSheet(
                currentSelection: state.selectedTimeframe,
                availableTimeframes: _availableTimeframes,
                customTimeframes:
                    _timeframesForLocale(Localizations.localeOf(context))
                        .take(
                          TimeframeSelector.customTimeframeLimit(
                            Localizations.localeOf(context),
                          ),
                        )
                        .toList(growable: false),
                compact: widget.compact,
                onCustomTimeframesChanged: (timeframes) {
                  if (mounted) {
                    setState(() => _customTimeframes = timeframes);
                    _persistCustomTimeframes(timeframes);
                  }
                },
                onSelected: (timeframe) {
                  selection.updateTimeframe(timeframe);
                  Navigator.of(sheetContext).pop();
                },
              );
            },
          ),
    );
    if (mounted) {
      setState(() => _isMoreSheetOpen = false);
    }
  }

  CandlestickSettingsStorage? _registeredSettingsStorage() {
    if (!getIt.isRegistered<CandlestickSettingsStorage>()) return null;
    return getIt<CandlestickSettingsStorage>();
  }

  void _persistCustomTimeframes(List<Timeframe> timeframes) {
    final settingsStorage = _settingsStorage;
    if (settingsStorage == null) return;
    final state = context.read<SelectionParamsCubit>().state;
    unawaited(
      settingsStorage.saveSelectionSettings(
        CandlestickSelectionSettings(
          selectedTimeframe: state.selectedTimeframe,
          customTimeframes: timeframes,
          mainStates: state.mainStates,
          secondaryStates: state.secondaryStates,
          volHidden: state.volHidden,
        ),
      ),
    );
  }
}
