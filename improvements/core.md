# Core Package — Improvements

---

## 🔴 1. Replace `dynamic` Casting in `BaseModel`

### Problem
`BaseModel.getId()` and `getLabel()` use `(this as dynamic).id` which bypasses type safety, crashes at runtime with no helpful error, and prevents IDE auto-completion.

```dart
// Current — dangerous
int getId() => (this as dynamic).id;
String getLabel() => (this as dynamic).title;
```

### Solution
Replace with explicit interface contracts:

```dart
abstract class Identifiable {
  int get id;
}

abstract class Labelable {
  String get label;
}

abstract class BaseModel extends Jsonable implements Identifiable, Labelable {
  // No dynamic casting needed
}

// Models implement it naturally:
class Product extends BaseModel {
  @override
  final int id;

  @override
  String get label => title; // maps title → label

  final String title;
  // ...
}
```

**Impact:** Compile-time safety, better IDE support, no runtime crashes.

---

## 🔴 2. Add Token Refresh / Rotation

### Problem
Currently, when a 401 is received, `mapErrorToState()` triggers a hard logout. This is aggressive — the token may simply be expired and refreshable.

### Solution
Add a `TokenRefreshInterceptor` that intercepts 401 responses, attempts a token refresh, and retries the original request:

```dart
class TokenRefreshInterceptor extends QueuedInterceptor {
  final AuthLocalManager _authManager;
  final Dio _dio;
  bool _isRefreshing = false;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    if (_isRefreshing) {
      // Queue the request until refresh completes
      return handler.next(err);
    }

    _isRefreshing = true;
    try {
      final newToken = await _refreshToken();
      if (newToken != null) {
        await _authManager.updateToken(newToken);
        // Retry the original request with new token
        final response = await _retryRequest(err.requestOptions, newToken);
        return handler.resolve(response);
      }
    } catch (e) {
      // Refresh failed — now do the hard logout
      Core.get<AuthenticationCubit>().logoutHard();
    } finally {
      _isRefreshing = false;
    }
    handler.next(err);
  }

  Future<String?> _refreshToken() async {
    final response = await _dio.post('/auth/refresh', options: Options(
      headers: {'Authorization': 'Bearer ${_authManager.currentUser?.token}'},
    ));
    return response.data?['token'];
  }
}
```

**Key design decisions:**
- Use `QueuedInterceptor` to serialize concurrent 401 refreshes
- Only hard-logout if refresh itself fails
- Retry the original request transparently
- Support configurable refresh endpoint

---

## 🔴 3. Encrypt Tokens at Rest

### Problem
Auth tokens are stored in plain text in SharedPreferences. On rooted/jailbroken devices, these are trivially readable.

### Solution
Use `flutter_secure_storage` for sensitive data:

```dart
class SecureAuthStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveToken(String key, String token) async {
    await _storage.write(key: key, value: token);
  }

  Future<String?> readToken(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
```

**Migration path:** Keep `SharedPrefHelper` for non-sensitive data (theme, language, onboarding). Move tokens and user data to `SecureAuthStorage`.

---

## 🟠 4. Make `Core` Testable

### Problem
`Core` is a static class with global mutable state. This makes unit testing difficult because:
- Tests share state
- Can't inject mocks without modifying global state
- No isolation between test cases

### Solution A — Scoped DI with InheritedWidget
```dart
class CoreProvider extends InheritedWidget {
  final Injector injector;

  static Injector of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CoreProvider>()!.injector;

  // ...
}

// In tests
testWidgets('...', (tester) async {
  final testInjector = TestInjector();
  testInjector.addInstance<AuthLocalManager>(MockAuthManager());

  await tester.pumpWidget(
    CoreProvider(injector: testInjector, child: MyWidget()),
  );
});
```

### Solution B — Keep Static but Add Reset (Simpler)
```dart
class Core {
  static Injector _injector = DefaultInjector();

  @visibleForTesting
  static void overrideInjector(Injector injector) {
    _injector = injector;
  }

  @visibleForTesting
  static void reset() {
    _injector = DefaultInjector();
  }
}
```

**Recommendation:** Solution B is pragmatic and least disruptive; Solution A is architecturally ideal.

---

## 🟠 5. Add Retry Interceptor with Exponential Backoff

### Problem
Network failures (timeout, connection reset) immediately surface as errors. No automatic retry.

### Solution
```dart
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration initialDelay;
  final Set<int> retryableStatusCodes;

  RetryInterceptor({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.retryableStatusCodes = const {408, 429, 500, 502, 503, 504},
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final attempt = (err.requestOptions.extra['retry_attempt'] ?? 0) as int;

    if (attempt >= maxRetries || !_shouldRetry(err)) {
      return handler.next(err);
    }

    final delay = initialDelay * pow(2, attempt);
    await Future.delayed(delay);

    err.requestOptions.extra['retry_attempt'] = attempt + 1;

    try {
      final response = await Dio().fetch(err.requestOptions);
      handler.resolve(response);
    } catch (e) {
      handler.next(err);
    }
  }

  bool _shouldRetry(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) return true;
    if (err.response != null &&
        retryableStatusCodes.contains(err.response!.statusCode)) return true;
    return false;
  }
}
```

**Configurable per-request:**
```dart
dio.get('/critical-data', options: Options(extra: {'max_retries': 5}));
```

---

## 🟠 6. Type-Safe SharedPrefHelper

