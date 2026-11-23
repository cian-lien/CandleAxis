import 'package:flutter/material.dart';

import '../../../../core/enums/timeframe.dart';
import '../../../../l10n/l10n.dart' as app_l10n;

/// 时间周期的工具栏短标签（如「5分」「1周」），供外显按钮与更多按钮共用
extension TimeframeShortLabelX on Timeframe {
  String shortLabel(BuildContext context) {
    final remoteLabel = localizedLabel(
      Localizations.localeOf(context).languageCode,
    );
    if (remoteLabel != null && remoteLabel.isNotEmpty) return remoteLabel;
    final s = app_l10n.S.of(context);
    switch (this) {
      case Timeframe.s30:
        return s.chartPeriod30sec;
      case Timeframe.m1:
        return s.chartPeriod1min;
      case Timeframe.m3:
        return s.chartPeriod3min;
      case Timeframe.m5:
        return s.chartPeriod5min;
      case Timeframe.m15:
        return s.chartPeriod15min;
      case Timeframe.m30:
        return s.chartPeriod30min;
      case Timeframe.h1:
        return s.chartPeriod1hour;
      case Timeframe.h2:
        return s.chartPeriod2hour;
      case Timeframe.h4:
        return s.chartPeriod4hour;
      case Timeframe.h6:
        return s.chartPeriod6hour;
      case Timeframe.h12:
        return s.chartPeriod12hour;
      case Timeframe.d1:
        return s.chartPeriod1day;
      case Timeframe.w1:
        return s.chartPeriod1week;
      case Timeframe.mo1:
        return s.chartPeriod1month;
      case Timeframe.mo3:
        return s.chartPeriod3month;
      default:
        return '${duration.inSeconds}s';
    }
  }
}
