import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

class NumberFormatCore {
  NumberFormatCore._();

  static final Map<String, NumberFormat> _cache = {};
  static final _chineseMarketUnits = [
    (threshold: Decimal.parse('1e12'), shift: 12, suffix: '万亿'),
    (threshold: Decimal.parse('1e8'), shift: 8, suffix: '亿'),
    (threshold: Decimal.parse('1e4'), shift: 4, suffix: '万'),
  ];
  static final _internationalMarketUnits = [
    (threshold: Decimal.parse('1e12'), shift: 12, suffix: 'T'),
    (threshold: Decimal.parse('1e9'), shift: 9, suffix: 'B'),
    (threshold: Decimal.parse('1e6'), shift: 6, suffix: 'M'),
    (threshold: Decimal.parse('1e3'), shift: 3, suffix: 'K'),
  ];

  /// 千分位分隔符
  /// [value] 值
  /// [locale] 语言
  /// [fractionDigits] 小数位数
  /// 返回千分位分隔符
  /// 示例：1000 -> "1,000"
  /// 示例：1000.1234567890 -> "1,000.1234"
  static String thousand(
    dynamic value, {
    String? locale,
    int fractionDigits = 0,
  }) {
    if (fractionDigits < 0) {
      throw ArgumentError.value(
        fractionDigits,
        'fractionDigits',
        'must be non-negative',
      );
    }

    final decimal = _parseDecimal(value);
    if (decimal == null) return '-';

    return _withThousands(_truncate(decimal, fractionDigits));
  }

  /// 紧凑型格式
  /// [value] 值
  /// [locale] 语言
  /// [fractionDigits] 小数位数
  /// 返回紧凑型格式
  /// 示例：1000 -> "1K"
  /// 示例：1000.1234567890 -> "1.0001K"
  /// 示例：1000000 -> "1M"
  /// 示例：1000000000 -> "1B"
  /// 示例：1000000000000 -> "1T"
  static String compact(num? value, {String? locale, int? fractionDigits}) {
    if (value == null) return '-';
    final key =
        '${locale ?? Intl.getCurrentLocale()}|COMPACT|${fractionDigits ?? -1}';
    final fmt = _cache.putIfAbsent(key, () {
      final f = NumberFormat.compact(locale: locale);
      if (fractionDigits != null) {
        f.maximumFractionDigits = fractionDigits;
        f.minimumFractionDigits = 0;
      }
      return f;
    });
    return fmt.format(value);
  }

  /// 市场资本格式
  /// [value] 值
  /// [symbol] 符号
  /// [locale] 语言
  /// 返回市场资本格式
  /// 示例：1000 -> "$1K"
  /// 示例：1000000 -> "$1M"
  /// 示例：1000000000 -> "$1B"
  /// 示例：1000000000000 -> "$1T"
  static String marketCap(
    dynamic value, {
    String symbol = r'$',
    String? locale,
    int fractionDigits = 2,
  }) {
    if (fractionDigits < 0) {
      throw ArgumentError.value(
        fractionDigits,
        'fractionDigits',
        'must be non-negative',
      );
    }
    final d = _parseDecimal(value);

    if (d == null || d == Decimal.zero) return '${symbol}0';

    final absolute = d.abs();
    final isChinese = _isChineseLocale(locale ?? Intl.getCurrentLocale());
    final units = isChinese ? _chineseMarketUnits : _internationalMarketUnits;

    var shift = 0;
    var suffix = '';
    for (final unit in units) {
      if (absolute >= unit.threshold) {
        shift = unit.shift;
        suffix = unit.suffix;
        break;
      }
    }

    // Every unit is a power of ten. Moving the decimal point is exact and
    // avoids Rational normalization on every live chart/header update.
    final q = d.shift(-shift);
    final out = _truncate(q, fractionDigits);
    final formatted = suffix.isEmpty ? _withThousands(out) : out;
    return '$symbol$formatted$suffix';
  }

