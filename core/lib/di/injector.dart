/// Abstract contract for managing application dependencies.
///
/// Application services should depend on this interface, not the concrete implementation.
abstract class Injector {
  /// Retrieves a registered dependency.
  T get<T>({String? key});

  /// Registers a new factory function (non-singleton).
  void add<T>(T Function() constructor, {String? key});

  /// Registers an existing instance (non-singleton).
  void addInstance<T>(T instance, {String? key});

  /// Registers a dependency as a singleton (created immediately).
  void addSingleton<T>(T Function() constructor, {String? key});

  /// Registers a dependency as a lazy singleton (created on first access).
  void addLazySingleton<T>(T Function() constructor, {String? key});

  /// Commits pending registrations (if required by the underlying library).
  void commit();
}
