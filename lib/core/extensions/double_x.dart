import 'package:intl/intl.dart';

extension DoubleX on double {
  /// Formats the value as Indian Rupees, e.g. "₹1,450.00".
  String get inr {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return formatter.format(this);
  }

  /// Compact currency, e.g. "₹1.2K", "₹45K", "₹1.5L".
  String get inrCompact {
    if (this >= 100000) return '₹${(this / 100000).toStringAsFixed(1)}L';
    if (this >= 1000) return '₹${(this / 1000).toStringAsFixed(1)}K';
    return '₹${toStringAsFixed(0)}';
  }

  /// Returns a string with two decimal places (no currency symbol).
  String get twoDecimal => toStringAsFixed(2);

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
