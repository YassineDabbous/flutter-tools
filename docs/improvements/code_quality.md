# Code Quality Improvements

Bug fixes, type safety, naming issues, and consistency problems found across the codebase.

---

## 1. `TokenRefreshInterceptor` Can Silently Swallow Retry Errors

**File:** `laravel_provider/lib/interceptors/refresh_interceptor.dart`

**Problem:** When the token refresh succeeds but the retry of the original request fails, the error is silently caught and the original 401 error is forwarded instead of the actual retry error:

```dart
try {
  final newToken = await _refreshToken();
  if (newToken != null) {
    await _authManager.updateToken(newToken);
    final response = await _dio.fetch(options);  // retry
    return handler.resolve(response);
  }
} catch (e) {
  // ← catches BOTH refresh failures AND retry failures
  // no logging, no distinction
} finally {
  _isRefreshing = false;
}

handler.next(err);  // forwards the ORIGINAL 401, not the retry error
```

**Suggestion:** Separate the refresh and retry error handling, and log failures:

```dart
try {
  final newToken = await _refreshToken();
  if (newToken == null) {
    Core.logCrash('Token refresh returned null');
    return handler.next(err);
  }
  
  await _authManager.updateToken(newToken);
  options.headers['Authorization'] = 'Bearer $newToken';
  
  try {
    final response = await _dio.fetch(options);
    return handler.resolve(response);
  } catch (retryError) {
    return handler.next(retryError is DioException ? retryError : err);
  }
} catch (refreshError) {
  Core.logCrash('Token refresh failed: $refreshError');
  // Trigger logout since refresh failed
  Core.get<AuthenticationCubit>().logoutHard();
  return handler.next(err);
} finally {
  _isRefreshing = false;
}
```

**Impact:** 🔴 High — auth bugs are extremely hard to debug when errors are swallowed.

---

## 2. `RetryInterceptor` Silently Drops Non-DioException Errors

**File:** `laravel_provider/lib/interceptors/retry_interceptor.dart`

**Problem:** The catch block re-throws for `DioException` but silently drops any other exception type:

```dart
try {
  final response = await _dio.fetch(err.requestOptions);
  handler.resolve(response);
} catch (e) {
  if (e is! DioException) {
    handler.next(err);  // ← drops the actual error, sends original
  }
  // ← if e IS DioException, nothing happens — handler is never called!
}
```

**Suggestion:**

```dart
try {
  final response = await _dio.fetch(err.requestOptions);
  handler.resolve(response);
} catch (e) {
  handler.next(e is DioException ? e : err);
}
```

**Impact:** 🔴 High — the current code can leave requests hanging with no response.

---

## 3. `OfflineQueueInterceptor` Doesn't Auto-Flush on Reconnect

**File:** `laravel_provider/lib/interceptors/offline_interceptor.dart`

**Problem:** The `flush()` method is never called automatically. There's no connectivity listener that triggers queue replay when the device comes back online. The queued requests will sit there forever unless the developer manually calls `flush()`.

**Suggestion:** Add a connectivity listener:

```dart
class OfflineQueueInterceptor extends Interceptor {
  final ListQueue<RequestOptions> _pendingRequests = ListQueue();
  StreamSubscription? _connectivitySub;
  Dio? _dio;

  void attachDio(Dio dio) {
    _dio = dio;
    // Listen for connectivity changes
    _connectivitySub = Core.get<NetworkInfo>().onStatusChange.listen((connected) {
      if (connected && _dio != null) flush(_dio!);
    });
  }

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    return super.close();
  }
  
  // ... rest of implementation
}
```

**Impact:** 🟡 Medium — offline queue is currently non-functional without manual flush calls.

---

## 4. `ActionRequest.toJson()` Has Side-Effects (Mutates Inputs)

**File:** `skeleton/lib/bases/base_action.dart`

**Problem:** `toJson()` calls `removeWhere` on the `payload` and `filter` maps, which mutates the original data:

```dart
@override
Map<String, dynamic> toJson() {
  var json = <String, dynamic>{};
  if (payload != null) {
    json.addAll(payload!..removeWhere((key, value) => value == null));  // mutates payload!
  }
  if (filter != null) {
    json.addAll(filter!
      ..removeWhere((key, value) => value == null)   // mutates filter!
      ..removeWhere((key, value) => value == ''));    // mutates filter!
  }
  // ...
}
```

