# Architecture — Cross-Cutting Improvements

---

## 🔴 1. Add Comprehensive Test Infrastructure

### Problem
There are no test files anywhere in the packages. This means:
- No regression protection when making changes
- No confidence during upgrades (Flutter, Dio, dependencies)
- No documentation of edge cases and expected behaviors
- Blocked from CI/CD adoption

### Solution
Build a test infrastructure with three layers:

#### Layer 1: Unit Tests (per package)
```
core/test/
├── di/
│   ├── injector_test.dart           # Registration, retrieval, lifecycle
│   └── default_injector_test.dart   # Concrete implementation
├── http/
│   ├── base_dio_test.dart           # Dio configuration
│   ├── exception_handler_test.dart  # Error → exception mapping
│   ├── auth_interceptor_test.dart   # Header injection
│   └── cache_test.dart              # Caching behavior
├── auth/
│   ├── auth_local_manager_test.dart # Token CRUD
│   ├── authentication_cubit_test.dart
│   └── auth_checker_cubit_test.dart
├── storage/
│   └── shared_pref_helper_test.dart # Type-safe persistence
└── blocs/
    ├── theme_bloc_test.dart
    └── language_bloc_test.dart
```

#### Layer 2: Integration Tests
```
integration_test/
├── auth_flow_test.dart           # Login → navigate → logout
├── crud_lifecycle_test.dart       # Create → read → update → delete
└── offline_resilience_test.dart   # Network failure → cache → recovery
```

#### Layer 3: Widget Tests
```
concrete/test/
├── ui/
│   ├── modal_test.dart
│   ├── form_handler_test.dart
│   └── filter_handler_test.dart
└── tools/
    ├── linker_test.dart
    └── clipboard_test.dart
```

#### Test Utilities
Create a shared test utilities package:

```dart
// test_helpers/mock_injector.dart
class MockInjector implements Injector {
  final Map<Type, dynamic> _mocks = {};

  void mock<T>(T instance) => _mocks[T] = instance;

  @override
  T get<T>({String? key}) => _mocks[T] as T;
  // ...
}

// test_helpers/fake_shared_prefs.dart
class FakeSharedPrefHelper extends SharedPrefHelper {
  final Map<String, dynamic> _store = {};
  @override
  T? get<T>(String key) => _store[key] as T?;
  @override
  Future<void> set<T>(String key, T value) async => _store[key] = value;
}

// test_helpers/mock_dio.dart
class MockDio {
  static Dio withResponses(Map<String, dynamic> responses) {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final key = '${options.method} ${options.path}';
        if (responses.containsKey(key)) {
          handler.resolve(Response(
            requestOptions: options,
            data: responses[key],
            statusCode: 200,
          ));
        } else {
          handler.reject(DioException(
            requestOptions: options,
            response: Response(requestOptions: options, statusCode: 404),
          ));
        }
      },
    ));
    return dio;
  }
}
```

#### Example Unit Test
```dart
// auth_local_manager_test.dart
void main() {
  late AuthLocalManager manager;
  late FakeSharedPrefHelper prefs;

  setUp(() {
    prefs = FakeSharedPrefHelper();
    Core.overrideInjector(MockInjector()..mock<SharedPrefHelper>(prefs));
    manager = AuthLocalManager();
  });

  group('login/logout flow', () {
    test('setAuth saves both tokens', () async {
      await manager.setAuth(AuthResponse(
        user: AuthUser(id: 1, type: 'user', name: 'Test'),
        token: 'token-123',
        abilities: [],
        permissions: [],
      ));

      expect(manager.check(), isTrue);
      expect(manager.currentUser?.token, equals('token-123'));
      expect(prefs.get<String>('real_token'), equals('token-123'));
    });

    test('logout clears profile but keeps root token', () async {
      await manager.setAuth(/*...*/);
      await manager.logout();

      expect(manager.guest(), isTrue);
      expect(prefs.get<String>('real_token'), isNotNull);
    });

    test('hardLogout clears everything', () async {
      await manager.setAuth(/*...*/);
      await manager.hardLogout();

      expect(manager.guest(), isTrue);
      expect(prefs.get<String>('real_token'), isNull);
    });
  });
}
```

