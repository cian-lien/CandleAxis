import 'dart:async';
import 'dart:convert';

import 'package:candlestick/candlestick_widget.dart';
import 'package:candlestick/chart_style.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/enums/timeframe.dart';

class CandlestickSettingsStorage {
  CandlestickSettingsStorage(this._prefs);

  static const String _settingsKey = 'candlestick_settings_v1';
  static const String _selectionKey = 'selection';
  static const String _displayKey = 'display';
  static const String _drawingKey = 'drawing';
  static const String _hiddenToolPromptSuppressedKey =
      'hiddenToolPromptSuppressed';

  /// v4：分钟以下仅保留 30 秒，迁移并去重已保存的周期。
  static const int _selectionVersion = 4;

  final SharedPreferences _prefs;
  CandlestickSelectionSettings? _selectionSettings;
  Future<void> _writeQueue = Future.value();

  CandlestickSelectionSettings get selectionSettings {
    if (_selectionSettings case final cached?) return cached;
    final section = _readSection(_selectionKey);
    final settings = CandlestickSelectionSettings.fromJson(section);
    _selectionSettings = settings;
    // Also repair imported period names carrying the current schema version.
    final normalized = settings.toJson();
    if (section.isNotEmpty &&
        (section['selectionVersion'] != _selectionVersion ||
            section['selectedTimeframe'] != normalized['selectedTimeframe'] ||
            jsonEncode(section['customTimeframes']) !=
                jsonEncode(normalized['customTimeframes']))) {
      unawaited(saveSelectionSettings(settings));
    }
    return settings;
  }

  CandlestickDisplaySettings get displaySettings {
    final section = _readSection(_displayKey);
    return CandlestickDisplaySettings.fromJson(section);
  }

  Future<void> saveSelectionSettings(
    CandlestickSelectionSettings settings,
  ) async {
    _selectionSettings = settings.normalized();
    await _writeSection(_selectionKey, _selectionSettings!.toJson());
  }

  Future<void> saveDisplaySettings(CandlestickDisplaySettings settings) async {
    await _writeSection(_displayKey, settings.toJson());
  }

  /// 「画图已隐藏时选工具」确认弹窗是否已被用户勾选「不再提示」。
  bool get hiddenDrawingToolPromptSuppressed =>
      _readSection(_drawingKey)[_hiddenToolPromptSuppressedKey] == true;

  Future<void> saveHiddenDrawingToolPromptSuppressed(bool suppressed) {
    final section = _readSection(_drawingKey)
      ..[_hiddenToolPromptSuppressedKey] = suppressed;
    return _writeSection(_drawingKey, section);
  }

  Map<String, dynamic> _readSection(String sectionKey) {
    final root = _readRoot();
    final section = root[sectionKey];
    return section is Map ? Map<String, dynamic>.from(section) : {};
  }

  Map<String, dynamic> _readRoot() {
    final raw = _prefs.getString(_settingsKey);
    if (raw == null || raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
    } on FormatException {
      return {};
    }
  }

  Future<void> _writeSection(String sectionKey, Map<String, dynamic> section) {
    final write = _writeQueue.then((_) async {
      final root = _readRoot()..[sectionKey] = section;
      await _prefs.setString(_settingsKey, jsonEncode(root));
    });
    // The operation still reports its failure to its caller; the sequencing
    // barrier recovers so one storage exception cannot disable future saves.
    _writeQueue = write.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return write;
  }
}

class CandlestickSelectionSettings {
  const CandlestickSelectionSettings({
    required this.selectedTimeframe,
    required this.customTimeframes,
    required this.mainStates,
    required this.secondaryStates,
    required this.volHidden,
    this.secondaryOrder = const ['VOL'],
  });

  factory CandlestickSelectionSettings.defaults() =>
      const CandlestickSelectionSettings(
        selectedTimeframe: Timeframe.m5,
        customTimeframes: [
          Timeframe.m1,
          Timeframe.m5,
          Timeframe.h1,
          Timeframe.h4,
          Timeframe.d1,
        ],
        mainStates: {},
        secondaryStates: {},
        volHidden: false,
      );

