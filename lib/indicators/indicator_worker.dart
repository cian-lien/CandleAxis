import 'dart:async';

import '../entity/k_line_entity.dart';
import 'indicator_calculator.dart';
import 'indicator_task.dart';
import 'indicator_worker_native.dart'
    if (dart.library.js_interop) 'indicator_worker_web.dart';

abstract interface class IndicatorCalculationService {
  /// Null means the queued request was superseded or the service was disposed.
  Future<List<KLineEntity>?> calculate(List<KLineEntity> data,
      {IndicatorContext context = const IndicatorContext(),
      List<int> maPeriods = const [5, 10, 20],
      int bollPeriod = 20,
      double bollMultiplier = 2});

  Future<void> dispose();
}

/// Reuses one native isolate. At most one job runs and one latest job waits,
/// preventing a high-rate feed from building an unbounded calculation backlog.
/// Web retains Flutter compute's single-threaded fallback semantics.
class IndicatorWorker implements IndicatorCalculationService {
  IndicatorWorkerBackend? _backend;
  _Request? _pending;
  _Request? _active;
  bool _running = false;
  bool _disposed = false;

  @override
  Future<List<KLineEntity>?> calculate(List<KLineEntity> data,
      {IndicatorContext context = const IndicatorContext(),
      List<int> maPeriods = const [5, 10, 20],
      int bollPeriod = 20,
      double bollMultiplier = 2}) {
    if (_disposed) return Future.value(null);
    final request = _Request(IndicatorTask(data, context,
        List.unmodifiable(maPeriods), bollPeriod, bollMultiplier));
    _pending?.complete(null);
    _pending = request;
    if (!_running) unawaited(_drain());
    return request.completer.future;
  }

  Future<void> _drain() async {
    _running = true;
    while (!_disposed && _pending != null) {
      final request = _active = _pending!;
      _pending = null;
      try {
        final backend = _backend ??= IndicatorWorkerBackend();
        final data = await backend.calculate(request.task);
        request.complete(_disposed ? null : data);
      } catch (error, stack) {
        if (!request.completer.isCompleted) {
          request.completer.completeError(error, stack);
        }
        // A failed worker must not permanently strand future feed updates.
        await _backend?.dispose();
        _backend = null;
      }
      _active = null;
    }
    _running = false;
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _pending?.complete(null);
    _pending = null;
    _active?.complete(null);
    await _backend?.dispose();
  }
}

class _Request {
  _Request(this.task);
  final IndicatorTask task;
  final completer = Completer<List<KLineEntity>?>();
  void complete(List<KLineEntity>? value) {
    if (!completer.isCompleted) completer.complete(value);
  }
}
