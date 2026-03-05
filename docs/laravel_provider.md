# `laravel_provider` Package

> Standardized implementation for Laravel backends.

The `laravel_provider` package provides concrete implementations of the `skeleton` base classes specifically tailored for Laravel APIs. It handles Laravel-specific response structures, error mapping, and bulk actions.

---

## Key Components

### `LaravelApiService`

The base class for all API services targeting a Laravel backend. It implements `BaseApiService` and provides a `handle()` method that automatically maps Laravel-specific HTTP errors to unified SDK failures.

```dart
class UserApiService extends LaravelApiService<User, UserRequest, UserFilter, int> {
  // Implementation
}
```

### `LaravelPaginationBloc`

A mixin that simplifies the implementation of `PaginationBloc` for Laravel-based paginated endpoints. It automatically handles the `paging` call and unwraps the response.

```dart
class UserListCubit extends MyBaseBloc<UserApiService, UserListState>
    with PaginationBloc<UserApiService, UserListState, User, UserFilter>,
         LaravelPaginationBloc<UserApiService, UserListState, User, UserFilter, int> {
  
  @override
  UserFilter defaultFilter() => UserFilter();
}
```

### `LaravelResponse<T>`

Wraps the standard Laravel API response envelope.

```json
{
  "code": 200,
  "message": "Success",
  "data": { ... },
  "error": null,
  "validation": null
}
```

### `LaravelActionApiService`

A concrete implementation of `ActionApiService` that uses the Laravel Bulk Action system. It sends requests to the `/_action_` endpoint with the appropriate payload.

---

## HTTP Configuration

### `DioFactory`

Provides a pre-configured `Dio` instance with interceptors optimized for Laravel:
- `AuthInterceptor`: Handles Bearer token and Tenant-Id.
- `LaravelErrorMapper`: Converts 422 Validation errors and 401/403 errors into SDK exceptions.
- Method Spoofing: Automatically converts `PUT`/`PATCH` requests with files to `POST` with `_method` field for Laravel compatibility.

---

## Best Practices

1. **Error Handling**: Always use the `handle()` method in your services to ensure exceptions are correctly mapped to `ValidationException`, `AuthException`, etc.
2. **Bulk Actions**: Use `LaravelActionApiService` when implementing features that require batch operations (delete multiple, change status of multiple, etc.).
3. **Pagination**: Leverage `LaravelPaginationBloc` to reduce boilerplate in your list Cubits.
