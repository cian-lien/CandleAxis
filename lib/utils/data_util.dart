import '../entity/index.dart';
import '../indicators/indicator_calculator.dart';

/// Compatibility facade; all formulas are defined in the indicator modules.
class DataUtil {
  static void calculate(List<KLineEntity> dataList,
          [List<int> maDayList = const [5, 10, 20], int n = 20, int k = 2]) =>
      IndicatorCalculator.calculate(dataList,
          maPeriods: maDayList, bollPeriod: n, bollMultiplier: k.toDouble());

  static void calcMA(List<KLineEntity> data, List<int> periods) =>
      IndicatorCalculator.calculate(data, maPeriods: periods);
  static void calcBOLL(List<KLineEntity> data, int n, int k) =>
      IndicatorCalculator.calculate(data,
          bollPeriod: n, bollMultiplier: k.toDouble());
  static void calcSAR(List<KLineEntity> data) => calculate(data);
  static void calcMACD(List<KLineEntity> data) => calculate(data);
  static void calcVolumeMA(List<KLineEntity> data) =>
      IndicatorCalculator.calculateVolumeMA(data);
  static void calcRSI(List<KLineEntity> data) => calculate(data);
  static void calcKDJ(List<KLineEntity> data) => calculate(data);
  static void calcWR(List<KLineEntity> data) => calculate(data);
  static void calcCCI(List<KLineEntity> data) => calculate(data);
}
