import 'dart:typed_data';

import '../entity/k_line_entity.dart';
import 'indicator_calculator.dart';

/// Capture raw input in numeric buffers, so enqueue/send do not allocate and
/// copy a full graph of mutable candle objects on the UI isolate.
class IndicatorTask {
  IndicatorTask(List<KLineEntity> data, this.context, this.maPeriods,
      this.bollPeriod, this.bollMultiplier)
      : _values = Float64List(data.length * _columns),
        _flags = Uint16List(data.length),
        _times =
            List.generate(data.length, (i) => data[i].time, growable: false) {
    for (var i = 0; i < data.length; i++) {
      final candle = data[i], offset = i * _columns;
      _values[offset] = candle.open;
      _values[offset + 1] = candle.high;
      _values[offset + 2] = candle.low;
      _values[offset + 3] = candle.close;
      _values[offset + 4] = candle.vol;
      _set(i, 5, candle.amount);
      _set(i, 6, candle.change);
      _set(i, 7, candle.ratio);
      _set(i, 8, candle.BOLLMA);
      _set(i, 9, candle.openMcap);
      _set(i, 10, candle.highMcap);
      _set(i, 11, candle.lowMcap);
      _set(i, 12, candle.closeMcap);
      if (candle.volumeValid) _flags[i] |= 1 << 13;
      if (candle.isClosed != null) _flags[i] |= 1 << 14;
      if (candle.isClosed == true) _flags[i] |= 1 << 15;
    }
  }

  static const _columns = 13;
  final Float64List _values;
  final Uint16List _flags;
  // Keep integer timestamps lossless, including null and values beyond 2^53.
  final List<int?> _times;
  final IndicatorContext context;
  final List<int> maPeriods;
  final int bollPeriod;
  final double bollMultiplier;

  void _set(int row, int column, double? value) {
    if (value == null) return;
    _flags[row] |= 1 << column;
    _values[row * _columns + column] = value;
  }

  double? _optional(int row, int column) => (_flags[row] & (1 << column)) == 0
      ? null
      : _values[row * _columns + column];

  List<KLineEntity> _materialize() => List.generate(_times.length, (i) {
        final offset = i * _columns, flags = _flags[i];
        return KLineEntity.fromCustom(
            time: _times[i],
            open: _values[offset],
            high: _values[offset + 1],
            low: _values[offset + 2],
            close: _values[offset + 3],
            vol: _values[offset + 4],
            amount: _optional(i, 5),
            change: _optional(i, 6),
            ratio: _optional(i, 7),
            volumeValid: (flags & (1 << 13)) != 0,
            isClosed:
                (flags & (1 << 14)) == 0 ? null : (flags & (1 << 15)) != 0)
          // Duplicate propagation deliberately preserves this legacy scalar.
          ..BOLLMA = _optional(i, 8)
          ..openMcap = _optional(i, 9)
          ..highMcap = _optional(i, 10)
          ..lowMcap = _optional(i, 11)
          ..closeMcap = _optional(i, 12);
      });
}

List<KLineEntity> calculateIndicatorTask(IndicatorTask task,
    [IndicatorCalculationCache? cache]) {
  final data = task._materialize();
  IndicatorCalculator.calculate(data,
      context: task.context,
      cache: cache,
      maPeriods: task.maPeriods,
      bollPeriod: task.bollPeriod,
      bollMultiplier: task.bollMultiplier);
  return data;
}
