import 'package:intl/intl.dart';

/// Extensions for the [String] class.
extension StringExtensions on String {
  /// Returns true if the string can be parsed as a number.
  bool get isNumeric => num.tryParse(this) != null;

  /// Parses the string as ISO 8601, converts to local time, and formats it
  /// into a human-readable "Month d, yyyy at h:mm a" format.
  String formatHumanReadableDate() {
    try {
      final dateTime = DateTime.parse(this).toLocal();
      final dateFormatter = DateFormat('MMMM d, yyyy');
      final timeFormatter = DateFormat('h:mm a');
      return '${dateFormatter.format(dateTime)} at ${timeFormatter.format(dateTime)}';
    } catch (e) {
      return this;
    }
  }
}
