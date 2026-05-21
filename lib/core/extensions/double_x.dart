import 'package:intl/intl.dart';

extension DoubleX on double {
  /// Formats as Indian Rupees, stripping unnecessary decimal zeros.
  /// ₹10.00 → ₹10 | ₹10.50 → ₹10.5 | ₹10.55 → ₹10.55
  String get inr {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    final raw = formatter.format(this);
    // Strip trailing zeros after the decimal point, then a lone decimal.
    return raw.replaceAll(RegExp(r'\.?0+$'), '');
  }

  /// Compact currency: ₹1.2L, ₹45K, ₹850 (no unnecessary decimals).
  String get inrCompact {
    if (this >= 100000) {
      final v = this / 100000;
      return '₹${v == v.truncateToDouble() ? v.toInt() : v.toStringAsFixed(1)}L';
    }
    if (this >= 1000) {
      final v = this / 1000;
      return '₹${v == v.truncateToDouble() ? v.toInt() : v.toStringAsFixed(1)}K';
    }
    return inr;
  }

  /// Returns a numeric string with decimals only when needed.
  /// 10.00 → "10" | 10.50 → "10.5" | 10.55 → "10.55"
  String get smartDecimal => this == truncateToDouble()
      ? toInt().toString()
      : toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '');

  /// Clamps the value between [min] and [max] and returns a percentage 0–1.
  double progressOf(double min, double max) {
    if (max <= min) return 0;
    return ((this - min) / (max - min)).clamp(0.0, 1.0);
  }
}

extension NumX on num {
  bool get isPositive => this > 0;
  bool get isNegative => this < 0;
}
