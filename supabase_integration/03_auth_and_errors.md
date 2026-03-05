# Auth & Exception Handling with Supabase

## 1. Auth Management

Supabase has a built-in `GoTrue` auth system. To integrate it with the SDK's `AuthLocalManager`, you should wrap the Supabase auth listener.

### Implementation Pattern

Use `SupabaseAuthBridge` to listen to Supabase auth changes and sync them with the local manager:

```dart
class SupabaseAuthBridge extends AuthLocalManager {
  final SupabaseClient client;

  SupabaseAuthBridge(this.client) {
    _listen();
  }

  void _listen() {
    client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        // Map Supabase User to SDK AuthResponse
        final sdkAuth = AuthResponse<String>(
          token: session.accessToken,
          user: AuthUser<String>(
            id: session.user.id, 
            name: session.user.email ?? 'Unknown',
            type: 'user',
            photo: session.user.userMetadata?['avatar_url'],
          ),
          abilities: ['*'],
          permissions: [],
        );
        setAuth(sdkAuth);
      } else {
        logout();
      }
    });
  }

  @override
  Future<void> logout() async {
    await client.auth.signOut();
    super.logout();
  }
}
```

## 2. Exception Mapping

Supabase throws `PostgrestException` or `AuthException`. These are mapped internally by `SupabaseApiService` to `AppFailure` types.

### Generic Failure Mapping

In your Supabase implementation:

```dart
if (err is PostgrestException) {
  if (err.code == '23505') throw ValidationFailure(errors: {'db': 'Unique constraint violation'});
  if (err.code == 'PGRST116') throw const NotFoundFailure();
  throw ServerFailure(err.message);
}
```

## 3. Real-time Synchronization

One of Supabase's strengths is Real-time. This can be integrated by extending the `PaginationBloc`:

```dart
mixin SupabaseRealtimeSync<T, F> on PaginationBloc<T, F> {
  void subscribe(String table) {
    Supabase.instance.client
      .from(table)
      .stream(primaryKey: ['id'])
      .listen((data) {
        // Refresh the current page
        load(); 
      });
  }
}
```

By adding these small "glue" components, the SDK becomes a powerful Supabase framework.
