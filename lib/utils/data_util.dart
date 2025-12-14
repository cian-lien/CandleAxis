import 'dart:math';

import '../entity/index.dart';

/// K 线数据处理工具类
/// 提供各种技术指标的计算方法
/// 所有计算都是原地修改（in-place），直接修改传入的 dataList
class DataUtil {
  /// 一键计算所有技术指标
  /// 这是使用本库的主要入口点
  ///
  /// [dataList] K 线数据列表，必须包含基础的 OHLC 数据
  /// [maDayList] MA 均线周期列表，默认 [5, 10, 20]
  /// [n] BOLL 指标的周期，默认 20
  /// [k] BOLL 指标的标准差倍数，默认 2
  ///
  /// 使用示例：
  /// ```dart
  /// List<KLineEntity> data = [...]; // 从 API 获取原始数据
  /// DataUtil.calculate(data); // 计算所有指标
  /// // 现在 data 中包含了所有技术指标数据
  /// ```
  static calculate(List<KLineEntity> dataList,
      [List<int> maDayList = const [5, 10, 20], int n = 20, k = 2]) {
    /// 计算主图指标
    calcMA(dataList, maDayList); // 移动平均线
    calcBOLL(dataList, n, k); // 布林带
    calcSAR(dataList); // 抛物线转向

    /// 计算副图指标
    calcVolumeMA(dataList); // 成交量均线
    calcKDJ(dataList); // 随机指标
    calcMACD(dataList); // MACD 指标
    calcRSI(dataList); // 相对强弱指标
    calcWR(dataList); // 威廉指标
    calcCCI(dataList); // 顺势指标
  }

  /// 计算移动平均线（Moving Average）
  /// 使用滑动窗口算法，时间复杂度 O(n)
  ///
  /// [dataList] K 线数据列表
  /// [maDayList] 均线周期列表，例如 [5, 10, 20] 表示计算 MA5、MA10、MA20
  ///
  /// 算法说明：
  /// 1. 使用滑动窗口维护每个周期的累加和
  /// 2. 达到周期后开始计算均值
  /// 3. 窗口滑动时减去滑出的值，加上新值
  static calcMA(List<KLineEntity> dataList, List<int> maDayList) {
    // ma[i] 保存第 i 个周期的累加和
    List<double> ma = List<double>.filled(maDayList.length, 0);

    if (dataList.isNotEmpty) {
      for (int i = 0; i < dataList.length; i++) {
        KLineEntity entity = dataList[i];
        final closePrice = entity.close;
        // 为每个 K 线创建 MA 值列表
        entity.maValueList = List<double>.filled(maDayList.length, 0);

        // 计算每个周期的 MA 值
        for (int j = 0; j < maDayList.length; j++) {
          ma[j] += closePrice; // 累加当前收盘价

          // 达到周期时开始计算均值
          if (i == maDayList[j] - 1) {
            entity.maValueList?[j] = ma[j] / maDayList[j];
          }
          // 滑动窗口：减去最早的值，保持窗口大小
          else if (i >= maDayList[j]) {
            ma[j] -= dataList[i - maDayList[j]].close;
            entity.maValueList?[j] = ma[j] / maDayList[j];
          }
        }
      }
    }
  }

  static void calcSAR(List<KLineEntity> dataList) {
    const List<double> params = [2, 2, 20]; //calcParams default
    final startAf = params[0] / 100;
    final step = params[1] / 100;
    final maxAf = params[2] / 100;

    // Acceleration factor
    double af = startAf;
    // Extreme point
    double ep = -100;
    // Determine trend direction — false: downtrend
    bool isIncreasing = false;
    double sar = 0;

    for (int i = 0; i < dataList.length; ++i) {
      // the previous period SAR
      final preSar = sar;
      final high = dataList[i].high;
      final low = dataList[i].low;

      if (isIncreasing) {
        // Uptrend
        if (ep == -100 || ep < high) {
          // Reinitialize parameters
          ep = high;
          af = min(af + step, maxAf);
        }
        sar = preSar + af * (ep - preSar);
        final lowMin = min(dataList[max(1, i) - 1].low, low);
        if (sar > dataList[i].low) {
          sar = ep;
          // Reinitialize parameters
          af = startAf;
          ep = -100;
          isIncreasing = !isIncreasing;
        } else if (sar > lowMin) {
          sar = lowMin;
        }
      } else {
        if (ep == -100 || ep > low) {
          // Reinitialize parameters
          ep = low;
          af = min(af + step, maxAf);
        }
        sar = preSar + af * (ep - preSar);
        final highMax = max(dataList[max(1, i) - 1].high, high);
        if (sar < dataList[i].high) {
          sar = ep;
          // Reinitialize parameters
          af = 0;
          ep = -100;
          isIncreasing = !isIncreasing;
        } else if (sar < highMax) {
          sar = highMax;
        }
      }

      dataList[i].sar = sar;
    }
  }