  factory CandlestickSelectionSettings.fromJson(Map<String, dynamic> json) {
    final fallback = CandlestickSelectionSettings.defaults();
    final custom = json.containsKey('customTimeframes')
        ? _timeframesByName(json['customTimeframes'])
        : fallback.customTimeframes;
    // 只更新旧默认组合，其余已保存的自定义周期保持不变。
    final wasDefault = listEquals(custom, const [
      Timeframe.m5,
      Timeframe.m15,
      Timeframe.h1,
      Timeframe.h4,
      Timeframe.d1,
    ]);
    return CandlestickSelectionSettings(
      selectedTimeframe: json.containsKey('selectedTimeframe')
          ? _timeframeByName(json['selectedTimeframe']) ?? Timeframe.m1
          : fallback.selectedTimeframe,
      customTimeframes: wasDefault ? fallback.customTimeframes : custom,
      mainStates: _enumListByName(
        MainState.values,
        json['mainStates'],
        fallback.mainStates.toList(growable: false),
      ).toSet(),
      secondaryStates: _enumListByName(
        SecondaryState.values,
        json['secondaryStates'],
        fallback.secondaryStates.toList(growable: false),
      ).toSet(),
      secondaryOrder: json['secondaryOrder'] is List
          ? (json['secondaryOrder'] as List).whereType<String>().toList()
          : const ['VOL'],
      volHidden: json['volHidden'] is bool
          ? json['volHidden'] as bool
          : fallback.volHidden,
    ).normalized();
  }

  final Timeframe selectedTimeframe;
  final List<Timeframe> customTimeframes;
  final Set<MainState> mainStates;
  final Set<SecondaryState> secondaryStates;
  final bool volHidden;
  final List<String> secondaryOrder;

  /// 主图最多同时叠加的指标数。
  static const int maxMainIndicators = 4;

  /// 副图（含 VOL）最多同时显示的指标数。
  static const int maxSecondaryIndicators = 6;

  /// 保留前 [max] - 1 项，满额后新增的指标替换最后一项。
  static Set<T> limitIndicators<T>(Iterable<T> selection, int max) {
    final list = selection.toSet().toList(growable: false);
    if (list.length <= max) return list.toSet();
    return {...list.take(max - 1), list.last};
  }

  /// 将 VOL 与技术副图纳入同一选择顺序，满额时替换最后一项。
  static ({Set<SecondaryState> states, bool volHidden, List<String> order})
  normalizeSecondary({
    required Set<SecondaryState> states,
    required bool volHidden,
    required List<String> order,
  }) {
    final selected = {
      for (final state in states) state.name,
      if (!volHidden) 'VOL',
    };
    final limited = limitIndicators({
      ...order.where(selected.contains),
      for (final state in states) state.name,
      if (!volHidden) 'VOL',
    }, maxSecondaryIndicators);
    return (
      states: {
        for (final name in limited)
          if (name != 'VOL')
            SecondaryState.values.firstWhere((state) => state.name == name),
      },
      volHidden: !limited.contains('VOL'),
      order: limited.toList(growable: false),
    );
  }

  CandlestickSelectionSettings normalized() {
    final selected = normalizeSecondary(
      states: secondaryStates,
      volHidden: volHidden,
      order: secondaryOrder,
    );
    return CandlestickSelectionSettings(
      selectedTimeframe: selectedTimeframe,
      customTimeframes: customTimeframes.isEmpty
          ? const [Timeframe.m1]
          : customTimeframes.toSet().toList(growable: false),
      mainStates: limitIndicators(mainStates, maxMainIndicators),
      secondaryStates: selected.states,
      volHidden: selected.volHidden,
      secondaryOrder: selected.order,
    );
  }

  Map<String, dynamic> toJson() => {
    'selectionVersion': CandlestickSettingsStorage._selectionVersion,
    'selectedTimeframe': selectedTimeframe.name,
    'customTimeframes': customTimeframes
        .map((timeframe) => timeframe.name)
        .toList(growable: false),
    'mainStates': mainStates.map((state) => state.name).toList(growable: false),
    'secondaryStates': secondaryStates
        .map((state) => state.name)
        .toList(growable: false),
    'volHidden': volHidden,
    'secondaryOrder': secondaryOrder,
  };
}

class CandlestickDisplaySettings {
  const CandlestickDisplaySettings({
    required this.valueType,
    required this.isTrendLine,
    required this.showTradeMarkers,
    required this.showAvgPriceLines,
    required this.chartHeightScale,
    required this.riseColor,
    required this.fallColor,
    required this.riseCandleBodyStyle,
    required this.fallCandleBodyStyle,
    required this.preferPortraitFullscreen,
  });

  factory CandlestickDisplaySettings.defaults() {
    final defaults = ChartColors();
    return CandlestickDisplaySettings(
      valueType: ChartValueType.marketCap,
      isTrendLine: false,
      showTradeMarkers: true,
      showAvgPriceLines: true,
      chartHeightScale: 1.0,
      riseColor: defaults.upColor,
      fallColor: defaults.dnColor,
      riseCandleBodyStyle: CandleBodyStyle.filled,
      fallCandleBodyStyle: CandleBodyStyle.filled,
      // 默认关闭：全屏入口打开横屏；开启后全屏入口打开竖屏全屏。
      preferPortraitFullscreen: false,
    );
  }

