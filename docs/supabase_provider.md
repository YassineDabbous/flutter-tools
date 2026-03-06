# supabase_provider

> **Supabase backend implementation via `supabase_flutter`.**

This package implements the `skeleton` contracts for **Supabase** backends. It provides a base API service with built-in CRUD, an auth bridge, a storage helper, and a pagination mixin.

**Depends on:** `skeleton`, `core`, `supabase_flutter`

---

## Table of Contents

- [Architecture](#architecture)
- [SupabaseApiService](#supabaseapiservice)
- [SupabasePaginationBloc](#supabasepaginationbloc)
- [SupabaseAuthBridge](#supabaseauthbridge)
- [SupabaseStorageHelper](#supabasestoragehelper)
- [Integration Example](#integration-example)

---

## Architecture

```
┌────────────────────────────────────────┐
│          Your Feature Code             │
│  ProductCubit → ProductApiService      │
├────────────────────────────────────────┤
│      SupabaseApiService (abstract)     │
│     ┌───────────────────────────┐      │
│     │    Error → AppFailure     │      │
│     │    mapping (built-in)     │      │
│     └───────────────────────────┘      │
├────────────────────────────────────────┤
│          SupabaseClient                │
│   (from supabase_flutter)              │
└────────────────────────────────────────┘
```

---

## SupabaseApiService

Base class with **built-in CRUD implementations** that work directly with Supabase tables:

```dart
abstract class SupabaseApiService<Model, EditRequest, SearchRequest, ID>
    implements BaseApiService<Model, EditRequest, SearchRequest, ID> {

  final SupabaseClient client;
  final String table;            // Supabase table name

  // Built-in implementations:
  Future<ApiResponse<Model>> show({required ID id, ...});   // .select().eq('id', id).single()
  Future<ApiResponse<ID>> create(EditRequest request);      // .insert(...)
  Future<ApiResponse<ID>> update({required ID id, ...});    // .update(...).eq('id', id)
  Future<ApiResponse<ID>> delete({required ID id, ...});    // .delete().eq('id', id)

  // Abstract — you implement these:
  Model modelFromJson(Map<String, dynamic> json);
  Map<String, dynamic> requestToJson(EditRequest request);
}
```

### Error Mapping

Supabase errors are automatically mapped to SDK failure types:

| Supabase Error | Mapped to |
|----------------|-----------|
| PostgrestException `42501` | `PermissionFailure` |
| PostgrestException `23505` | `ValidationFailure` (unique constraint) |
| PostgrestException `PGRST116` | `NotFoundFailure` |
| `AuthException` | `AuthFailure` |
| Other | `ServerFailure` |

### Example Implementation

```dart
class ProductSupabaseService extends SupabaseApiService<Product, ProductRequest, ProductFilter, String> {
  ProductSupabaseService(SupabaseClient client) : super(client, 'products');

  @override
  Product modelFromJson(Map<String, dynamic> json) => Product.fromJson(json);

  @override
  Map<String, dynamic> requestToJson(ProductRequest request) => request.toJson();

  // Custom query example:
  @override
  Future<ApiResponse<List<Product>>> all({required ProductFilter request}) {
    return handle(() async {
      final query = client.from(table).select();
      // Apply filters from request
      if (request.category != null) {
        query.eq('category', request.category!);
      }
      final data = await query;
      return ApiResponse(data: data.map((e) => Product.fromJson(e)).toList());
    });
  }
}
```

---

## SupabasePaginationBloc

Mixin for range-based Supabase pagination:

```dart
mixin SupabasePaginationBloc<ApiType, BaseState, Model, SearchRequest, ID>
    on PaginationBloc<ApiType, BaseState, Model, SearchRequest> {

  @override
  Future<PaginatedResponse<Model>> load() async =>
    (await http().paging(page: page, request: filter)).data!;
}
```

### `SupabasePaginatedResponse<T>`

Generic paginated response for Supabase:

```dart
class SupabasePaginatedResponse<T> implements PaginatedResponse<T> {
  final List<T> data;
  final int total;
  final int perPage;
  final int currentPage;
  int get lastPage => (total / perPage).ceil();
}
```

---

## SupabaseAuthBridge

Bridges Supabase GoTrue authentication with the SDK's `AuthLocalManager`:

```dart
class SupabaseAuthBridge extends AuthLocalManager {
  final SupabaseClient client;

  @override
  bool check() => client.auth.currentSession != null;

  @override
  Future<void> logout() async {
    await client.auth.signOut();
    super.logout();
  }

  void listenToAuthChanges();  // Auto-sync auth state
}
```

### Usage

```dart
// In your Registrar:
final supabase = Supabase.instance.client;
Core.i.addSingleton<AuthLocalManager>(() => SupabaseAuthBridge(supabase));
```

The bridge:
- Uses Supabase's session to determine login status
- Listens to `onAuthStateChange` for real-time auth updates
- Delegates to the parent `AuthLocalManager` for local persistence

---

## SupabaseStorageHelper

Utility for uploading and deleting files in Supabase Storage:

```dart
class SupabaseStorageHelper {
  final SupabaseClient client;

  Future<String> upload(String bucket, File file, {String? path});
  Future<void> delete(String bucket, String path);
}
```

### Example

```dart
final storage = SupabaseStorageHelper(supabase);

// Upload
final url = await storage.upload('avatars', avatarFile);
// Returns: https://your-project.supabase.co/storage/v1/object/public/avatars/...

// Delete
await storage.delete('avatars', 'path/to/file.jpg');
```

---

## Integration Example

```dart
class AppRegistrar extends Registrar {
  @override
  void register() {
    final supabase = Supabase.instance.client;

    // Override default AuthLocalManager with Supabase bridge
    Core.i.addSingleton<AuthLocalManager>(() {
      final bridge = SupabaseAuthBridge(supabase);
      bridge.listenToAuthChanges();
      return bridge;
    });

    // Register API services
    Core.i.addSingleton<ProductApiService>(
      () => ProductSupabaseService(supabase),
    );

    // Register storage helper
    Core.i.addSingleton<SupabaseStorageHelper>(
      () => SupabaseStorageHelper(supabase),
    );
  }
}
```