### Problem
The current `get<T>()` and `set<T>()` methods rely on runtime type checking with `switch` on `T`. Adding a new type requires modifying the method body, and unsupported types silently fail.

### Solution
Use sealed type adapters:

```dart
abstract class PrefAdapter<T> {
  Future<void> write(SharedPreferences prefs, String key, T value);
  T? read(SharedPreferences prefs, String key);
}

class StringAdapter extends PrefAdapter<String> {
  @override
  Future<void> write(SharedPreferences prefs, String key, String value) =>
      prefs.setString(key, value);

  @override
  String? read(SharedPreferences prefs, String key) => prefs.getString(key);
}

// Registry
class TypedPrefs {
  static final Map<Type, PrefAdapter> _adapters = {
    String: StringAdapter(),
    int: IntAdapter(),
    double: DoubleAdapter(),
    bool: BoolAdapter(),
    // Custom types
    Map: JsonMapAdapter(),
    List: JsonListAdapter(),
  };

  T? get<T>(String key) => (_adapters[T] as PrefAdapter<T>?)?.read(_prefs, key);
  Future<void> set<T>(String key, T value) =>
      (_adapters[T] as PrefAdapter<T>?)?.write(_prefs, key, value) ?? Future.value();
}
```

---

## 🟡 7. Connectivity-Aware Request Queuing

### Problem
When offline, API requests fail immediately. Users lose data they were trying to submit.

### Solution
```dart
class OfflineQueueInterceptor extends Interceptor {
  final NetworkInfo networkInfo;
  final Queue<RequestOptions> _pendingRequests = Queue();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (await networkInfo.isConnected) {
      handler.next(options);
    } else if (_isMutating(options.method)) {
      // Queue POST/PUT/DELETE for later
      _pendingRequests.add(options);
      handler.reject(DioException(
        requestOptions: options,
        error: OfflineQueuedException(queueSize: _pendingRequests.length),
      ));
    } else {
      handler.next(options); // Let GET fail normally (may hit cache)
    }
  }

  /// Flush queued requests when back online
  Future<void> flush(Dio dio) async {
    while (_pendingRequests.isNotEmpty) {
      final req = _pendingRequests.removeFirst();
      try {
        await dio.fetch(req);
      } catch (e) {
        _pendingRequests.addFirst(req); // Re-queue on failure
        break;
      }
    }
  }
}
```

---

## 🟡 8. Replace `print()` with Structured Logging

### Problem
Several files use `print()` directly (e.g., `RestartWidget`, `AuthLocalManager` debug logs). These can't be filtered, are noisy in production, and bypass the existing `loggy` system.

### Solution
1. Replace all `print()` calls with the existing logging extensions (`logCtrl`, `logAuth`, `logNet`, `logUI`)
2. Add a production-safe log level configuration:
```dart
// In Config
LogLevel get logLevel => kDebugMode ? LogLevel.debug : LogLevel.warning;
```
3. Conditionally strip debug logs in release builds using `dart:developer`'s `log()` instead of `loggy` for zero-overhead production logging.

---

## 🟡 9. Add `AuthLocalManager.updateToken()` Method

### Problem
Currently there is no way to update just the token without recreating the entire `AuthResponse`. This is needed for token refresh flows.

### Solution
```dart
Future<void> updateToken(String newToken) async {
  final current = await user();
  if (current != null) {
    current.token = newToken;
    await _prefs.set<String>(_key, jsonEncode(current.toJson()));
  }
}
```

---

## 🟡 10. Improve `Config` with Validation

### Problem
`Config` is an abstract class with many getters. If a subclass forgets to override a critical getter, it may return null or throw at runtime.

### Solution
Add a `validate()` method called during `Registrar.init()`:

```dart
abstract class Config {
  void validate() {
    assert(baseUrl.isNotEmpty, 'Config.baseUrl must not be empty');
    assert(appID > 0, 'Config.appID must be positive');
    assert(supportedLocales.isNotEmpty, 'At least one locale required');
    assert(themes.isNotEmpty, 'At least one theme required');
  }
}

// In Registrar.init()
Core.get<Config>().validate();
```

---

## 🟡 11. Add `onTokenAboutToExpire` Callback

### Problem
JWTs have expiration times. Currently, there's no proactive mechanism to refresh before expiry.

### Solution
```dart
class TokenExpiryWatcher {
  Timer? _timer;

  void watch(String token, VoidCallback onExpiringSoon) {
    final payload = _decodeJwt(token);
    final exp = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
    final refreshAt = exp.subtract(const Duration(minutes: 5));
    final delay = refreshAt.difference(DateTime.now());

    if (delay.isNegative) {
      onExpiringSoon();
    } else {
      _timer = Timer(delay, onExpiringSoon);
    }
  }

  void cancel() => _timer?.cancel();
}
```

---

## 🟡 12. Improve Cache with ETags

### Problem
Current caching uses time-based staleness only. No support for conditional requests (ETags, Last-Modified).

### Solution
Add a `ConditionalRequestInterceptor`:

```dart
class ConditionalRequestInterceptor extends Interceptor {
  final Map<String, String> _etags = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final etag = _etags[options.uri.toString()];
    if (etag != null) {
      options.headers['If-None-Match'] = etag;
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final etag = response.headers.value('ETag');
    if (etag != null) {
      _etags[response.requestOptions.uri.toString()] = etag;
    }
    handler.next(response);
  }
}
```

This reduces bandwidth and server load for frequently-accessed data.
