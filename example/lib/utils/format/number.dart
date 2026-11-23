import 'package:decimal/decimal.dart';

import '../../core/formatting/number_format_core.dart';

/// Keep two decimal places for floating point numbers
/// Support String, double, int and other types as input
/// [decimals] Specify the number of decimal places to keep, default is 2
/// [removeTrailingZeros] Whether to remove trailing zeros, default is true
String formatDecimal(
  dynamic value, {
  int decimals = 2,
  bool removeTrailingZeros = true,
  String? symbol,
}) {
  if (value == null) return '0.00';

  // Convert to double
  double? numValue;
  if (value is String) {
    numValue = double.tryParse(value);
  } else if (value is num) {
    numValue = value.toDouble();
  }

  if (numValue == null) return '0.00';

  // Format to specified decimal places
  String result = numValue.toStringAsFixed(decimals);

  // Whether to remove trailing zeros
  if (removeTrailingZeros) {
    result = _removeTrailingZeros(result);
  }

  return result;
}

/// Format a value for UI display using the app amount rules.
///
/// The raw value is parsed as a decimal and truncated toward zero. This is a
/// presentation helper only; callers must keep the original value for
/// calculations, comparisons, filtering, and ordering.
String formatAmount(dynamic value, {int significantDigits = 4}) {
  return NumberFormatCore.amount(value, significantDigits: significantDigits);
}

/// Format token quantities with localized compact units for large values and
/// the general amount rules for values below the locale-specific threshold.
String formatCompactAmount(
  dynamic value, {
  String? locale,
  int significantDigits = 4,
}) {
  return NumberFormatCore.compactAmount(
    value,
    locale: locale,
    significantDigits: significantDigits,
  );
}

// _removeTrailingZeros function is the same as option one
String _removeTrailingZeros(String n) {
  if (!n.contains('.')) return n;
  String trimmed = n.replaceAll(RegExp(r'0+$'), '');
  if (trimmed.endsWith('.')) {
    return trimmed.substring(0, trimmed.length - 1);
  }
  return trimmed;
}

String convertMillisecondToSecond(double millisecond) {
  final str = (millisecond / 1000).toStringAsFixed(2);
  return str == '-0.00' ? '0.00' : str;
}

/// Format price with abbreviation for multiple zeros
///
/// [price] Price value.
/// [maxDecimals] Maximum number of decimal places, default is 4.
///
/// Returns the formatted price string.
///
/// Examples:
///   formatPrice(0.000123) => "0.000123" (3 significant digits)
///   formatPrice(0.0015412) => "0.001541" (4 significant digits)
///   formatPrice(0.00000176) => "0.0₅176" (5 zeros, subscript)
///   formatPrice(0.000000000123) => "0.0₉123" (9 zeros, subscript)
///   formatPrice(1.23) => "1.23"
///   formatPrice(0.1234567890) => "0.1235"
String formatPrice(dynamic price, {int maxDecimals = 4}) {
  return formatAmount(price, significantDigits: maxDecimals);
}

/// Format a token quantity for display.
///
/// Large quantities use localized compact units (K/M/B/T or 万/亿/万亿),
/// while smaller quantities follow the shared amount rules. The result never
/// includes a currency symbol or token name.
String formatQuantity(dynamic value, {String? locale}) {
  if (value is String && value.contains('%')) return value;
  return formatCompactAmount(value, locale: locale);
}

/// Format price with support for billion, ten million, million, thousand
// @Deprecated('请使用值.marketCap(context) 或 NumberFormatter.marketCap(value, ctx)')
// String formatPriceAdvanced(num price,
//     {int decimals = 2, String currencySymbol = ''}) {
//   if (price < 10000) {
//     return formatPrice(price);
//   }

