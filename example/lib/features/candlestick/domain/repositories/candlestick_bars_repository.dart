import '../../../../core/enums/timeframe.dart';
import '../../../../core/types/result.dart';

abstract class CandlestickBarsRepository {
  Future<Result<List<Timeframe>>> getBars();
}