---

## 🟠 2. Introduce a `Result` Type for Error Handling

### Problem
Methods in BLoCs use try/catch everywhere. This:
- Hides which errors a method can produce
- Makes error handling inconsistent
- Can swallow unexpected exceptions

### Solution
Use a `Result<T, E>` union type:

```dart
sealed class Result<T, E> {
  const Result();
}

class Success<T, E> extends Result<T, E> {
  final T data;
  const Success(this.data);
}

class Failure<T, E> extends Result<T, E> {
  final E error;
  const Failure(this.error);
}

// Extensions for convenience
extension ResultX<T, E> on Result<T, E> {
  T? get dataOrNull => switch (this) {
    Success(:final data) => data,
    Failure() => null,
  };

  Result<R, E> map<R>(R Function(T) mapper) => switch (this) {
    Success(:final data) => Success(mapper(data)),
    Failure(:final error) => Failure(error),
  };

  Future<Result<R, E>> flatMap<R>(Future<Result<R, E>> Function(T) mapper) async =>
      switch (this) {
        Success(:final data) => await mapper(data),
        Failure(:final error) => Failure(error),
      };
}
```

**Usage in repository layer:**
```dart
class ProductRepository {
  Future<Result<Product, AppError>> getById(int id) async {
    try {
      final product = await handle(api.show(id: id));
      return Success(product!);
    } on AuthException {
      return Failure(AppError.unauthorized);
    } on NotFoundException {
      return Failure(AppError.notFound);
    } on NoInternetException {
      return Failure(AppError.offline);
    }
  }
}

// In BLoC — cleaner error handling
void show(int id) async {
  emit(ProductLoading());
  final result = await repo.getById(id);
  switch (result) {
    case Success(:final data):
      emit(ProductLoaded(data));
    case Failure(:final error):
      emit(ProductError(error.message));
  }
}
```

---

## 🟠 3. Environment-Based Configuration

### Problem
`Config` is a single abstract class. No built-in way to switch between development, staging, and production environments.

### Solution
```dart
enum Environment { dev, staging, production }

abstract class Config {
  Environment get environment;
  bool get isProduction => environment == Environment.production;
  bool get isDev => environment == Environment.dev;

  // Environment-specific getters
  String get baseUrl;
  LogLevel get logLevel => isProduction ? LogLevel.warning : LogLevel.debug;
  bool get enableCrashReporting => isProduction;
  bool get enablePerformanceMonitoring => isProduction;
  Duration get cacheMaxAge => isProduction
      ? const Duration(hours: 24)
      : const Duration(minutes: 5);
}

class DevConfig extends AppConfig {
  @override
  Environment get environment => Environment.dev;
  @override
  String get baseUrl => 'https://dev-api.myapp.com/v1';
}

class ProdConfig extends AppConfig {
  @override
  Environment get environment => Environment.production;
  @override
  String get baseUrl => 'https://api.myapp.com/v1';
}
```

Entry point selection:
```dart
// main_dev.dart
void main() => bootstrap(DevConfig());

// main_prod.dart
void main() => bootstrap(ProdConfig());

void bootstrap(Config config) {
  Core.i.addSingleton<Config>(() => config);
  // ... rest of init
}
```

Build with `--dart-define` or `--flavor` to select the entry point.

---

## 🟡 4. CLI Scaffolding Tool

### Problem
Creating a new feature requires creating 10+ files with specific types, imports, and boilerplate.

### Solution
Build a Dart CLI tool:

