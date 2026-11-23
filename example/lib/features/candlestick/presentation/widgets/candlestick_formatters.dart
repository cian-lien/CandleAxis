import 'package:candle_axis/candle_axis.dart';

import '../../../../core/formatting/number_format_core.dart';

final _marketCapFormatters = <(String, String), PriceFormatter>{};

/// Retain exact Decimal formatting while avoiding repeated work on chart
/// repaint. Both caches are bounded; locale and currency symbol are isolated.
PriceFormatter marketCapFormatter(String locale, {String symbol = ''}) {
  final key = (locale, symbol);
  final existing = _marketCapFormatters[key];
  if (existing != null) return existing;
  if (_marketCapFormatters.length == 16) {
    _marketCapFormatters.remove(_marketCapFormatters.keys.first);
  }
  final values = <double, String>{};
  return _marketCapFormatters[key] = (value) {
    final cached = values[value];
    if (cached != null) return cached;
    final formatted = NumberFormatCore.marketCap(
      value,
      symbol: symbol,
      locale: locale,
    );
    if (values.length == 512) values.remove(values.keys.first);
    values[value] = formatted;
    return formatted;
  };
}

final englishPopupValueFormatters = PopupValueFormatters(
  marketCap: marketCapFormatter('en'),
  usd: marketCapFormatter('en', symbol: r'$'),
);
