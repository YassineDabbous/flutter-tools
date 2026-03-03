import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart' as pp;

/// Utility class to manage and provide the application's document/cache path.
class AppPathProvider {
  AppPathProvider._();

  static String? _path;

  /// Retrieves the initialized path; throws if not initialized.
  static String get path {
    if (_path != null) return _path!;
    throw Exception('Path not initialized. Call initPath() first.');
  }

  /// Initializes the application document path based on the platform.
  static Future<void> initPath() async {
    if (kIsWeb) {
      _path = ''; // Empty path for web environments
      return;
    }
    final dir = await pp.getApplicationDocumentsDirectory();
    _path = dir.path;
  }
}
