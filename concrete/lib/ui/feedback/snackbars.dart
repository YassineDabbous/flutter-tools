import 'package:flutter/material.dart';

/// Helper for showing specialized Snackbars.
class AppSnackbars {
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, Colors.green, Icons.check_circle_outline);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, Colors.red, Icons.error_outline);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, Colors.blue, Icons.info_outline);
  }

  static void showWarning(BuildContext context, String message) {
    _show(context, message, Colors.orange, Icons.warning_amber_outlined);
  }

  static void _show(BuildContext context, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }
}
