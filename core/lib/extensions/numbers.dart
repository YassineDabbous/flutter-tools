import 'package:intl/intl.dart';

/// Extensions for nullable [num] types.
extension NumxExtensions on num? {
  /// Checks if the number is null or zero.
  bool get isEmpty => this == null || this == 0;

  /// Checks if the number is not null and not zero.
  bool get isNotEmpty => !isEmpty;

  /// Formats the number as a currency string without a symbol (dinar style).
  String get dinar => this == null
      ? '-'
      : NumberFormat.simpleCurrency(name: '', decimalDigits: 0).format(this);
}
