# `core` Package

> The foundational layer of the SDK. Every other package depends on `core`.

---

## Module Overview

| Module | Purpose |
|--------|---------|
| `di/` | Dependency injection contract and default implementation |
| `http/` | Dio HTTP client, caching, interceptors, file uploads, exceptions |
| `auth/` | Authentication models, local storage, BLoC state management, UI guards |
| `blocs/` | App-wide Cubits: theme, language, font size, onboarding |
| `router/` | Navigation abstraction (`AppNavigator`, `NavRoute`, `R` route definitions) |
| `storage/` | SharedPreferences wrapper with generic type-safe get/set |
| `contracts/` | Abstract interfaces for platform-dependent services |
| `extensions/` | Dart extension methods (context, strings, numbers, maps, logging) |
| `constants/` | Enums and constants (actions, file types, sizing tokens) |
| `app/` | App-level abstractions (Config, Registrar, Initializer, ControlledState) |

---

## `Core` — The Service Locator Entry Point

```dart
import 'package:core/core.dart';

// Access the injector
Core.i.addSingleton<MyService>(() => MyService());

// Retrieve a dependency
final myService = Core.get<MyService>();

// Access the navigator
Core.nav.push('/products/1');

// Access current BuildContext
final ctx = Core.ctx;
```

**Key properties:**

| Property | Type | Description |
|----------|------|-------------|
| `Core.i` | `Injector` | The global dependency injector instance |
| `Core.get<T>()` | `T` | Shortcut to `Core.i.get<T>()` |
| `Core.nav` | `AppNavigator` | The registered navigation service |
| `Core.ctx` | `BuildContext?` | Current context via the navigator key |
| `Core.navigatorKey` | `GlobalKey<NavigatorState>` | Global navigator key for service-level access |

---

## Dependency Injection (`di/`)

### `Injector` — Abstract Contract

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

### `DefaultInjector` — Concrete Implementation

Uses the `injector` pub package under the hood. Registered as `Core.i` at startup.

### Registration Methods

| Method | Lifecycle | When Created |
|--------|-----------|-------------|
| `add<T>()` | Factory (new instance per call) | On each `get<T>()` |
| `addInstance<T>()` | Wrapper over `add()` | Pre-existing instance |
| `addSingleton<T>()` | Singleton | Immediately |
| `addLazySingleton<T>()` | Lazy singleton | On first `get<T>()` |

---

## HTTP Layer (`http/`)

### `BaseDio` — Configured Dio Client

```dart
// Registration (done by Registrar)
Core.i.add<BaseDio>(() => BaseDio(customInterceptors: appInterceptors));

// Usage in API services
final dio = Core.get<BaseDio>().dio;

// Get instance with main account auth token applied
final authedDio = BaseDio.auth();
```

**Built-in interceptors (applied automatically):**

1. **Custom app interceptors** — Passed via the `customInterceptors` parameter
2. **`PrettyLogInterceptor`** — Debug-mode HTTP logging (skips `home` and `customization` endpoints)
3. **`DioCacheInterceptor`** — Hive-backed response caching

### `AuthInterceptor` — Automatic Header Injection

Injects on every request:
- `Accept: application/json`
- `Tenant-Id: {config.appID}`
- `Accept-Language: {selectedLocale}`
- `Authorization: Bearer {token}` (if authenticated)

### `Cache` — HTTP Response Caching

```dart
// Clear all cache
await Cache.clear();

// Clear low-priority cache only
await Cache.clearLowRequests();

// Get cache options for daily-stale requests
final options = Cache.daily;
```

**Default policy:** `CachePolicy.request` with 1-day max stale and high priority.

### File Uploads — `superRequest` / `superRequestTransform`

For multipart/form-data uploads with Laravel-style method spoofing:

```dart
// Mix regular fields and file uploads seamlessly
await superRequestTransform(
  dio: dio,
  path: 'products',
  method: 'POST',
  baseUrl: null,
  fieldsAndFiles: {
    'name': 'Widget',
    'price': 29.99,
    'image': FileField(name: 'image', type: FileType.IMAGE, data: bytes),
  },
);
```

> [!NOTE]
> `superRequestTransform` and the associated method spoofing are primarily designed for compatibility with Laravel backends (provided by `laravel_provider`).

**Key behaviors:**
- `PUT`/`PATCH` are spoofed as `POST` with a `_method` field (Laravel compatibility)
- Lists use `ListFormat.multiCompatible` encoding

### `FileField` — File Upload Model

