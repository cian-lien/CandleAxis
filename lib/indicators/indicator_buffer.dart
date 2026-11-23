part of 'indicator_calculator.dart';

/// Dense numeric storage for the fixed indicator vocabulary. Keeps insertion
/// order and distinguishes absent, null and non-finite values just like Map.
/// Published through an unmodifiable view after calculation completes.
class _IndicatorBuffer extends MapBase<IndicatorLine, double?> {
  final _values = Float64List(IndicatorLine.values.length);
  final _order = Uint8List(IndicatorLine.values.length);
  int _present = 0, _nonNull = 0, _length = 0;

  @override
  double? operator [](Object? key) {
    if (key is! IndicatorLine || (_nonNull & (1 << key.index)) == 0) {
      return null;
    }
    return _values[key.index];
  }

  @override
  void operator []=(IndicatorLine key, double? value) {
    final bit = 1 << key.index;
    if ((_present & bit) == 0) {
      _present |= bit;
      _order[_length++] = key.index;
    }
    if (value == null) {
      _nonNull &= ~bit;
    } else {
      _nonNull |= bit;
      _values[key.index] = value;
    }
  }

  @override
  bool containsKey(Object? key) =>
      key is IndicatorLine && (_present & (1 << key.index)) != 0;

  @override
  int get length => _length;

  @override
  Iterable<IndicatorLine> get keys sync* {
    for (var i = 0; i < _length; i++) {
      yield IndicatorLine.values[_order[i]];
    }
  }

  @override
  double? remove(Object? key) {
    if (key is! IndicatorLine || !containsKey(key)) return null;
    final previous = this[key];
    final bit = 1 << key.index;
    _present &= ~bit;
    _nonNull &= ~bit;
    var index = 0;
    while (_order[index] != key.index) {
      index++;
    }
    for (var i = index; i < _length - 1; i++) {
      _order[i] = _order[i + 1];
    }
    _length--;
    return previous;
  }

  @override
  void clear() {
    _present = _nonNull = _length = 0;
  }
}
