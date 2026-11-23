import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/animation.dart';

/// Unscaled price bounds shared by every main-chart layer.
class PriceRange {
  const PriceRange(this.min, this.max);
  final double min, max;
  double get span => max - min;

  PriceRange scaled(double scale) {
    final center = (max + min) / 2;
    return PriceRange(center - span / scale / 2, center + span / scale / 2);
  }

  bool matches(PriceRange other) =>
      (min - other.min).abs() <= 1e-10 * math.max(span, other.span) &&
      (max - other.max).abs() <= 1e-10 * math.max(span, other.span);

  PriceRange lerp(PriceRange other, double t) => PriceRange(
      lerpDouble(min, other.min, t)!, lerpDouble(max, other.max, t)!);
}

/// Per-chart transition state, retained across painter replacements. Endpoints
/// stay fixed throughout a transition, so timing is independent of frame rate.
class PriceRangeTransition {
  PriceRangeTransition({required this.onRetarget, this.curve = Curves.linear});
  final void Function() onRetarget;
  final Curve curve;
  double _startedAt = 0;
  double get endTime => _startedAt + 1;
  PriceRange? current, _from, _target, _lastInput;
  bool awaitingRestart = false;
  bool _held = false;

  PriceRange resolve(PriceRange target, double time, {bool immediate = false}) {
    if (current == null || immediate) {
      _held = awaitingRestart = false;
      return current = _from = _target = _lastInput = target;
    }
    if (_held && _lastInput!.matches(target)) return current!;
    _held = false;
    _lastInput = target;
    // Advance the old segment before retargeting. A pointer can supply a new
    // target every frame; freezing until a target is unchanged would stall it.
    if (!awaitingRestart) {
      current = _from!.lerp(_target!, progressAt(time));
    }
    if (!_target!.matches(target)) {
      _from = current;
      _target = target;
      _startedAt = time;
      if (!awaitingRestart) {
        awaitingRestart = true;
        onRetarget();
      }
    }
    return current!;
  }

  double progressAt(double time) => _from == null || _from!.matches(_target!)
      ? 1
      : curve.transform((time - _startedAt).clamp(0.0, 1.0));

  /// An idle clock starts at zero. An already running clock keeps its time,
  /// so frequent targets cannot repeatedly discard the next ticker frame.
  void markRestarted({bool resetClock = true}) {
    if (resetClock) _startedAt = 0;
    awaitingRestart = false;
  }

  /// Stop at the last painted range, including a queued post-paint restart.
  /// A new target or an explicit resume hands control back to the ticker.
  void interrupt() {
    _held = true;
    awaitingRestart = false;
    _from = _target = current;
  }

  void resume() => _held = false;

  void clear() {
    current = _from = _target = _lastInput = null;
    _held = awaitingRestart = false;
  }
}