```dart
final file = FileField(
  name: 'avatar',
  type: FileType.IMAGE,
  data: imageBytes,     // Uint8List
  fullUrl: null,        // null for new uploads
);

// Check if file exists on server
file.isOnline; // true if fullUrl != null

// Mark for deletion on update
file.shouldBeRemoved = true;

// Convert to Dio MultipartFile
final part = file.formPart(); // MapEntry<String, MultipartFile>?
```

### `FileFieldConverter` — JSON Serialization

```dart
class Product {
  @FileFieldConverter(name: 'image', type: FileType.IMAGE)
  FileField image;

  @FileFieldConverter.justForUrl()
  FileField thumbnail;
}
```

### `AppPathProvider` — Application Document Path

```dart
// Must be called before Cache initialization
await AppPathProvider.initPath();

// Access the path
final path = AppPathProvider.path;
```

### Custom Exceptions

| Exception | HTTP Code | Message |
|-----------|-----------|---------|
| `AuthException` | 401 | 🙃 Login first! |
| `PermissionException` | 403 | ⛔ Unauthorized, need permission |
| `NotFoundException` | 404 | 😵‍💫 Data not found. |
| `ValidationException` | 422 | Contains field-specific `bag` map |
| `ClientException` | 4xx | 😏 Client error occurred. |
| `ServerException` | 5xx | 🤔 Server error occurred. |
| `NoInternetException` | — | 🙄 No internet connection! |
| `CacheException` | — | Generic cache failure |

---

## Authentication (`auth/`)

### Data Models

**`AuthResponse`** — The root authentication payload:
```dart
class AuthResponse {
  AuthUser user;
  String token;
  List<String> abilities;
  List<int> permissions;
}
```

**`AuthUser`** — The user profile:
```dart
class AuthUser {
  int id;
  String type;
  String name;
  String? photo;
  String get photoUrl; // Falls back to default avatar
}
```

**`Authorization` Extension** — Permission helpers:
```dart
authResponse.hasAbilityTo('content_creator'); // true/false
authResponse.hasPermissionTo(42);             // true/false
```

### `AuthLocalManager` — Dual-Token Persistence

Manages two tokens:
1. **Active profile token** (`currentUser.token`) — The currently selected account
2. **Root token** (`realToken`) — The main login token, used for switching between profiles

```dart
// Global accessor functions
final manager = auth();               // Shortcut to AuthLocalManager
final currentUser = await user();      // Get current user or null

// Login flow
await manager.setAuth(authResponse);          // Saves both tokens
await manager.setSwitchAccount(authResponse); // Updates active only

// Logout
await manager.logout();     // Soft: clears active profile, keeps root token
await manager.hardLogout();  // Hard: clears everything

// Check state
manager.check();  // true if logged in
manager.guest();  // true if not logged in

// Update user info locally
await manager.updateCurrentUser(name: 'New Name', photo: 'url');
```

### `AuthenticationCubit` — Auth State Management

| Method | Effect | State Emitted |
|--------|--------|---------------|
| `login(auth)` | Saves auth + root token | `AuthenticationAuthenticated` |
| `switchTo(auth)` | Saves new profile only | `AuthenticationAuthenticated` |
| `logout()` | Clears active profile | `AuthenticationLogout` |
| `logoutHard()` | Clears all tokens | `AuthenticationLogoutHard` |

### `AuthCheckerCubit` — Startup Auth Verification

Used at app launch to determine the initial auth state:

| State | Condition |
|-------|-----------|
| `AuthIdentified` | Root token exists AND current user data exists |
| `AuthNotIdentified(hard: true)` | No root token at all |
| `AuthNotIdentified(hard: false)` | Root token exists but no active profile |
| `AuthCheckingFailure` | Error reading SharedPreferences |

### Auth UI Widgets

**`AppWrapper`** — Top-level listener for global auth state changes:
```dart
// Wrap your MaterialApp with this
AppWrapper(child: MaterialApp(...))
```
When auth state changes, it automatically:
- Redirects to home on login (if currently on a guest route)
- Calls `I.activate(user:)` / `I.deactivate()` for service lifecycle
- Redirects to login on logout

**`Authenticity`** — Route-level auth guard:
```dart
// Hard mode: forces redirection
Authenticity.hard(child: ProtectedScreen())

// Soft mode: shows Guest widget if not authenticated
Authenticity.soft(
  guest: LoginPrompt(),
  onChecked: (user) => print(user?.name),
  condition: (auth) => auth.hasAbilityTo('admin'),
  child: AdminPanel(),
)
```

**`Guest`** — Default fallback widget showing a "Login" button.

---

## BLoCs (`blocs/`)

All BLoCs use `SharedPrefHelper` for persistence and `Core.get<Config>()` for configuration.

### `ThemeBloc`