**Suggestion:** Work on copies:

```dart
@override
Map<String, dynamic> toJson() {
  final json = <String, dynamic>{};
  if (payload != null) {
    json.addAll(Map.of(payload!)..removeWhere((k, v) => v == null));
  }
  if (filter != null) {
    json.addAll(Map.of(filter!)
      ..removeWhere((k, v) => v == null)
      ..removeWhere((k, v) => v == ''));
  }
  json.addAll({'_action_': action, '_type_': type, '_keys_': keys});
  return json;
}
```

**Impact:** 🔴 High — calling `toJson()` twice produces different results (second call has fewer fields).

---

## 5. `ApiResponse` Stores Error as `dynamic` Instead of Using `Result`

**Problem:** The SDK already has a well-designed `Result<S, E>` sealed class in `core/lib/utils/result.dart`, but `ApiResponse` uses nullable `data` + nullable `error` + nullable `message` fields. This is the "defensive nullable" anti-pattern — callers never know which field to check first.

```dart
// Current ApiResponse:
class ApiResponse<T> {
  final T? data;       // ← nullable
  final String? message; // ← nullable
  final dynamic error;   // ← untyped dynamic
}

// Existing (but unused) Result:
sealed class Result<S, E> {
  T when<T>({required T Function(S) success, required T Function(E) failure});
}
```

**Suggestion:** Migrate `BaseApiService` methods to return `Result<T, AppFailure>` instead:

```dart
// Before:
Future<ApiResponse<Model>> show({required ID id});

// After:
Future<Result<Model, AppFailure>> show({required ID id});
```

This is a large refactor, so it could be done incrementally — starting with new features and gradually migrating existing ones.

**Impact:** 🟡 Medium — the `Result` type is already there, just unused. Would eliminate null-check guessing.

---

## 6. `PaginationBloc` Uses `dynamic` for `forAdmin` Logic Branching

**File:** `skeleton/lib/bases/bloc/base_pagination_cubit.dart`

**Problem:** The `forAdmin` field from `MyBaseBloc` is used inside `PaginationBloc.move()` but it's not part of `PaginationBloc`'s type signature. It's accessed indirectly because `PaginationBloc` mixes into `MyBaseBloc`. This creates an implicit contract.

Additionally, `PaginationBloc` has `offlinePaging` as a mutable boolean that changes behavior at runtime, which makes the BLoC non-deterministic:

```dart
bool offlinePaging = false;  // can flip mid-pagination

Future loadNext() async =>
  offlinePaging ? await moveOffline() : await move();
```

**Suggestion:** Consider two separate mixins instead:

```dart
mixin OnlinePaginationBloc<...> on MyBaseBloc<...> { ... }
mixin OfflinePaginationBloc<...> on MyBaseBloc<...> { ... }
```

**Impact:** 🟢 Low — clarifies intent but requires API restructuring.

---

## 7. Missing `@override` and Inconsistent `showForEdit`

**Problem:** `showForEdit` in `BaseApiService` exists in the interface but most implementations either throw `UnimplementedError` or just delegate to `show()`. In `CrudBloc`, the default `oneForEdit()` simply calls `one()`:

```dart
@protected
Future<Model> oneForEdit({required ID id, Filter? params}) async =>
    await one(id: id, params: params);
```

**Suggestion:** Either:
- Make `showForEdit` optional in the interface (with a default implementation that delegates to `show`)
- Or remove it from `BaseApiService` and add it only to specific service implementations that have separate edit endpoints

**Impact:** 🟢 Low — reduces boilerplate in implementations.

---

## 8. Typos and Naming Irregularities

| Location | Issue | Suggestion |
|----------|-------|------------|
| `base_controller.dart:91` | `initialySelectedIds` | `initiallySelectedIds` |
| `editor_screen_handler.dart:36` | `'unvalid form'` | `'invalid form'` |
| `bulk_action_form.dart:132` | `'unvalid form'` | `'invalid form'` |
| `base_maker.dart:14` | `_attachments` private but `attachments` getter is public | Consider making the design intent clearer |
| `core/main.dart:23` | `appSlogon` | `appSlogan` |
| `controlled_state.dart:5` | `usualy` | `usually` |
| `component_handler.dart:3` | Missing doc comment on class | Add documentation |
