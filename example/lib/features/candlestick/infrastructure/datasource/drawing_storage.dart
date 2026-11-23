import 'dart:async';
import 'dart:convert';

import 'package:candle_axis/drawing/drawing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/types/result.dart';
import '../../../../infrastructure/utils/logger_util.dart';
import '../models/drawing_document_dto.dart';
import '../models/drawing_namespace.dart';

/// One shared adapter sequences writes, including across chart page lifecycles.
class DrawingStorage {
  DrawingStorage(SharedPreferences preferences)
    : this.withBackend(
        read: preferences.getString,
        write: preferences.setString,
        remove: preferences.remove,
      );

  DrawingStorage.withBackend({
    required String? Function(String key) read,
    required Future<bool> Function(String key, String value) write,
    Future<bool> Function(String key)? remove,
  }) : _read = read,
       _write = write,
       _remove = remove;

  final String? Function(String key) _read;
  final Future<bool> Function(String key, String value) _write;
  final Future<bool> Function(String key)? _remove;
  Future<void> _queue = Future.value();

  /// A damaged or unsupported archive is discarded instead of blocking drawing.
  /// The caller receives an empty document and may save new work immediately.
  Result<DrawingDocument> load(DrawingNamespace namespace) {
    final raw = _read(namespace.storageKey);
    if (raw != null) {
      try {
        return Result.success(_decode(raw));
      } catch (_) {
        unawaited(_discard(namespace));
      }
    }
    return Result.success(DrawingDocument());
  }

  /// 删除也排进写入队列：否则紧接着的保存可能被这次删除覆盖掉。
  Future<void> _discard(DrawingNamespace namespace) {
    final remove = _remove;
    if (remove == null) return Future.value();
    final operation = _queue.then((_) async {
      try {
        await remove(namespace.storageKey);
      } catch (_) {
        // Cleanup is best effort; the next save can replace the damaged archive.
        LoggerUtil.warning('DrawingStorage: unreadable archive cleanup failed');
      }
    });
    _queue = operation.then((_) {});
    return operation;
  }

  Future<Result<void>> save(
    DrawingNamespace namespace,
    DrawingDocument document,
  ) {
    // Encode an immutable snapshot before joining the asynchronous queue.
    final String encoded;
    try {
      final dto = DrawingDocumentDto.fromDocument(document);
      dto.toDocument();
      encoded = jsonEncode(dto.toJson());
    } catch (_) {
      return Future.value(const Result.failure('drawingDocumentInvalid'));
    }
    final operation = _queue.then((_) async {
      try {
        final saved = await _write(namespace.storageKey, encoded);
        return saved
            ? const Result<void>.success(null)
            : const Result<void>.failure('drawingSaveFailed');
      } catch (_) {
        return const Result<void>.failure('drawingSaveFailed');
      }
    });
    _queue = operation.then((_) {});
    return operation;
  }

  Future<void> flush() => _queue;

  DrawingDocument _decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid drawing archive');
    }
    return DrawingDocumentDto.fromJson(decoded).toDocument();
  }
}
