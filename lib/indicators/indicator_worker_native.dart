import 'dart:async';
import 'dart:isolate';

import '../entity/k_line_entity.dart';
import 'indicator_calculator.dart';
import 'indicator_task.dart';

class IndicatorWorkerBackend {
  IndicatorWorkerBackend() {
    _port.listen(_receive);
    _spawning = Isolate.spawn(_entry, _port.sendPort,
        onError: _port.sendPort,
        onExit: _port.sendPort,
        errorsAreFatal: true,
        debugName: 'candlestick-indicators');
    unawaited(_spawning.then((isolate) {
      if (_disposed) {
        isolate.kill(priority: Isolate.immediate);
      } else {
        _isolate = isolate;
      }
    }, onError: _fail));
  }

  final _port = ReceivePort();
  final _ready = Completer<SendPort>();
  Completer<List<KLineEntity>>? _result;
  late final Future<Isolate> _spawning;
  Isolate? _isolate;
  bool _disposed = false;
  Object? _failure;
  StackTrace? _failureStack;

  void _receive(dynamic message) {
    if (message is SendPort) {
      if (!_ready.isCompleted) _ready.complete(message);
    } else if (message is List<KLineEntity>) {
      _result?.complete(message);
      _result = null;
    } else if (message is (String, String)) {
      _fail(StateError(message.$1), StackTrace.fromString(message.$2));
    } else {
      final detail = message is List ? message.join('\n') : 'Worker exited';
      _fail(StateError(detail), StackTrace.current);
    }
  }

  void _fail(Object error, StackTrace stack) {
    _failure = error;
    _failureStack = stack;
    if (!_ready.isCompleted) _ready.completeError(error, stack);
    _result?.completeError(error, stack);
    _result = null;
  }

  Future<List<KLineEntity>> calculate(IndicatorTask task) async {
    final sender = await _ready.future;
    if (_disposed) throw StateError('Indicator worker disposed');
    final failure = _failure;
    if (failure != null) Error.throwWithStackTrace(failure, _failureStack!);
    final result = _result = Completer<List<KLineEntity>>();
    sender.send(task);
    return result.future;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _fail(StateError('Indicator worker disposed'), StackTrace.current);
    _port.close();
    _isolate?.kill(priority: Isolate.immediate);
    // Spawn can complete after disposal; wait for its kill handler as well.
    try {
      final isolate = await _spawning;
      isolate.kill(priority: Isolate.immediate);
    } catch (_) {
      // Spawn failure has already completed the request through _fail.
    }
  }
}

void _entry(SendPort parent) {
  final cache = IndicatorCalculationCache();
  final port = ReceivePort();
  parent.send(port.sendPort);
  port.listen((dynamic message) {
    try {
      parent.send(calculateIndicatorTask(message as IndicatorTask, cache));
    } catch (error, stack) {
      parent.send((error.toString(), stack.toString()));
    }
  });
}
