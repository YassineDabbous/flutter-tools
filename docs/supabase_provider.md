# `supabase_provider` Package

> Standardized implementation for Supabase backends.

The `supabase_provider` package provides concrete implementations of the `skeleton` base classes specifically tailored for Supabase using `supabase_flutter`.

---

## Key Components

### `SupabaseApiService`

The base class for all API services targeting a Supabase backend. It uses `SupabaseClient` directly and maps Postgrest/Auth exceptions to unified SDK Failures (e.g., `PermissionFailure`, `NotFoundFailure`).

```dart
class ProductApiService extends SupabaseApiService<Product, ProductRequest, ProductFilter, String> {
  ProductApiService(super.client, super.table);

  @override
  Product modelFromJson(Map<String, dynamic> json) => Product.fromJson(json);

  @override
  Map<String, dynamic> requestToJson(ProductRequest request) => request.toJson();
}
```

### `SupabasePaginationBloc`

A mixin for range-based pagination in Supabase. It bridges the SDK's 1-indexed pagination with Supabase's 0-indexed range selection.

```dart
class ProductListCubit extends MyBaseBloc<ProductApiService, ProductListState>
    with PaginationBloc<ProductApiService, ProductListState, Product, ProductFilter>,
         SupabasePaginationBloc<ProductApiService, ProductListState, Product, ProductFilter, String> {
}
```

### `SupabaseAuthBridge`

Bridges Supabase's `GoTrue` authentication system with the SDK's `AuthLocalManager`. It allows the SDK to remain reactive to Supabase auth state changes while maintaining its own local session state.

```dart
// Register the bridge in your Registrar
final client = Supabase.instance.client;
Core.i.addSingleton<AuthLocalManager>(() => SupabaseAuthBridge(client));
```

---

## Storage Integration

### `StorageHelper`

Provides utility methods for interacting with Supabase Storage buckets, specifically focused on file uploads/downloads compatible with the SDK's `FileField` model.

---

## Best Practices

1. **ID Types**: Supabase typically uses UUIDs for primary keys. Ensure your services specify `String` as the ID type in `SupabaseApiService`.
2. **Real-time**: While `SupabaseApiService` handles standard CRUD, you can still access `client` directly for real-time subscriptions if needed.
3. **Auth Integration**: Use `SupabaseAuthBridge` to ensure `Core` utilities like `Authenticity` guards work correctly with Supabase sessions.
