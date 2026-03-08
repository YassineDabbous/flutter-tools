import 'package:core/core.dart';
import 'package:flutter/material.dart';

typedef HeaderProvider = Future<String?> Function();

abstract class CrashMessenger {
  void report(dynamic error, StackTrace? stack);
  void log(String message);
}

/// ControlledState is widget state with a State manager `store` (usually a Bloc instance)
/// Central static class providing easy access to core application services.
class Core {
  /// Global key used to access the current [NavigatorState] for service-level navigation.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Shortcut to the current [BuildContext].
  static BuildContext? get ctx => navigatorKey.currentContext;

  /// The static instance of the dependency injector.
  /// Initialized with the concrete implementation of [Injector].
  static final Injector i = DefaultInjector();

  /// Shortcut to retrieve a dependency from the injector.
  static T get<T>({String? key}) => i.get<T>(key: key);

  /// Shortcut to the registered application navigation service.
  static AppNavigator get nav => get<AppNavigator>();

  // --- Dynamic Headers ---
  static String? appSlogan;
  static final Map<String, HeaderProvider> _dynamicHeaders = {};

  static void registerHeader(String key, HeaderProvider provider) {
    _dynamicHeaders[key] = provider;
  }

  static Map<String, HeaderProvider> get dynamicHeaders =>
      Map.unmodifiable(_dynamicHeaders);

  // --- Crash Reporting ---
  static CrashMessenger? _crashMessenger;

  static void registerCrashMessenger(CrashMessenger messenger) {
    _crashMessenger = messenger;
  }

  static void reportError(dynamic error, StackTrace? stack) {
    _crashMessenger?.report(error, stack);
  }

  static void logCrash(String message) {
    _crashMessenger?.log(message);
  }
}
