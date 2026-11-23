import '../entity/k_entity.dart';

/// 改进版本: 使用工厂构造函数,避免 late 关键字
class KLineEntityImproved extends KEntity {
  final double open;
  final double high;
  final double low;
  final double close;
  final double vol;
  final double? amount;
  final double? change;
  final double? ratio;
  final int? time;

  // 私有构造函数,所有字段都通过参数初始化
  KLineEntityImproved._({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.vol,
    this.amount,
    this.change,
    this.ratio,
    this.time,
  });

  // 工厂构造函数,从自定义参数创建
  factory KLineEntityImproved.fromCustom({
    double? amount,
    required double open,
    required double close,
    double? change,
    double? ratio,
    required int? time,
    required double high,
    required double low,
    required double vol,
  }) {
    return KLineEntityImproved._(
      open: open,
      high: high,
      low: low,
      close: close,
      vol: vol,
      amount: amount,
      change: change,
      ratio: ratio,
      time: time,
    );
  }

  // 工厂构造函数,从 JSON 创建
  factory KLineEntityImproved.fromJson(Map<String, dynamic> json) {
    final open = json['open']?.toDouble() ?? 0;
    final high = json['high']?.toDouble() ?? 0;
    final low = json['low']?.toDouble() ?? 0;
    final close = json['close']?.toDouble() ?? 0;
    final vol = json['vol']?.toDouble() ?? 0;
    final amount = json['amount']?.toDouble();

    // 兼容火币数据
    final int tempTime =
        json['time']?.toInt() ?? ((json['id']?.toInt() ?? 0) * 1000);

    return KLineEntityImproved._(
      open: open,
      high: high,
      low: low,
      close: close,
      vol: vol,
      amount: amount,
      time: tempTime,
      ratio: json['ratio']?.toDouble(),
      change: json['change']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'open': open,
      'close': close,
      'high': high,
      'low': low,
      'vol': vol,
      'amount': amount,
      'ratio': ratio,
      'change': change,
    };
  }

  @override
  String toString() {
    return 'KLineEntityImproved{open: $open, high: $high, low: $low, close: $close, vol: $vol, time: $time, amount: $amount, ratio: $ratio, change: $change}';
  }
}