```dart
// Switch theme
themeBloc.setTheme(1);

// Get current theme data
themeBloc.state.theme.themeData; // ThemeData
themeBloc.state.theme.name;      // String
```

### `LanguageBloc`

```dart
// Switch language
languageBloc.setLang(1);

// Get available languages
LanguageBloc.languages; // Iterable<CustomLang>

// Get current locale
languageState.getLocale(); // CustomLang with name + Locale
```

### `FontBloc`

```dart
fontBloc.setFont(18); // Set font size
fontBloc.state.size;  // int (default: 16)
```

### `IntroducerBloc` — Onboarding Status

```dart
// Skip onboarding
introducerBloc.skipOnboarding();

// Check status
if (state is IntroducerLoadedState) {
  state.introducer.onboarding; // true if completed
}
```

---

## Router (`router/`)

### `AppNavigator` — Navigation API

```dart
final nav = Core.nav;

// Navigate (replace all)
nav.navigate('/home');

// Push
nav.push('/products/1');
nav.pushNamed('product', pathParams: {'id': '1'});
nav.pushRoute(MaterialPageRoute(builder: (_) => Screen()));

// Pop
nav.pop();
nav.canPop();
nav.popUntil((route) => route.isFirst);

// Replace
nav.pushReplacement('/login');
nav.pushReplacementNamed('login');
nav.popAndPushNamed('/settings');
```

> **Note:** `AppNavigator` provides base implementations using Flutter's Navigator. Methods like `push()`, `pushReplacement()`, and `queryParams()` throw `UnimplementedError` and are meant to be overridden by `impl/nav_go_router` or `impl/nav_modular`.

### `NavRoute` — Route Definition Model

```dart
NavRoute(
  path: '/products',
  name: 'Products',
  icon: Icons.inventory,
  selectedIcon: Icons.inventory_2,
  isPrimary: true,
  builder: (context, state) => ProductsScreen(),
  routes: [
    NavRoute(
      path: ':id',
      name: 'Product Details',
      builder: (context, state) => ProductDetailScreen(
        id: state.pathParams?['id'],
      ),
    ),
  ],
)
```

### `R` — Abstract Route Registry

Extend this class to define your app's routes:

```dart
class AppRoutes extends R {
  // Override redirect targets
  @override
  String get redirectAfterLogin => '/dashboard';

  @override
  List<String> get guest => [
    ...super.guest,
    '/welcome',
  ];
}

// Register in DI
Core.i.addSingleton<R>(() => AppRoutes());
```

**Built-in routes:**
- Auth: `/auth/login`, `/auth/register`, `/auth/password/forget`, `/auth/password/reset`, `/auth/accounts`
- Settings: `/settings/themes`, `/settings/notifications`, `/settings/languages`, `/settings/server`
- Content: `/home`, `/onboarding`

---

## Storage (`storage/`)

### `SharedPrefHelper` — Type-Safe Local Persistence

```dart
final prefs = Core.get<SharedPrefHelper>();

// Must call at startup
await prefs.init();

// Generic get/set (supports String, int, double, bool, List<String>, Map, List)
await prefs.set<String>('key', 'value');
final val = prefs.get<String>('key');

// Complex types auto-encode/decode as JSON
await prefs.set<Map<String, dynamic>>('settings', {'dark': true});
final settings = prefs.get<Map<String, dynamic>>('settings');

// Application-specific convenience methods
prefs.getThemeIndex();
prefs.saveThemeIndex(1);
prefs.getLanguageIndex();
prefs.saveLanguageIndex(0);
prefs.getFontSize();
prefs.saveFontSize(18);
prefs.getIntroducer();
prefs.saveIntroducer(model);
prefs.getTenantId();
prefs.saveTenantId('tenant-123');
```

---

## Contracts (`contracts/`)

Abstract interfaces for platform-dependent services. Implementations live in `impl/` packages.

### `NetworkInfo`
```dart
abstract class NetworkInfo {
  Future<bool> get isConnected;
}
// Implemented by: concrete/tools/NetworkInfoImpl
```

### `Notifier`
```dart
abstract class Notifier {
  Future init();
  Future<bool> logout();
  Future<bool> subscribe(int id);
  Future<bool> unsubscribe(int id);
  Future<bool> subscribeTo(String tag);
  Future<bool> unSubscribeFrom(String tag);
}
// Implemented by: impl/impl_notifier_onesignal
```

### `DeviceInfo`
```dart
abstract class DeviceInfo {
  Future<String?> uuid();
  Future<String?> name();
}
// Implemented by: impl/impl_device_info
```

