import 'package:core/core.dart';
import 'package:flutter/material.dart';

/// Central static class providing easy access to core application services.
class Core {
  /// Global key used to access the current [NavigatorState] for service-level navigation.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Shortcut to the current [BuildContext].
  static BuildContext? get ctx => navigatorKey.currentContext;

  /// The static instance of the dependency injector.
  /// Initialized with the concrete implementation of [Injector].
  static final Injector i = DefaultInjector();

  /// Shortcut to retrieve a dependency from the injector.
  static T get<T>({String? key}) => i.get<T>(key: key);

  /// Shortcut to the registered application navigation service.
  static AppNavigator get nav => get<AppNavigator>();
}
