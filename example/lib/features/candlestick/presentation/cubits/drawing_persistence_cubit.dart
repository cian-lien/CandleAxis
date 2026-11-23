import 'dart:async';

import 'package:candlestick/drawing/drawing.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../infrastructure/datasource/drawing_storage.dart';
import '../../infrastructure/models/drawing_namespace.dart';
import 'drawing_persistence_state.dart';

export 'drawing_persistence_state.dart';

/// Persists committed edits only. The owner retains and disposes the controller.
class DrawingPersistenceCubit extends Cubit<DrawingPersistenceState> {
  DrawingPersistenceCubit({
    required DrawingStorage storage,
    required DrawingNamespace namespace,
    required ChartDrawingController controller,
  }) : _storage = storage,
       _namespace = namespace,
       _controller = controller,
       super(const DrawingPersistenceState.initial());

  final DrawingStorage _storage;
  final DrawingNamespace _namespace;
  final ChartDrawingController _controller;
  bool _listening = false;
  bool _initializing = false;
  bool _closing = false;
  int _revision = 0;

  Future<void> initialize() async {
    if (_closing || _listening || _initializing) return;
    _initializing = true;
    emit(const DrawingPersistenceState.loading());
    // A previous page may still be draining its last committed edit on exit.
    await _storage.flush();
    _initializing = false;
    if (_closing || isClosed) return;
    // 损坏或版本不支持的存档会被存储层丢弃，这里拿到的是空文档。
    final result = _storage.load(_namespace);
    if (!result.isSuccess) {
      emit(
        DrawingPersistenceState.failure(
          message: result.errorMessage ?? 'drawingArchiveUnreadable',
        ),
      );
      return;
    }
    _controller.restore(result.value!);
    _controller.addDocumentListener(_onDocumentChanged);
    _listening = true;
    emit(const DrawingPersistenceState.success());
  }

  void _onDocumentChanged() => unawaited(_save());

  Future<void> _save() async {
    if (_closing || !_listening) return;
    final revision = ++_revision;
    emit(const DrawingPersistenceState.loading());
    final result = await _storage.save(_namespace, _controller.document);
    if (_closing || isClosed || revision != _revision) return;
    emit(
      result.isSuccess
          ? const DrawingPersistenceState.success()
          : DrawingPersistenceState.failure(
              message: result.errorMessage ?? 'drawingSaveFailed',
            ),
    );
  }

  /// Re-reads the archive after another chart (e.g. the landscape session)
  /// may have written to the same namespace.
  Future<void> reload() async {
    if (!_listening) return initialize();
    await _storage.flush();
    if (_closing || isClosed) return;
    final result = _storage.load(_namespace);
    if (result.isSuccess) _controller.restore(result.value!);
  }

  Future<void> retry() => _listening ? _save() : initialize();
  Future<void> flush() => _storage.flush();

  @override
  Future<void> close() async {
    _closing = true;
    if (_listening) _controller.removeDocumentListener(_onDocumentChanged);
    await _storage.flush();
    await super.close();
  }
}
