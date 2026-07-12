import 'package:core/core.dart';
import 'package:flutter/foundation.dart';

/// Abstract class responsible for registering all application dependencies
/// with the [Core] service locator.
abstract class Registrar {
  const Registrar();

  /// Initializes the core service dependencies.
  @mustCallSuper
  Future init() async {
    // General local storage
    Core.i.addSingleton<SharedPrefHelper>(() => SharedPrefHelper());
    Core.i.addSingleton<SecureAuthStorage>(() => SecureAuthStorage());

    // Execute concrete implementation registration (Provider provides AuthLocalManager)
    register();

    // Auth managers (Cubits depend on registered AuthLocalManager)
    Core.i.addSingleton<AuthenticationCubit>(
      () => AuthenticationCubit(repository: Core.get<AuthLocalManager>()),
    );
    Core.i.add<AuthCheckerCubit>(
      () => AuthCheckerCubit(repository: Core.get<AuthLocalManager>()),
    );

    // Commit changes to the service locator
    Core.i.commit();
  }

  /// Abstract method to be implemented by the concrete application layer
  /// for registering app-specific dependencies.
  void register();
}