//   if (price >= 100000000) {
//     double num = price / 100000000;
//     // Floor to avoid rounding up
//     int factor = 1;
//     for (int i = 0; i < decimals; i++) {
//       factor *= 10;
//     }
//     num = (num * factor).floor() / factor;
//     return '$currencySymbol${num.toStringAsFixed(decimals)}B'; // B for billion
//   } else if (price >= 10000000) {
//     // Support for ten million level
//     double num = price / 10000000;
//     // Floor to avoid rounding up
//     int factor = 1;
//     for (int i = 0; i < decimals; i++) {
//       factor *= 10;
//     }
//     num = (num * factor).floor() / factor;
//     return '$currencySymbol${num.toStringAsFixed(decimals)}千W'; // Ten million
//   } else if (price >= 1000000) {
//     // Support for million level
//     double num = price / 1000000;
//     // Floor to avoid rounding up
//     int factor = 1;
//     for (int i = 0; i < decimals; i++) {
//       factor *= 10;
//     }
//     num = (num * factor).floor() / factor;
//     return '$currencySymbol${num.toStringAsFixed(decimals)}M'; // M for million
//   } else if (price >= 10000) {
//     double num = price / 10000;
//     // Floor to avoid rounding up
//     int factor = 1;
//     for (int i = 0; i < decimals; i++) {
//       factor *= 10;
//     }
//     num = (num * factor).floor() / factor;
//     return '$currencySymbol${num.toStringAsFixed(decimals)}W'; // W for ten thousand
//   } else {
//     // For numbers less than 10,000, use NumberFormat to add thousand separators
//     final formatter = NumberFormat('#,##0.##');
//     return '$currencySymbol${formatter.format(price)}';
//   }
// }

/// Format number to keep exactly 4 decimal places, but remove trailing zeros
/// Examples:
///   formatToFourDecimals(1.2345) => "1.2345"
///   formatToFourDecimals(1.2300) => "1.23"
///   formatToFourDecimals(1.0000) => "1"
///   formatToFourDecimals(0.123456) => "0.1235"
// String formatToFourDecimals(dynamic value) {
//   if (value == null) return '0';

//   // Convert to double
//   double? numValue;
//   if (value is String) {
//     numValue = double.tryParse(value);
//   } else if (value is num) {
//     numValue = value.toDouble();
//   }

//   if (numValue == null) return '0';

//   // Format to 4 decimal places first
//   String result = numValue.toStringAsFixed(4);

//   // Remove trailing zeros and unnecessary decimal point
//   result = result.replaceAll(RegExp(r'\.?0+$'), '');

//   return result;
// }

@Deprecated('请使用值.marketCap(context) 或 NumberFormatter.marketCap(value, ctx)')
String formatPriceEnglish(dynamic value) {
  // 支持 double, int, String 类型
  Decimal? decimalValue;

  if (value is num) {
    decimalValue = Decimal.parse(value.toString());
  } else if (value is String) {
    decimalValue = Decimal.tryParse(value);
    if (decimalValue == null) return '\$0';
  } else {
    return '\$0';
  }

  // (1) 极小值判断
  if (decimalValue < Decimal.parse('0.001')) {
    return '\$0';
  }

  String suffix = '';
  Decimal divisor = Decimal.one;

  final trillion = Decimal.parse('1000000000000');
  final billion = Decimal.parse('1000000000');
  final million = Decimal.parse('1000000');
  final thousand = Decimal.parse('1000');

  // (2) 数值后加符号
  if (decimalValue >= trillion) {
    suffix = 'T';
    divisor = trillion;
  } else if (decimalValue >= billion) {
    suffix = 'B';
    divisor = billion;
  } else if (decimalValue >= million) {
    suffix = 'M';
    divisor = million;
  } else if (decimalValue >= thousand) {
    suffix = 'K';
    divisor = thousand;
  }

  final formattedDecimal = decimalValue / divisor;
  double formattedValue = formattedDecimal.toDouble();

  // (3) 优化小数点展示
  String result;
  if (formattedValue < 1 && formattedValue >= 0.001) {
    result = formattedValue.toStringAsFixed(3);
  } else if (formattedValue < 100) {
    formattedValue = (formattedValue * 100).round() / 100;
    result = formattedValue.toString();
    if (result.endsWith('.0')) {
      result = result.substring(0, result.length - 2);
    }
  } else {
    formattedValue = (formattedValue * 10).round() / 10;
    result = formattedValue.toString();
    if (result.endsWith('.0')) {
      result = result.substring(0, result.length - 2);
    }
  }

  // 移除不必要的小数点后的0
  if (result.contains('.')) {
    result = result.replaceAll(RegExp(r'0*$'), '');
    if (result.endsWith('.')) {
      result = result.substring(0, result.length - 1);
    }
  }

  return '\$$result$suffix';
}
