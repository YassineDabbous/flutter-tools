# laravel_provider

> **Laravel backend implementation via Dio + Retrofit.**

This package implements the `skeleton` contracts for **Laravel** backends. It uses Dio as the HTTP client with Retrofit for declarative API definitions, and provides a full interceptor pipeline, error mapping, and response parsing.

**Depends on:** `skeleton`, `core`, `dio`, `retrofit`, `json_annotation`

---

## Table of Contents

- [Architecture](#architecture)
- [DioClientFactory](#dioclientfactory)
- [LaravelApiService](#laravelapiservice)
- [Response Models](#response-models)
- [LaravelPaginationBloc](#laravelpaginationbloc)
- [LaravelActionApiService](#laravelactionapiservice)
- [LaravelErrorMapper](#laravelerrormapper)
- [Interceptors](#interceptors)
- [Advanced Requests](#advanced-requests)
- [Integration Example](#integration-example)

---

## Architecture

```
┌─────────────────────────────────────────────┐
│              Your Feature Code              │
│   ProductCubit → ProductApiService          │
├─────────────────────────────────────────────┤
│         LaravelApiService (abstract)        │
│    ┌──────────────────────────────────┐     │
│    │       LaravelErrorMapper         │     │
│    └──────────────────────────────────┘     │
├─────────────────────────────────────────────┤
│              Dio + Interceptors             │
│  Auth → Refresh → Retry → Offline → Pretty │
├─────────────────────────────────────────────┤
│           DioClientFactory.create()         │
└─────────────────────────────────────────────┘
```

---

## DioClientFactory

Creates a configured `Dio` instance with all interceptors:

```dart
final dio = DioClientFactory.create(
  baseUrl: config.baseUrl,
  config: config,
  authManager: Core.get<AuthLocalManager>(),
  prefHelper: Core.get<SharedPrefHelper>(),
  debug: kDebugMode,  // Enables PrettyLogInterceptor
);
```

**Interceptor pipeline (in order):**

1. `AuthInterceptor` — Attaches Bearer token, Tenant-Id, Accept-Language
2. `TokenRefreshInterceptor` — Refreshes expired tokens
3. `RetryInterceptor` — Retries failed requests
4. `OfflineQueueInterceptor` — Queues requests when offline
5. `PrettyLogInterceptor` — Beautiful request/response logging (debug only)

---

## LaravelApiService

Base class for all Laravel API services. Extends `BaseApiService` with error handling:

```dart
abstract class LaravelApiService<Model, EditRequest, SearchRequest, ID>
    implements BaseApiService<Model, EditRequest, SearchRequest, ID> {

  /// Wraps API calls with error mapping
  Future<T> handle<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (e) {
      throw LaravelErrorMapper.map(e);
    }
  }
}
```

### Example Implementation

```dart
class ProductApiService extends LaravelApiService<Product, ProductRequest, ProductFilter, int> {
  final ProductRetrofitClient _client;

  ProductApiService(Dio dio) : _client = ProductRetrofitClient(dio);

  @override
  Future<ApiResponse<Product>> show({required int id, ProductFilter? params}) =>
    handle(() => _client.show(id));

  @override
  Future<ApiResponse<int>> create(ProductRequest request) =>
    handle(() => _client.create(request.toJson()));

  @override
  Future<ApiResponse<int>> update({required int id, required ProductRequest request}) =>
    handle(() => _client.update(id, request.toJson()));

  @override
  Future<ApiResponse<int>> delete({required int id, ProductFilter? params}) =>
    handle(() => _client.delete(id));

  @override
  Future<ApiResponse<PaginatedResponse<Product>>> paging({
    required int page, required ProductFilter request,
  }) => handle(() => _client.index(page, request.toJson()));

  @override
  Future<ApiResponse<List<Product>>> all({required ProductFilter request}) =>
    handle(() => _client.all(request.toJson()));
}
```

---

## Response Models

### `BasicResponse<T>`

Wraps Laravel's standard JSON response:

```dart
// Laravel API returns:
// { "code": 200, "message": "success", "data": { ... }, "validation": null }

class BasicResponse<T> implements ApiResponse<T> {
  final int? code;
  final String? message;
  final String? error;
  final Map<String, dynamic>? validation;
  final T? data;
}
```

### `LaravelPaginationResponse<T>`

Maps Laravel's paginated response:

```dart
// Laravel API returns:
// { "data": [...], "total": 50, "per_page": 15, "current_page": 1 }

class LaravelPaginationResponse<T> implements PaginatedResponse<T> {
  final List<T> data;
  final int total;
  final int perPage;
  final int currentPage;
}
```

Both use `json_serializable` with `genericArgumentFactories` for type-safe deserialization.

---

## LaravelPaginationBloc

A mixin that auto-implements `PaginationBloc.load()` for Laravel:

```dart
mixin LaravelPaginationBloc<ApiType, BaseState, Model, SearchRequest, ID>
    on PaginationBloc<ApiType, BaseState, Model, SearchRequest> {

  @override
  Future<PaginatedResponse<Model>> load() async =>
    (await http().paging(page: page, request: filter)).data!;
}
```

### Usage

```dart
class ProductListCubit extends MyBaseBloc<ProductApiService, ProductListState>
    with PaginationBloc<ProductApiService, ProductListState, Product, ProductFilter>,
         LaravelPaginationBloc<ProductApiService, ProductListState, Product, ProductFilter, int> {
  // load() is already implemented!
}
```

---

## LaravelActionApiService

Implements `ActionApiService` for Laravel's bulk action endpoint:

```dart
class LaravelActionApiService implements ActionApiService {
  LaravelActionApiService(Dio dio, {String? baseUrl});

  @override
  Future<ApiResponse<dynamic>> handleAction(ActionRequest request) async {
    // POSTs to /_action_ with the action payload
    // Uses superRequestTransform for file upload support
  }
}
```

Register it in your `Registrar`:

```dart
Core.i.addSingleton<ActionApiService>(() => LaravelActionApiService(dio));
```

---

## LaravelErrorMapper

Maps Dio exceptions to SDK `AppFailure` types:

| HTTP Status | DioExceptionType | Mapped to |
|-------------|------------------|-----------|
| — | `connectionTimeout`, `receiveTimeout`, `sendTimeout`, `connectionError` | `NetworkFailure` |
| 401 | — | `AuthFailure` |
| 403 | — | `PermissionFailure` |
| 404 | — | `NotFoundFailure` |
| 422 | — | `ValidationFailure` (with field errors) |
| 500+ | — | `ServerFailure` |
| Other | Non-Dio error | `ServerFailure` |

---

## Interceptors

### `AuthInterceptor`

Automatically attaches to every request:
- `Authorization: Bearer <token>`
- `Tenant-Id: <appID>`
- `Accept-Language: <locale>`
- `Accept: application/json`

### `TokenRefreshInterceptor`

Detects 401 responses and attempts to refresh the auth token before retrying the original request.

### `RetryInterceptor`

Automatically retries failed requests (network errors, timeouts) with configurable retry logic.

### `OfflineQueueInterceptor`

Queues requests when the device is offline and replays them when connectivity is restored.

### `PrettyLogInterceptor`

Development-only colored request/response logging using `pretty_dio_logger`.

---

## Advanced Requests

The `superRequestTransform` function handles complex requests with file uploads by automatically converting fields that contain file references into multipart form data, while using method spoofing (`_method`) for Laravel compatibility with PUT/PATCH requests.

---

## Integration Example

```dart
// 1. In your Registrar
class AppRegistrar extends Registrar {
  @override
  void register() {
    final dio = DioClientFactory.create(
      baseUrl: Core.get<Config>().baseUrl,
      config: Core.get<Config>(),
      authManager: Core.get<AuthLocalManager>(),
      prefHelper: Core.get<SharedPrefHelper>(),
    );

    Core.i.addSingleton<ProductApiService>(() => ProductApiService(dio));
    Core.i.addSingleton<ActionApiService>(() => LaravelActionApiService(dio));
  }
}
```
