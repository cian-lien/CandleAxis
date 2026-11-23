import 'package:flutter/foundation.dart';

import '../entity/k_line_entity.dart';
import 'indicator_task.dart';

/// Flutter compute falls back to the browser event loop on web.
class IndicatorWorkerBackend {
  Future<List<KLineEntity>> calculate(IndicatorTask task) =>
      compute(calculateIndicatorTask, task);
  Future<void> dispose() async {}
}