```bash
# Install globally
dart pub global activate caky_cli

# Create a new feature
caky create feature product

# Output:
# ✅ Created lib/features/product/model/product.dart
# ✅ Created lib/features/product/model/product_request.dart
# ✅ Created lib/features/product/model/product_filter.dart
# ✅ Created lib/features/product/data/product_api.dart
# ✅ Created lib/features/product/logic/product_cubit.dart
# ✅ Created lib/features/product/logic/product_state.dart
# ✅ Created lib/features/product/helpers/product_maker.dart
# ✅ Created lib/features/product/helpers/product_controller.dart
# ✅ Created lib/features/product/ui/product_form.dart
# ✅ Created lib/features/product/ui/product_list_screen.dart
# ✅ Created lib/features/product/ui/product_editor_screen.dart
# ✅ Updated lib/registrar.dart (added ProductApiService, ProductCubit)

# Create just a model
caky create model user --fields="id:int,name:String,email:String?"

# Create an impl package
caky create impl biometric --contract=BiometricAuth
```

Use template files with placeholder substitution:
```dart
// templates/cubit.dart.tmpl
class {{Name}}Cubit extends MyBaseBloc<{{Name}}ApiService, {{Name}}State>
    with CrudBloc<{{Name}}ApiService, {{Name}}State, {{Name}}, {{Name}}Request, {{Name}}Filter>,
         PaginationBloc<{{Name}}ApiService, {{Name}}State, {{Name}}, {{Name}}Filter> {
  {{Name}}Cubit() : super(bs: {{Name}}State());
  // ...
}
```

---

## 🟡 5. API Versioning Support

### Problem
`Config.baseUrl` is a single string. No mechanism for hitting different API versions or gracefully handling version deprecation.

### Solution
```dart
abstract class Config {
  String get baseHost => 'api.myapp.com';
  String get apiVersion => 'v1';
  String get baseUrl => 'https://$baseHost/$apiVersion';

  /// Supported API versions
  List<String> get supportedVersions => ['v1'];

  /// Version negotiation header
  Map<String, String> get versionHeaders => {
    'Api-Version': apiVersion,
    'Accept': 'application/vnd.myapp.$apiVersion+json',
  };
}

// Version deprecation interceptor
class ApiVersionInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final deprecation = response.headers.value('X-Api-Deprecated');
    if (deprecation != null) {
      logNet.warning('⚠️ API version deprecated: $deprecation');
      // Notify user or trigger update check
    }
    handler.next(response);
  }
}
```

---

## 🟡 6. Cross-Package Dependency Audit

### Problem
Some packages have dependencies that could be simplified or removed:
- `concrete` imports both `core` and `skeleton`, but also re-exports `core`
- `action` depends on `concrete` just for `dialogConfirmation` and `showSnackBar`

### Solution
1. **Extract dialog/snackbar utilities** from `concrete` into `core` or a shared `ui_core` package so `action` doesn't need a full `concrete` dependency
2. **Audit transitive dependencies** — packages like `whatsapp_unilink`, `url_launcher`, `share_plus` are only needed in `concrete/tools/`. Keep them isolated there
3. **Consider a `core_ui` package** for Flutter-dependent core utilities (extensions on `BuildContext`, `ControlledState`, size tokens) to keep `core` pure Dart where possible

---

## 🟡 7. Add Structured Error Codes

### Problem
Errors use free-form strings. No standardized error codes for the client to programmatically handle specific errors.

### Solution
```dart
enum AppErrorCode {
  // Auth
  tokenExpired(1001, 'Token has expired'),
  insufficientPermissions(1002, 'Insufficient permissions'),

  // Network
  noInternet(2001, 'No internet connection'),
  serverDown(2002, 'Server is unreachable'),
  timeout(2003, 'Request timed out'),

  // Validation
  validationFailed(3001, 'Validation failed'),

  // Business logic
  resourceNotFound(4001, 'Resource not found'),
  resourceConflict(4002, 'Resource conflict'),
  quotaExceeded(4003, 'Quota exceeded'),

  // Unknown
  unknown(9999, 'An unknown error occurred');

  const AppErrorCode(this.code, this.defaultMessage);
  final int code;
  final String defaultMessage;
}

// Usage
class AppError {
  final AppErrorCode code;
  final String? message;
  final Map<String, dynamic>? details;

  AppError(this.code, {this.message, this.details});

  String get displayMessage => message ?? code.defaultMessage;
}
```
