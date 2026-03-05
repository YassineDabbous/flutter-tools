import 'package:core/core.dart';
import 'package:flutter/foundation.dart';

/// Abstract class responsible for registering all application dependencies
/// with the [Core] service locator.
abstract class Registrar {
  const Registrar();

  /// Initializes the core service dependencies.
  @mustCallSuper
  Future init() async {
    // Auth managers (Base implementation, providers should override if needed)
    Core.i.addSingleton<AuthLocalManager>(() => AuthLocalManager());
    Core.i.addSingleton<AuthenticationCubit>(() => AuthenticationCubit(repository: Core.get<AuthLocalManager>()));
    Core.i.add<AuthCheckerCubit>(() => AuthCheckerCubit(repository: Core.get<AuthLocalManager>()));

    // General local storage
    Core.i.addSingleton<SharedPrefHelper>(() => SharedPrefHelper());

    // Execute concrete implementation registration
    register();

    // Commit changes to the service locator
    Core.i.commit();
  }

  /// Abstract method to be implemented by the concrete application layer
  /// for registering app-specific dependencies.
  void register();
}