  factory CandlestickDisplaySettings.fromJson(Map<String, dynamic> json) {
    final fallback = CandlestickDisplaySettings.defaults();
    return CandlestickDisplaySettings(
      valueType: _enumByName(
        ChartValueType.values,
        json['valueType'],
        fallback.valueType,
      ),
      isTrendLine: json['isTrendLine'] is bool
          ? json['isTrendLine'] as bool
          : fallback.isTrendLine,
      showTradeMarkers: json['showTradeMarkers'] is bool
          ? json['showTradeMarkers'] as bool
          : fallback.showTradeMarkers,
      showAvgPriceLines: json['showAvgPriceLines'] is bool
          ? json['showAvgPriceLines'] as bool
          : fallback.showAvgPriceLines,
      chartHeightScale: json['chartHeightScale'] is num
          ? (json['chartHeightScale'] as num)
                .toDouble()
                .clamp(0.8, 1.25)
                .toDouble()
          : fallback.chartHeightScale,
      riseColor: _colorFromJson(json['riseColor'], fallback.riseColor),
      fallColor: _colorFromJson(json['fallColor'], fallback.fallColor),
      riseCandleBodyStyle: _enumByName(
        CandleBodyStyle.values,
        json['riseCandleBodyStyle'],
        fallback.riseCandleBodyStyle,
      ),
      fallCandleBodyStyle: _enumByName(
        CandleBodyStyle.values,
        json['fallCandleBodyStyle'],
        fallback.fallCandleBodyStyle,
      ),
      preferPortraitFullscreen: json['preferPortraitFullscreen'] is bool
          ? json['preferPortraitFullscreen'] as bool
          : fallback.preferPortraitFullscreen,
    );
  }

  final ChartValueType valueType;
  final bool isTrendLine;
  final bool showTradeMarkers;
  final bool showAvgPriceLines;
  final double chartHeightScale;
  final Color riseColor;
  final Color fallColor;
  final CandleBodyStyle riseCandleBodyStyle;
  final CandleBodyStyle fallCandleBodyStyle;

  /// 为真时图表全屏入口打开竖屏全屏；默认假则打开横屏。
  final bool preferPortraitFullscreen;

  Map<String, dynamic> toJson() => {
    'valueType': valueType.name,
    'isTrendLine': isTrendLine,
    'showTradeMarkers': showTradeMarkers,
    'showAvgPriceLines': showAvgPriceLines,
    'chartHeightScale': chartHeightScale,
    'riseColor': _colorToJson(riseColor),
    'fallColor': _colorToJson(fallColor),
    'riseCandleBodyStyle': riseCandleBodyStyle.name,
    'fallCandleBodyStyle': fallCandleBodyStyle.name,
    'preferPortraitFullscreen': preferPortraitFullscreen,
  };
}

// Migrate legacy enum names and imported resolution labels to the only
// supported sub-minute period before decoding the custom list and deduplicating.
Timeframe? _timeframeByName(Object? name) {
  if (name is! String) return null;
  // 动态周期单独编码，不改变旧版 s1/s5/s15 的迁移语义。
  if (name.startsWith('bar_')) {
    final seconds = int.tryParse(name.substring(4));
    if (seconds != null && seconds > 0) {
      return Timeframe.remote(bar: seconds, zh: '$seconds秒', en: '${seconds}s');
    }
  }
  for (final value in Timeframe.values) {
    if (value.name == name) return value;
  }
  final secondsMatch = RegExp(
    r'^(?:s([0-9]+)|([0-9]+)s)$',
  ).firstMatch(name.trim().toLowerCase());
  final seconds = int.tryParse(
    secondsMatch?.group(1) ?? secondsMatch?.group(2) ?? '',
  );
  return seconds != null && seconds > 0 && seconds < 60 ? Timeframe.s30 : null;
}

List<Timeframe> _timeframesByName(Object? names) {
  if (names is! List) return const [Timeframe.m1];
  final decoded = names.map(_timeframeByName).whereType<Timeframe>().toSet();
  return decoded.isEmpty
      ? const [Timeframe.m1]
      : decoded.toList(growable: false);
}

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  if (name is! String) return fallback;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

List<T> _enumListByName<T extends Enum>(
  List<T> values,
  Object? names,
  List<T> fallback,
) {
  if (names is! List) return fallback;
  final decoded = <T>[];
  for (final name in names) {
    if (name is! String) continue;
    for (final value in values) {
      if (value.name == name) {
        decoded.add(value);
        break;
      }
    }
  }
  return decoded.isEmpty ? fallback : decoded;
}

Color _colorFromJson(Object? value, Color fallback) {
  if (value is! int) return fallback;
  return Color(value);
}

int _colorToJson(Color color) {
  final alpha = (color.a * 255).round() & 0xff;
  final red = (color.r * 255).round() & 0xff;
  final green = (color.g * 255).round() & 0xff;
  final blue = (color.b * 255).round() & 0xff;
  return alpha << 24 | red << 16 | green << 8 | blue;
}
