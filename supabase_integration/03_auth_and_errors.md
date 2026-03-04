# Auth & Exception Handling with Supabase

## 1. Auth Management

Supabase has a built-in `GoTrue` auth system. To integrate it with Caky's `AuthLocalManager`, you should wrap the Supabase auth listener.

### Implementation Pattern

Modify `AuthLocalManager` (or a subclass) to listen to Supabase auth changes:

```dart
class SupabaseAuthManager extends AuthLocalManager {
  final SupabaseClient client;

  SupabaseAuthManager(this.client) {
    _listen();
  }

  void _listen() {
    client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        // Map Supabase User to Caky AuthResponse
        final cakyUser = AuthResponse(
          token: session.accessToken,
          user: User(id: session.user.id, name: session.user.email),
        );
        setAuth(cakyUser);
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

Supabase throws `PostgrestException` or `AuthException`. You need a new version of the `ExceptionHandler` mixin.

### SupabaseExceptionHandler

```dart
mixin SupabaseExceptionHandler {
  Exception ex(Object err) {
    if (err is PostgrestException) {
      // Map Supabase error codes to Caky exceptions
      if (err.code == '23505') return ValidationException(bag: {'db': 'Unique constraint violation'});
      if (err.code == 'PGRST116') return NotFoundException();
      return ServerException(message: err.message);
    }
    
    if (err is AuthException) {
      return AuthException();
    }

    return err as Exception;
  }
}
```

## 3. Real-time Synchronization (Bonus)

One of Supabase's strengths is Real-time. Caky's `RealtimeSync` mixin can be easily adapted:

```dart
mixin SupabaseRealtimeSync<T> on PaginationBloc<T> {
  void subscribe(String table) {
    Supabase.instance.client
      .from(table)
      .stream(primaryKey: ['id'])
      .listen((data) {
        // Trigger a refresh or manually update the state list
        refresh(); 
      });
  }
}
```

By adding these small "glue" components, the Caky SDK becomes a powerful Supabase framework.
