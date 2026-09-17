/// Money/measurement formatters shared by every Rebelo app/module.
///
/// # Ownership rule
/// **Core is the only home.** Never copy `formatMoney`/`formatMmSs`/… into an
/// app or module — import from `package:core/core.dart`.
///
/// # Millimes vs major units
/// Rebelo amounts are stored in **millimes** (÷1000 = major). [formatMoney]
/// divides by 1000; use [formatMoneyFromMajor] for catalog/product prices
/// already stored in major units (`Product.price`, `CartItem.price`,
/// `ProductModifier.priceAdjustment`) to avoid double-dividing.
library;

import 'package:localization/localization.dart';

String formatMillimes(num? value) => ((value ?? 0) / 1000).toStringAsFixed(3);

/// Formats an amount in **millimes** (÷1000 → major).
///
/// Use [formatMoneyFromMajor] for catalog/product prices already in major
/// units (`Product.price`, `CartItem.price`, `ProductModifier.priceAdjustment`)
/// to avoid double-dividing. Order amounts/fares are millimes.
String formatMoney(num? value, {String? currency}) =>
    '${formatMillimes(value)} ${currency ?? 'TND'}';

/// Formats a value already expressed in **major currency units** (no ÷1000).
///
/// Catalog/product prices (`Product.price`, `CartItem.price`,
/// `ProductModifier.priceAdjustment`) are stored in major units, so they must
/// use this variant instead of [formatMoney] to avoid double-dividing by 1000.
String formatMoneyFromMajor(num? value, {String? currency}) =>
    '${(value ?? 0).toStringAsFixed(3)} ${currency ?? 'TND'}';

String formatKilos(int? grams) {
  if (grams == null) return '-';
  return grams >= 1000 ? '${(grams / 1000).toStringAsFixed(2)} kg' : '$grams g';
}

String formatCentimeters(int? mm) {
  if (mm == null) return '-';
  return mm % 10 == 0 ? '${mm ~/ 10} cm' : '${(mm / 10).toStringAsFixed(1)} cm';
}

String formatKilometers(int? meters) {
  if (meters == null) return '-';
  if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(2)} km';
  return '$meters m';
}

String formatMinutes(int? minutes) {
  if (minutes == null) return '-';
  return '$minutes ${'min'.i18n()}';
}

String formatEta(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final minutes = seconds ~/ 60;
  if (minutes < 60) return '${minutes}min';
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  return '${hours}h ${mins}min';
}

/// Formats a countdown/duration as `mm:ss` (e.g. `05:09`).
String formatMmSs(int seconds) {
  final minutes = seconds ~/ 60;
  final secs = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
}

String yesNo(dynamic value) =>
    value == true || value == 1 || value == '1' ? 'yes'.i18n() : 'no'.i18n();