  /// Formats a general UI number according to the amount display rules.
  ///
  /// This method is for presentation only. It intentionally accepts the raw
  /// value as a string so formatting does not introduce a lossy double round
  /// trip before truncation.
  static String amount(dynamic value, {int significantDigits = 4}) {
    if (significantDigits <= 0) {
      throw ArgumentError.value(
        significantDigits,
        'significantDigits',
        'must be greater than zero',
      );
    }

    final decimal = _parseDecimal(value);
    if (decimal == null || decimal == Decimal.zero) return '0';

    final negative = decimal < Decimal.zero;
    final absolute = decimal.abs();
    late final String formatted;

    if (absolute < Decimal.one) {
      final decimalPart = absolute.toString().split('.').elementAtOrNull(1);
      if (decimalPart == null || decimalPart.isEmpty) return '0';

      final firstNonZero = decimalPart.indexOf(RegExp(r'[1-9]'));
      if (firstNonZero < 0) return '0';

      if (firstNonZero >= 5) {
        final availableDigits = decimalPart.length - firstNonZero;
        final take = significantDigits < availableDigits
            ? significantDigits
            : availableDigits;
        final significant = decimalPart
            .substring(firstNonZero)
            .substring(0, take)
            .replaceAll(RegExp(r'0+$'), '');
        return '${negative ? '-' : ''}0.0${_toSubscript(firstNonZero)}$significant';
      }

      formatted = _truncate(absolute, firstNonZero + significantDigits);
    } else {
      final integerDigits = absolute.toBigInt().toString().length;
      final fractionDigits = integerDigits == 1
          ? significantDigits
          : integerDigits <= 4
          ? 2
          : 1;
      formatted = _withThousands(_truncate(absolute, fractionDigits));
    }

    return negative ? '-$formatted' : formatted;
  }

  /// Formats token quantities with localized units only when the value reaches
  /// the market-cap compact threshold. Smaller values keep the general amount
  /// rules so fractional token quantities do not lose significant digits.
  static String compactAmount(
    dynamic value, {
    String? locale,
    int significantDigits = 4,
  }) {
    final decimal = _parseDecimal(value);
    if (decimal == null || decimal == Decimal.zero) return '0';

    final resolvedLocale = locale ?? Intl.getCurrentLocale();
    final compactThreshold = _isChineseLocale(resolvedLocale)
        ? Decimal.parse('10000')
        : Decimal.parse('1000');

    if (decimal.abs() < compactThreshold) {
      return amount(decimal, significantDigits: significantDigits);
    }

    return marketCap(decimal, symbol: '', locale: resolvedLocale);
  }

  static Decimal? _parseDecimal(dynamic value) {
    if (value is num && !value.isFinite) return null;
    if (value is Decimal) return value;

    final rawValue = switch (value) {
      num() => value.toString(),
      String() => value.trim(),
      BigInt() => value.toString(),
      _ => '',
    };
    if (rawValue.isEmpty) return null;

    return Decimal.tryParse(rawValue);
  }

  static String priceSmart(
    dynamic value, {
    int maxDecimals = 4,
    String? locale,
  }) => amount(value, significantDigits: maxDecimals);

  /// 转换为下标
  /// [number] 数字
  /// 返回下标
  static String _toSubscript(int number) {
    const subscripts = ['₀', '₁', '₂', '₃', '₄', '₅', '₆', '₇', '₈', '₉'];
    return number
        .toString()
        .split('')
        .map((d) => subscripts[int.parse(d)])
        .join();
  }

  static String _truncate(Decimal value, int fractionDigits) {
    final scaled = value.shift(fractionDigits).toBigInt();
    final negative = scaled.isNegative;
    final digits = scaled.abs().toString();

    if (fractionDigits == 0) {
      return '${negative ? '-' : ''}$digits';
    }

    final padded = digits.padLeft(fractionDigits + 1, '0');
    final splitAt = padded.length - fractionDigits;
    final integerPart = padded.substring(0, splitAt);
    final decimalPart = padded
        .substring(splitAt)
        .replaceAll(RegExp(r'0+$'), '');
    final result = decimalPart.isEmpty
        ? integerPart
        : '$integerPart.$decimalPart';
    return negative ? '-$result' : result;
  }

  static String _withThousands(String value) {
    final negative = value.startsWith('-');
    final unsigned = negative ? value.substring(1) : value;
    final parts = unsigned.split('.');
    final integerPart = parts.first;
    final grouped = integerPart.replaceAllMapped(
      RegExp(r'(?<!^)(?=(\d{3})+$)'),
      (_) => ',',
    );
    final result = parts.length == 1 ? grouped : '$grouped.${parts[1]}';
    return negative ? '-$result' : result;
  }

  static bool _isChineseLocale(String locale) {
    final languageCode = locale.toLowerCase().split(RegExp(r'[-_]')).first;
    return languageCode == 'zh';
  }

  static void clearLocale(String locale) {
    _cache.removeWhere((key, value) => key.startsWith('$locale|'));
  }
}