  static void calcBOLL(List<KLineEntity> dataList, int n, int k) {
    _calcBOLLMA(n, dataList);
    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      if (i >= n) {
        double md = 0;
        for (int j = i - n + 1; j <= i; j++) {
          double c = dataList[j].close;
          double m = entity.BOLLMA!;
          double value = c - m;
          md += value * value;
        }
        md = md / (n - 1);
        md = sqrt(md);
        entity.mb = entity.BOLLMA!;
        entity.up = entity.mb! + k * md;
        entity.dn = entity.mb! - k * md;
      }
    }
  }

  static void _calcBOLLMA(int day, List<KLineEntity> dataList) {
    double ma = 0;
    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      ma += entity.close;
      if (i == day - 1) {
        entity.BOLLMA = ma / day;
      } else if (i >= day) {
        ma -= dataList[i - day].close;
        entity.BOLLMA = ma / day;
      } else {
        entity.BOLLMA = null;
      }
    }
  }

  /// 计算 MACD 指标（指数平滑异同移动平均线）
  /// MACD 是最常用的趋势指标之一
  ///
  /// 计算公式：
  /// 1. EMA(12) = 前一日 EMA(12) × 11/13 + 今日收盘价 × 2/13
  /// 2. EMA(26) = 前一日 EMA(26) × 25/27 + 今日收盘价 × 2/27
  /// 3. DIF = EMA(12) - EMA(26)  [快线]
  /// 4. DEA = 前一日 DEA × 8/10 + 今日 DIF × 2/10  [慢线，也叫信号线]
  /// 5. MACD = (DIF - DEA) × 2  [柱状图]
  ///
  /// 用法：
  /// - DIF 上穿 DEA：金叉，买入信号
  /// - DIF 下穿 DEA：死叉，卖出信号
  /// - MACD 柱状图：反映多空力量强弱
  static void calcMACD(List<KLineEntity> dataList) {
    double ema12 = 0; // 12 日指数移动平均
    double ema26 = 0; // 26 日指数移动平均
    double dif = 0; // 差离值（快线）
    double dea = 0; // 信号线（慢线）
    double macd = 0; // MACD 柱状图

    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      final closePrice = entity.close;

      if (i == 0) {
        // 第一天：EMA 初始值设为收盘价
        ema12 = closePrice;
        ema26 = closePrice;
      } else {
        // EMA 计算公式：
        // EMA(n) = 前一日 EMA × (n-1)/(n+1) + 今日价格 × 2/(n+1)
        ema12 = ema12 * 11 / 13 + closePrice * 2 / 13; // n=12: (12-1)/(12+1)=11/13
        ema26 = ema26 * 25 / 27 + closePrice * 2 / 27; // n=26: (26-1)/(26+1)=25/27
      }

      // 计算 DIF（快线）
      dif = ema12 - ema26;

      // 计算 DEA（慢线）：DIF 的 9 日 EMA
      // DEA = 前一日 DEA × 8/10 + 今日 DIF × 2/10
      dea = dea * 8 / 10 + dif * 2 / 10;

      // 计算 MACD 柱状图
      macd = (dif - dea) * 2;

      // 保存计算结果
      entity.dif = dif;
      entity.dea = dea;
      entity.macd = macd;
    }
  }

  static void calcVolumeMA(List<KLineEntity> dataList) {
    double volumeMa5 = 0;
    double volumeMa10 = 0;

    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entry = dataList[i];

      volumeMa5 += entry.vol;
      volumeMa10 += entry.vol;

      if (i == 4) {
        entry.MA5Volume = (volumeMa5 / 5);
      } else if (i > 4) {
        volumeMa5 -= dataList[i - 5].vol;
        entry.MA5Volume = volumeMa5 / 5;
      } else {
        entry.MA5Volume = 0;
      }

      if (i == 9) {
        entry.MA10Volume = volumeMa10 / 10;
      } else if (i > 9) {
        volumeMa10 -= dataList[i - 10].vol;
        entry.MA10Volume = volumeMa10 / 10;
      } else {
        entry.MA10Volume = 0;
      }
    }
  }

  static void calcRSI(List<KLineEntity> dataList) {
    double? rsi;
    double rsiABSEma = 0;
    double rsiMaxEma = 0;
    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      final double closePrice = entity.close;
      if (i == 0) {
        rsi = 0;
        rsiABSEma = 0;
        rsiMaxEma = 0;
      } else {
        double rMax = max(0, closePrice - dataList[i - 1].close.toDouble());
        double rAbs = (closePrice - dataList[i - 1].close.toDouble()).abs();

        rsiMaxEma = (rMax + (14 - 1) * rsiMaxEma) / 14;
        rsiABSEma = (rAbs + (14 - 1) * rsiABSEma) / 14;
        rsi = (rsiMaxEma / rsiABSEma) * 100;
      }
      if (i < 13) rsi = null;
      if (rsi != null && rsi.isNaN) rsi = null;
      entity.rsi = rsi;
    }
  }

  static void calcKDJ(List<KLineEntity> dataList) {
    var preK = 50.0;
    var preD = 50.0;
    final tmp = dataList.first;
    tmp.k = preK;
    tmp.d = preD;
    tmp.j = 50.0;
    for (int i = 1; i < dataList.length; i++) {
      final entity = dataList[i];
      final n = max(0, i - 8);
      var low = entity.low;
      var high = entity.high;
      for (int j = n; j < i; j++) {
        final t = dataList[j];
        if (t.low < low) {
          low = t.low;
        }
        if (t.high > high) {
          high = t.high;
        }
      }
      final cur = entity.close;
      var rsv = (cur - low) * 100.0 / (high - low);
      rsv = rsv.isNaN ? 0 : rsv;
      final k = (2 * preK + rsv) / 3.0;
      final d = (2 * preD + k) / 3.0;
      final j = 3 * k - 2 * d;
      preK = k;
      preD = d;
      entity.k = k;
      entity.d = d;
      entity.j = j;
    }
  }

  static void calcWR(List<KLineEntity> dataList) {
    double r;
    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      int startIndex = i - 14;
      if (startIndex < 0) {
        startIndex = 0;
      }
      double max14 = double.minPositive;
      double min14 = double.maxFinite;
      for (int index = startIndex; index <= i; index++) {
        max14 = max(max14, dataList[index].high);
        min14 = min(min14, dataList[index].low);
      }
      if (i < 13) {
        entity.r = -10;
      } else {
        r = -100 * (max14 - dataList[i].close) / (max14 - min14);
        if (r.isNaN) {
          entity.r = null;
        } else {
          entity.r = r;
        }
      }
    }
  }

  static void calcCCI(List<KLineEntity> dataList) {
    final size = dataList.length;
    final count = 14;
    for (int i = 0; i < size; i++) {
      final kline = dataList[i];
      final tp = (kline.high + kline.low + kline.close) / 3;
      final start = max(0, i - count + 1);
      var amount = 0.0;
      var len = 0;
      for (int n = start; n <= i; n++) {
        amount += (dataList[n].high + dataList[n].low + dataList[n].close) / 3;
        len++;
      }
      final ma = amount / len;
      amount = 0.0;
      for (int n = start; n <= i; n++) {
        amount +=
            (ma - (dataList[n].high + dataList[n].low + dataList[n].close) / 3)
                .abs();
      }
      final md = amount / len;
      kline.cci = ((tp - ma) / 0.015 / md);
      if (kline.cci!.isNaN) {
        kline.cci = 0.0;
      }
    }
  }
}
