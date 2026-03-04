# Supabase Integration Helpers & Utils

To make Supabase feel "native" to the Caky SDK, we implement several small utility helpers.

## 1. Postgrest Extension for DynamicQueryRequest

The `DynamicQueryRequest` in Caky is designed for Laravel-style queries. We can add an extension to automatically apply these to Supabase.

```dart
extension SupabaseQueryHelper on PostgrestFilterBuilder {
  /// Maps Caky's DynamicQueryRequest to Supabase Postgres filters
  PostgrestFilterBuilder applyCaky(DynamicQueryRequest? request) {
    if (request == null) return this;
    
    var query = this;

    // 1. Filtering (Where)
    if (request.where?.isNotEmpty ?? false) {
      for (var filter in request.where!) {
        // Map common operators: eq, neq, like, gt, lt
        query = _applyFilter(query, filter);
      }
    }

    // 2. Ordering
    if (request.orderBy?.isNotEmpty ?? false) {
      for (var order in request.orderBy!) {
        query = query.order(order.column, ascending: order.direction == 'asc');
      }
    }

    return query;
  }

  PostgrestFilterBuilder _applyFilter(PostgrestFilterBuilder q, dynamic filter) {
    // Logic to map Caky Filter object to .eq(), .gt(), etc.
    return q;
  }
}
```

## 2. SupabaseAuthProvider Client

Instead of creating a local SQLite for session management, we can use Supabase Auth as the primary provider for `AuthLocalManager`.

### Pattern

```dart
class CakySupabaseAuth extends AuthLocalManager {
  final SupabaseClient client;
  CakySupabaseAuth(this.client) : super();

  @override
  bool check() => client.auth.currentUser != null;

  @override
  Future<AuthResponse?> getCurrentUser() async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    return AuthResponse(
      token: client.auth.currentSession?.accessToken ?? '',
      user: User(id: user.id, email: user.email),
    );
  }
}
```

## 3. Offline Synchronization Strategy

While the `OfflineQueueInterceptor` (V1) was for Dio, for Supabase we can use **Supabase Offline Storage** patterns or a custom `Action` queue.

- **Pattern**: Wrap `from().insert()` into a Caky `UndoableAction`. If offline, save the action to a local Hive/Isar box and replay it when `NoInternetException` is resolved.

## 4. RLS (Row Level Security) Awareness

Caky's `ExceptionHandler` should be updated to handle "Forbidden" errors which often happen when RLS denies access.

```dart
// Inside SupabaseExceptionHandler
if (err.code == '42501') return PermissionException(message: 'Row Level Security violation.');
```
