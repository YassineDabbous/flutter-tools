import 'package:core/core.dart';
import 'package:flutter/widgets.dart';

/// Contract for modular feature registration.
abstract class ModuleConfig {
  /// Register services, Cubits, etc. into the DI container.
  void register(Injector i);

  /// Return a list of BlocProviders or other providers to be added to the widget tree.
  List<Widget> get providers => [];
}
