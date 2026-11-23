/// K 线周期。时长秒数直接作为 candles API 的 bar 参数。
/// 内置值仅用于接口加载前的默认选项，接口可提供任意正整数秒周期。
class Timeframe {
  const Timeframe._(this.name, this.label, this.duration, [this.zh, this.en]);

  factory Timeframe.remote({
    required int bar,
    required String zh,
    required String en,
  }) {
    if (bar <= 0) throw const FormatException('Invalid candle bar');
    final known = values
        .where((value) => value.duration.inSeconds == bar)
        .firstOrNull;
    return Timeframe._(
      known?.name ?? 'bar_$bar',
      zh,
      Duration(seconds: bar),
      zh,
      en,
    );
  }

  static const s30 = Timeframe._('s30', '30秒', Duration(seconds: 30));
  static const m1 = Timeframe._('m1', '1分钟', Duration(minutes: 1));
  static const m3 = Timeframe._('m3', '3分钟', Duration(minutes: 3));
  static const m5 = Timeframe._('m5', '5分钟', Duration(minutes: 5));
  static const m15 = Timeframe._('m15', '15分钟', Duration(minutes: 15));
  static const m30 = Timeframe._('m30', '30分钟', Duration(minutes: 30));
  static const h1 = Timeframe._('h1', '1小时', Duration(hours: 1));
  static const h2 = Timeframe._('h2', '2小时', Duration(hours: 2));
  static const h4 = Timeframe._('h4', '4小时', Duration(hours: 4));
  static const h6 = Timeframe._('h6', '6小时', Duration(hours: 6));
  static const h12 = Timeframe._('h12', '12小时', Duration(hours: 12));
  static const d1 = Timeframe._('d1', '1天', Duration(days: 1));
  static const w1 = Timeframe._('w1', '1周', Duration(days: 7));
  static const mo1 = Timeframe._('mo1', '1个月', Duration(days: 30));
  static const mo3 = Timeframe._('mo3', '3个月', Duration(days: 90));

  static const values = [
    s30,
    m1,
    m3,
    m5,
    m15,
    m30,
    h1,
    h2,
    h4,
    h6,
    h12,
    d1,
    w1,
    mo1,
    mo3,
  ];

  final String name;
  final String label;
  final Duration duration;
  final String? zh;
  final String? en;

  String? localizedLabel(String languageCode) =>
      languageCode.toLowerCase() == 'zh' ? zh : en;

  String get dateFormat {
    if (duration < const Duration(minutes: 1)) return 'HH:mm:ss';
    if (duration < const Duration(days: 1)) return 'MM/dd HH:mm';
    if (duration < const Duration(days: 7)) return 'MM/dd';
    if (duration < const Duration(days: 30)) return 'yyyy/MM/dd';
    return 'yyyy/MM';
  }

  int get defaultDataCount {
    if (duration < const Duration(hours: 1)) return 200;
    if (duration < const Duration(days: 1)) return 150;
    if (duration < const Duration(days: 7)) return 100;
    if (duration < const Duration(days: 30)) return 52;
    if (duration < const Duration(days: 90)) return 36;
    return 24;
  }

  // 周期身份由 bar 决定，后端名称变化不应使已保存的选中项失效。
  @override
  bool operator ==(Object other) =>
      other is Timeframe && duration == other.duration;

  @override
  int get hashCode => duration.hashCode;
}
