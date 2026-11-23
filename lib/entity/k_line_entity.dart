import '../entity/k_entity.dart';
import '../indicators/indicator_values.dart';

class KLineEntity extends KEntity {
  KLineEntity.fromCustom({
    this.amount,
    required this.open,
    required this.close,
    this.change,
    this.ratio,
    required this.time,
    required this.high,
    required this.low,
    required this.vol,
    this.volumeValid = true,
    this.isClosed,
  });

  KLineEntity.fromJson(Map<String, dynamic> json) {
    open = json['open']?.toDouble() ?? 0;
    high = json['high']?.toDouble() ?? 0;
    low = json['low']?.toDouble() ?? 0;
    close = json['close']?.toDouble() ?? 0;
    vol = json['vol']?.toDouble() ?? 0;
    volumeValid = json['vol'] is num && vol.isFinite && vol >= 0;
    isClosed = json['isClosed'] as bool?;
    amount = json['amount']?.toDouble();
    int? tempTime = json['time']?.toInt();
    //兼容火币数据
    if (tempTime == null) {
      tempTime = json['id']?.toInt() ?? 0;
      tempTime = tempTime! * 1000;
    }
    time = tempTime;
    ratio = json['ratio']?.toDouble();
    change = json['change']?.toDouble();
  }

  /// 逐字段在 [begin] 与 [end] 之间插值，供最后一根蜡烛的过渡动画使用。
  ///
  /// 除 OHLC/vol 外，同时插值主图（MA/BOLL/SAR）、成交量均线与全部副图指标
  /// （MACD/KDJ/RSI/WR/CCI），保证动画期间指标线连续、刻度不跳变。
  /// 任一侧指标为 null 时直接取 [end] 的值（含 null），与真实数据语义一致。
  static KLineEntity lerp(KLineEntity begin, KLineEntity end, double t) {
    final entity = KLineEntity.fromCustom(
      time: end.time,
      open: _lerpScalar(begin.open, end.open, t),
      high: _lerpScalar(begin.high, end.high, t),
      low: _lerpScalar(begin.low, end.low, t),
      close: _lerpScalar(begin.close, end.close, t),
      vol: _lerpScalar(begin.vol, end.vol, t),
      amount: end.amount,
      change: end.change,
      ratio: end.ratio,
    );
    entity
      ..volumeValid = end.volumeValid
      ..isClosed = end.isClosed
      ..indicators = IndicatorValues.lerp(begin.indicators, end.indicators, t)
      ..maValueList = _lerpList(begin.maValueList, end.maValueList, t)
      ..sar = _lerpNullable(begin.sar, end.sar, t)
      ..BOLLMA = _lerpNullable(begin.BOLLMA, end.BOLLMA, t)
      ..mb = _lerpNullable(begin.mb, end.mb, t)
      ..up = _lerpNullable(begin.up, end.up, t)
      ..dn = _lerpNullable(begin.dn, end.dn, t)
      ..MA5Volume = _lerpNullable(begin.MA5Volume, end.MA5Volume, t)
      ..MA10Volume = _lerpNullable(begin.MA10Volume, end.MA10Volume, t)
      ..k = _lerpNullable(begin.k, end.k, t)
      ..d = _lerpNullable(begin.d, end.d, t)
      ..j = _lerpNullable(begin.j, end.j, t)
      ..macd = _lerpNullable(begin.macd, end.macd, t)
      ..dif = _lerpNullable(begin.dif, end.dif, t)
      ..dea = _lerpNullable(begin.dea, end.dea, t)
      ..rsi = _lerpNullable(begin.rsi, end.rsi, t)
      ..r = _lerpNullable(begin.r, end.r, t)
      ..cci = _lerpNullable(begin.cci, end.cci, t)
      ..openMcap = end.openMcap
      ..highMcap = end.highMcap
      ..lowMcap = end.lowMcap
      ..closeMcap = end.closeMcap;
    return entity;
  }

  /// Immutable-at-call-time copy for UI overlays that must not change when the
  /// live data list refreshes the underlying mutable KLineEntity instances.
  KLineEntity snapshot() {
    final entity = KLineEntity.fromCustom(
      time: time,
      open: open,
      high: high,
      low: low,
      close: close,
      vol: vol,
      amount: amount,
      change: change,
      ratio: ratio,
    );
    entity
      ..volumeValid = volumeValid
      ..isClosed = isClosed
      ..indicators = indicators.snapshot()
      ..maValueList = maValueList == null ? null : List<double>.of(maValueList!)
      ..sar = sar
      ..BOLLMA = BOLLMA
      ..mb = mb
      ..up = up
      ..dn = dn
      ..MA5Volume = MA5Volume
      ..MA10Volume = MA10Volume
      ..k = k
      ..d = d
      ..j = j
      ..macd = macd
      ..dif = dif
      ..dea = dea
      ..rsi = rsi
      ..r = r
      ..cci = cci
      ..openMcap = openMcap
      ..highMcap = highMcap
      ..lowMcap = lowMcap
      ..closeMcap = closeMcap;
    return entity;
  }

  static double _lerpScalar(double begin, double end, double t) =>
      begin + (end - begin) * t;

  static double? _lerpNullable(double? begin, double? end, double t) =>
      (begin == null || end == null) ? end : _lerpScalar(begin, end, t);

  static List<double>? _lerpList(
      List<double>? begin, List<double>? end, double t) {
    if (begin == null || end == null || begin.length != end.length) {
      return end;
    }
    return [
      for (var i = 0; i < begin.length; i++) _lerpScalar(begin[i], end[i], t),
    ];
  }

  @override
  late double open;
  @override
  late double high;
  @override
  late double low;
  @override
  late double close;
  @override
  late double vol;
  late double? amount;
  // late double? turnover;
  double? change;
  double? ratio;
  int? time;

  bool volumeValid = true;
  bool? isClosed;
  IndicatorValues indicators = const IndicatorValues({});

  /// 市值相关字段（由上层计算后传入）
  double? openMcap;
  double? highMcap;
  double? lowMcap;
  double? closeMcap;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['time'] = time;
    data['open'] = open;
    data['close'] = close;
    data['high'] = high;
    data['vol'] = vol;
    data['amount'] = amount;
    data['ratio'] = ratio;
    data['change'] = change;
    return data;
  }

  @override
  String toString() {
    return 'MarketModel{open: $open, high: $high, low: $low, close: $close, vol: $vol, time: $time, amount: $amount, ratio: $ratio, change: $change}';
  }
}
// ignore_for_file: overridden_fields
