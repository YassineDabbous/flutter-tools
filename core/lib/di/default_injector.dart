import 'package:core/core.dart';
import 'package:injector/injector.dart' as package;

/// Concrete implementation of [Injector] using `package:injector`.
class DefaultInjector implements Injector {
  /// Static instance of the application-wide Injector.
  static final package.Injector _injector = package.Injector.appInstance;

  /// Retrieves a registered dependency.
  @override
  T get<T>({String? key}) => _injector.get<T>(dependencyName: key ?? '');

  /// Registers a new factory function (non-singleton).
  @override
  void add<T>(T Function() constructor, {String? key}) => _injector.registerDependency(constructor, dependencyName: key ?? '');

  /// Registers an existing instance (non-singleton).
  @override
  void addInstance<T>(T instance, {String? key}) => add(() => instance, key: key);

  /// Registers a dependency as a singleton (created immediately).
  @override
  void addSingleton<T>(T Function() constructor, {String? key}) => _injector.registerSingleton(constructor, dependencyName: key ?? '');

  /// Registers a dependency as a lazy singleton (created on first access).
  @override
  void addLazySingleton<T>(T Function() constructor, {String? key}) => _injector.registerSingleton(constructor, dependencyName: key ?? '');

  /// Commits pending registrations (no-op for this implementation).
  @override
  void commit() {}
}
