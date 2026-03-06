# core

> **Pure foundation for the SDK framework. Backend-agnostic.**

The `core` package is the lowest layer in the SDK. Every other package depends on it. It provides dependency injection, authentication management, app configuration, routing, shared state (themes/fonts/language), failure types, and utility extensions.

---

## Table of Contents

- [Dependency Injection](#dependency-injection)
- [App Configuration](#app-configuration)
- [Environment Config](#environment-config)
- [Module System](#module-system)
- [Registrar](#registrar)
- [Service Initializer](#service-initializer)
- [Authentication](#authentication)
- [Failures](#failures)
- [Shared BLoCs](#shared-blocs)
- [Routing](#routing)
- [Contracts](#contracts)
- [Local Storage](#local-storage)
- [Extensions](#extensions)
- [Crash Reporting](#crash-reporting)

---

## Dependency Injection

The SDK uses a central `Core` static class as the entry point for all services.

### `Core` class

```dart
// Register a dependency
Core.i.addSingleton<MyService>(() => MyServiceImpl());

// Retrieve a dependency
final service = Core.get<MyService>();

// Navigation
Core.nav.push('/users');

// Current BuildContext
final ctx = Core.ctx;
```

### `Injector` interface

```dart
abstract class Injector {
  T get<T>({String? key});
  void add<T>(T Function() constructor, {String? key});
  void addInstance<T>(T instance, {String? key});
  void addSingleton<T>(T Function() constructor, {String? key});
  void addLazySingleton<T>(T Function() constructor, {String? key});
  void commit();
}
```

The default implementation (`DefaultInjector`) wraps the `injector` package. You can swap it out by implementing `Injector`.

---

## App Configuration

### `Config` (abstract)

Subclass `Config` to define environment-specific settings:

```dart
class AppConfig extends Config {
  @override
  String get appName => 'My App';

  @override
  String get baseUrl => 'https://api.myapp.com/v1';

  @override
  List<CustomLang> get supportedLocales => [
    CustomLang('English', Locale('en', 'US')),
    CustomLang('Arabic', Locale('ar', 'SA')),
  ];

  @override
  List<CustomTheme> get themes => [
    CustomTheme('Light', ThemeData.light()),
    CustomTheme('Dark', ThemeData.dark()),
  ];
}
```

**Key properties:**

| Property | Type | Description |
|----------|------|-------------|
| `baseUrl` | `String` | Base API URL |
| `appID` | `int` | Tenant ID |
| `appName` | `String` | Display name |
| `supportedLocales` | `List<CustomLang>` | Supported languages |
| `themes` | `List<CustomTheme>` | Available UI themes |
| `oneSignalAppID` | `String` | Push notification key |
| `sentryDSN` | `String` | Crash reporting DSN |

---

## Environment Config

For multi-environment setups (dev/staging/prod):

```dart
final env = EnvConfig.dev(baseUrl: 'https://dev-api.myapp.com');
// or
final env = EnvConfig.prod(baseUrl: 'https://api.myapp.com');
```

---

## Module System

### `ModuleConfig` (abstract)

Use `ModuleConfig` to register feature-specific dependencies as self-contained modules:

```dart
class UserModule extends ModuleConfig {
  @override
  void register(Injector i) {
    i.addSingleton<UserApiService>(() => UserApiServiceImpl(dio));
    i.addSingleton<UserCubit>(() => UserCubit());
  }

  @override
  List<Widget> get providers => [
    BlocProvider<UserCubit>(create: (_) => Core.get<UserCubit>()),
  ];
}
```

---

## Registrar

### `Registrar` (abstract)

The application's root dependency registration class. Subclass it and override `register()`:

```dart
class AppRegistrar extends Registrar {
  @override
  void register() {
    // Core services are already registered by super.init()
    // Register app-specific dependencies here:
    Core.i.addSingleton<ProductApiService>(() => ProductApiServiceImpl(dio));
  }
}
```

**Auto-registered by `Registrar.init()`:**
- `AuthLocalManager`
- `AuthenticationCubit`
- `AuthCheckerCubit`
- `SharedPrefHelper`

---

## Service Initializer

### `I` (abstract)

An interface for services that need lifecycle management tied to authentication:

```dart
abstract class I {
  Future init();          // App startup
  void refresh();         // Re-read state
  void activate({required AuthResponse user});   // User logged in
  void deactivate({AuthResponse? user});         // User logged out
}
```

---

## Authentication

### Data Models

```dart
class AuthUser<ID> {
  ID id;
  String type;
  String name;
  String? photo;
}

class AuthResponse<ID> {
  AuthUser<ID> user;
  String token;
  List<String> abilities;    // Token abilities (e.g. '*')
  List<dynamic> permissions; // User permissions
}
```

**Authorization helpers:**
```dart
auth.hasAbilityTo('create-post');    // Check token ability
auth.hasPermissionTo('admin');       // Check user permission
```

### `AuthLocalManager`

Manages local persistence of auth data. Supports multi-profile (account switching):

```dart
final manager = Core.get<AuthLocalManager>();
manager.check();               // Is user logged in?
manager.guest();               // Is user a guest?
await manager.getCurrentUser();// Load saved user
await manager.setAuth(auth);   // Save primary login
await manager.setSwitchAccount(auth); // Switch profile
await manager.logout();        // Soft logout (keeps root token)
await manager.hardLogout();    // Full logout (clears everything)
```

### `AuthenticationCubit`

BLoC for managing authentication state in the widget tree:

```dart
Core.get<AuthenticationCubit>().login(auth);     // Login
Core.get<AuthenticationCubit>().logout();         // Soft logout
Core.get<AuthenticationCubit>().logoutHard();     // Hard logout
Core.get<AuthenticationCubit>().switchTo(auth);   // Account switch
```

**States:** `AuthenticationInitial`, `AuthenticationAuthenticated`, `AuthenticationLogout`, `AuthenticationLogoutHard`

---

## Failures

All application errors extend `AppFailure`:

| Failure | When |
|---------|------|
| `NetworkFailure` | No internet / timeout |
| `AuthFailure` | 401 Unauthorized |
| `ValidationFailure` | 422 with field errors |
| `ServerFailure` | 500+ server errors |
| `NotFoundFailure` | 404 Not found |
| `PermissionFailure` | 403 Forbidden |

```dart
try {
  await apiCall();
} catch (e) {
  if (e is ValidationFailure) {
    print(e.errors); // Map<String, dynamic>
  }
}
```

---

## Shared BLoCs

| BLoC | Purpose |
|------|---------|
| `ThemeBloc` | Switch between `Config.themes` |
| `LanguageBloc` | Switch language/locale |
| `FontBloc` | Switch font families |
| `IntroducerBloc` | Control onboarding/intro screens |

---

## Routing

### `AppNavigator` (abstract)

Navigation contract used by `Core.nav`:

```dart
Core.nav.push('/users');
Core.nav.pushNamed('/users/42');
Core.nav.queryParams(); // Get current query parameters
```

### `Routes`

Define route constants for type-safe navigation.

---

## Contracts

Abstract interfaces for platform-specific implementations (provided by `impl/` packages):

| Contract | Package implementing it |
|----------|------------------------|
| `Notifier` | `impl_notifier_onesignal` |
| `NetworkInfo` | `concrete` (network_checker) |
| `DeviceInfo` | `impl_device_info` |
| `Locator` | `impl_locator` |
| `FileField` | `file_picker` |

---

## Local Storage

### `SharedPrefHelper`

Wraps `shared_preferences` for simple key-value persistence:

```dart
final prefs = Core.get<SharedPrefHelper>();
prefs.set<String>('key', 'value');
prefs.get<String>('key');
```

---

## Extensions

Utility extensions available on common types:

| Extension | Adds to | Examples |
|-----------|---------|---------|
| `ContextExt` | `BuildContext` | `context.textTheme`, `context.mediaQuery` |
| `StringExt` | `String` | `.i18n()` translation |
| `MapExt` | `Map` | `.toDynamic` |
| `NumberExt` | `num` | Formatting helpers |
| `LoggerExt` | — | `logUI`, `logCtrl`, `logAuth` named loggers |

---

## Crash Reporting

Register a `CrashMessenger` implementation for error reporting:

```dart
Core.registerCrashMessenger(SentryCrashMessenger());
Core.reportError(error, stackTrace);
Core.logCrash('Something went wrong');
```

---

## Dynamic Headers

Register dynamic HTTP headers that providers will attach to requests:

```dart
Core.registerHeader('X-Custom', () async => await getCustomValue());
```
