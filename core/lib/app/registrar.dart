import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Abstract class responsible for registering all application dependencies
/// with the [Core] service locator.
abstract class Registrar {
  const Registrar();

  /// Initializes the core service dependencies.
  ///
  /// This method registers singleton instances for core managers and BLoCs,
  /// and sets up services like Dio for networking.
  @mustCallSuper
  // @protected
  Future init() async {
    // Auth managers
    Core.i.addSingleton<AuthLocalManager>(() => AuthLocalManager());
    Core.i.addSingleton<AuthenticationCubit>(() => AuthenticationCubit(repository: Core.get<AuthLocalManager>()));
    Core.i.add<AuthCheckerCubit>(() => AuthCheckerCubit(repository: Core.get<AuthLocalManager>()));

    // General local storage
    Core.i.addSingleton<SharedPrefHelper>(() => SharedPrefHelper());

    // Networking Services
    //Core.i.addSingleton<AuthInterceptor>(() => AuthInterceptor(Core.get<Config>(), Core.get<AuthLocalManager>(), Core.get<SharedPrefHelper>()));
    Core.i.add<BaseDio>(() => BaseDio(customInterceptors: appInterceptors));

    // Core.i.add<ActionApiService>(() => ActionApiService.instance());
    // Core.i.add<ActionCubit>(() => ActionCubit());

    // Execute concrete implementation registration
    register();

    // Commit changes to the service locator
    Core.i.commit();
  }

  /// An abstract getter that can be overrided by the final application's registrar.
  ///
  /// This "hook" allows the application to provide its own list of custom
  /// Dio interceptors. These will be added to the Dio client *in addition* to the
  /// core interceptors (logging, caching).
  ///
  /// The app can return an empty list if no extra interceptors are needed.
  List<Interceptor> get appInterceptors => [
    // The app can still use the default AuthInterceptor from core...
    AuthInterceptor(Core.get<Config>(), Core.get<AuthLocalManager>(), Core.get<SharedPrefHelper>()),

    // ...and add its own separate, specialized interceptors.
    // AnalyticsInterceptor(),
    // RetryInterceptor(),
  ];

  /// Abstract method to be implemented by the concrete application layer
  /// for registering app-specific dependencies.
  void register();
}