### `Locator`
```dart
abstract class Locator {
  Future<Position> getCurrentPosition();
  Future<Position> pickFromMap(BuildContext context, Position position);
  Future<Position> viewInMap(BuildContext context, Position position);
  Future openAppSettings();
}
// Implemented by: impl/impl_locator
```

---

## Extensions (`extensions/`)

### Context Extensions
```dart
context.sz;          // MediaQuery Size
context.theme;       // ThemeData
context.colorScheme; // ColorScheme
context.textTheme;   // TextTheme
context.isDark;      // bool
context.isRtl;       // bool
context.isMobile;    // width < 850
context.isTablet;    // 850 <= width < 1100
context.isDesktop;   // width >= 1100
```

### String Extensions
```dart
'123'.isNumeric;                           // true
'2024-01-15T10:30:00Z'.formatHumanReadableDate(); // "January 15, 2024 at 10:30 AM"
```

### Number Extensions
```dart
num? x = null;
x.isEmpty;     // true (null or zero)
x.isNotEmpty;  // false
(1500).dinar;  // "1,500" (formatted without currency symbol)
```

### Map Extensions
```dart
{'a': '1', 'b': '2.5'}.toDynamic; // {'a': 1, 'b': 2.5} (auto-parse)
{'key': 'val'}.toQuery;           // "key=val"
{'key': 'val'}.toQueryWithMark;   // "?key=val"
myMap.sorted;                     // Sorted by keys alphabetically
myMap.sort<String, dynamic>();    // Typed sort
```

### Logging
```dart
// Via extension on Object (available everywhere)
logCtrl.debug('Controller message');
logAuth.info('Auth message');
logUI.warning('UI message');
logNet.error('Network message');

// Via mixins (for class-level logging)
class MyService with AuthLoggy { ... }
class MyWidget with UiLoggy { ... }
```

---

## Constants (`constants/`)

### `UserAction` Enum
Actions that can be performed on resources:
```
SHOW, EDIT, SELECT, LOAD, OPTIONS, REACT, RATE, COMMENT,
SHARE, DELETE, REPORT, FOLLOW, ACCEPT, REFUSE, BAN, BOOKMARK, PICK
```

### `FileType` Enum
```
IMAGE, IMAGE_PNG, SVG, AUDIO, VIDEO, PDF, GLTF, GLB, VR, UNKNOWN
```
With extensions for `.extension()` and `.mediaType()`.

### Size Tokens (`Sz`, `Edges`, `Corner`)
```dart
Sz.xs   // 4.0
Sz.sm   // 8.0
Sz.md   // 12.0
Sz.lg   // 16.0
Sz.xl   // 32.0
Sz.xxl  // 64.0

Edges.md  // EdgeInsets.all(12.0)
Corner.lg // BorderRadius.circular(16.0)
```

---

## App Layer (`app/`)

### `Config` — Abstract Configuration
```dart
class MyConfig extends Config {
  @override
  String get baseUrl => 'https://api.myapp.com/v1';

  @override
  int get appID => 42;

  @override
  String get appName => 'My App';

  @override
  List<CustomLang> get supportedLocales => [
    CustomLang('English', Locale('en', 'US')),
    CustomLang('Arabic', Locale('ar', 'IQ')),
  ];

  @override
  List<CustomTheme> get themes => [
    CustomTheme('Light', lightTheme),
    CustomTheme('Dark', darkTheme),
  ];
}
```

### `Registrar` — Dependency Bootstrap

```dart
class AppRegistrar extends Registrar {
  @override
  void register() {
    // Register app-specific services
    Core.i.add<ProductApiService>(() => ProductApiService.instance());
    Core.i.add<ProductCubit>(() => ProductCubit());
  }

  @override
  List<Interceptor> get appInterceptors => [
    AuthInterceptor(Core.get<Config>(), Core.get<AuthLocalManager>(), Core.get<SharedPrefHelper>()),
    // Add custom interceptors here
  ];
}
```

### `I` — Initializer Contract

Services that need lifecycle management implement this:
```dart
class NotificationService extends I {
  @override
  Future init() async { /* Setup */ }

  @override
  void refresh() { /* Re-read settings */ }

  @override
  void activate({required AuthResponse user}) {
    // Subscribe to user-specific topics
  }

  @override
  void deactivate({AuthResponse? user}) {
    // Unsubscribe from topics
  }
}
```

### `ControlledState` — Auto-Injected BLoC State

```dart
class _MyScreenState extends ControlledState<MyScreen, MyCubit> {
  // `store` is automatically injected from DI
  // BLoC is automatically closed on dispose

  @override
  Widget build(BuildContext context) {
    store.loadData(); // Use the cubit
    return ...;
  }
}
```
