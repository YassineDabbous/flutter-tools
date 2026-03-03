# Authentication Flow Guide

> How the dual-token authentication system works and how to integrate login, logout, account switching, and route guards.

---

## Token Architecture

The auth system uses **two tokens** to support multi-account switching:

| Token | Purpose | Persistence | Cleared On |
|-------|---------|-------------|------------|
| **Root Token** (`realToken`) | The main session token from the initial login | SharedPreferences (`real_token`) | Hard logout only |
| **Profile Token** (`currentUser.token`) | The active profile's bearer token | SharedPreferences (`current_user`) | Soft or hard logout |

```
Login → Sets both root + profile tokens
Switch Account → Changes profile token only (root stays)
Soft Logout → Clears profile token (root stays for re-login)
Hard Logout → Clears everything
```

---

## Login Flow

### 1. Call Your Login API

```dart
// Your login screen widget
class _LoginScreenState extends ControlledState<LoginScreen, LoginCubit> {
  void onLoginPressed() {
    store.login(email: emailCtrl.text, password: passCtrl.text);
  }
}

// Your login cubit
class LoginCubit extends MyBaseBloc<AuthApiService, LoginState> {
  void login({required String email, required String password}) async {
    try {
      emit(bs.loading);
      final response = await handle(http().login(email: email, password: password));
      // response is your AuthResponse from the server
      emit(bs.loaded(data: response));
    } catch (e) {
      emit(mapErrorToState(e));
    }
  }
}
```

### 2. Trigger the Global Login

```dart
// In your login screen's BLoC listener
void listener(BuildContext context, LoginState state) {
  if (state is LoginSuccessState) {
    // This triggers the global auth flow:
    // 1. Saves tokens to SharedPreferences
    // 2. Calls I.activate(user:) for service initialization
    // 3. AppWrapper redirects to home
    Core.get<AuthenticationCubit>().login(state.auth);
  }
}
```

### 3. What Happens Automatically

```
AuthenticationCubit.login(auth)
  ├── AuthLocalManager.setAuth(auth)
  │   ├── Save realToken to SharedPrefs
  │   ├── Save currentUser to SharedPrefs
  │   └── I.refresh()  ← Re-read settings
  ├── Emit AuthenticationAuthenticated
  │
  └── AppWrapper.listener()  ← Catches this state
      ├── Check: is current route a guest route?
      ├── I.activate(user: auth)  ← Start push notifications, etc.
      ├── Core.nav.popUntil(isFirst)  ← Clear navigation stack
      └── Core.nav.navigate(R.redirectAfterLogin)  ← Go to home
```

---

## Logout Flow

### Soft Logout (Profile Only)

Clears the active profile but keeps the root token. The user can re-select a profile or re-login.

```dart
Core.get<AuthenticationCubit>().logout();
```

```
AuthenticationCubit.logout()
  ├── AuthLocalManager.logout()
  │   ├── Clear currentUser from SharedPrefs
  │   └── Keep realToken
  ├── Emit AuthenticationLogout
  │
  └── AppWrapper.listener()
      ├── I.deactivate()  ← Unsubscribe from push, etc.
      └── Core.nav.pushReplacement(R.redirectAfterLogout)
```

### Hard Logout (Complete)

Clears everything. The user must login again from scratch.

```dart
Core.get<AuthenticationCubit>().logoutHard();
```

```
AuthenticationCubit.logoutHard()
  ├── AuthLocalManager.hardLogout()
  │   ├── Clear currentUser from SharedPrefs
  │   └── Clear realToken from SharedPrefs
  ├── Emit AuthenticationLogoutHard
  │
  └── AppWrapper.listener()
      ├── I.deactivate()
      └── Core.nav.pushReplacement(R.redirectAfterHardLogout)
```

### Auto Logout on 401

When any API call returns 401, the error flows through:

```
DioException (401) → ExceptionHandler.ex() → AuthException
  → MyBaseBloc.mapErrorToState()
    → onAuthError()
      → AuthenticationCubit.logoutHard()  ← Automatic!
```

---

## Account Switching

```dart
// After receiving the new profile's auth response from your API
Core.get<AuthenticationCubit>().switchTo(newProfileAuth);
```

This updates the active profile token while keeping the root token intact.

---

## Route Guards

### Hard Guard — Protected Routes

Forces redirection if auth state conflicts with route type:

```dart
Authenticity.hard(child: DashboardScreen())
```

| Scenario | Action |
|----------|--------|
| Authenticated + on guest route (e.g. `/login`) | Redirect to `R.redirectAfterLogin` |
| Not authenticated + on protected route | Redirect to `R.redirectAfterLogout` or `R.redirectAfterHardLogout` |
| Not authenticated + on guest route | Show the route normally |
| Authenticated + on protected route | Show the route normally |

### Soft Guard — Optional Auth

Shows alternative content for guests without forcing navigation:

```dart
Authenticity.soft(
  child: ProfileWidget(),       // Shown when authenticated
  guest: LoginPrompt(),         // Shown when not authenticated
  onChecked: (user) {           // Called with auth result
    if (user != null) loadUserData(user.user.id);
  },
)
```

### Conditional Guard — Role/Permission Check

```dart
Authenticity.soft(
  child: AdminPanel(),
  guest: NoAccessWidget(),
  condition: (auth) => auth.hasAbilityTo('admin'),
)
```

---

## Startup Auth Check

At app launch, `AuthCheckerCubit` determines the initial state:

```dart
// In Authenticity widget (automatically triggers)
AuthCheckerCubit..check()
```

| Result | Meaning | Typical Next Step |
|--------|---------|-------------------|
| `AuthIdentified(auth)` | User is logged in | Show home screen |
| `AuthNotIdentified(hard: true)` | No tokens at all | Show login screen |
| `AuthNotIdentified(hard: false)` | Root token exists, no profile | Show account picker |
| `AuthCheckingFailure` | Error reading storage | Show error |

---

## Permission Checking

```dart
// Extension on AuthResponse
auth.hasAbilityTo('content_creator');  // Check ability string
auth.hasPermissionTo(42);             // Check permission int

// Wildcard support
// abilities: ['*'] → hasAbilityTo() always returns true
// abilities: []    → hasAbilityTo() always returns true (empty = no restrictions)
// permissions: ['*'] → hasPermissionTo() always returns true
```

---

## Configuring Routes for Auth

```dart
class AppRoutes extends R {
  // Where to go after login
  @override
  String get redirectAfterLogin => '/home?r=${DateTime.now().millisecondsSinceEpoch}';

  // Where to go after soft logout
  @override
  String get redirectAfterLogout => login(); // '/auth/login'

  // Where to go after hard logout
  @override
  String get redirectAfterHardLogout => login();

  // Routes accessible without authentication
  @override
  List<String> get guest => [
    login(),           // '/auth/login'
    register(),        // '/auth/register'
    passwordForget(),  // '/auth/password/forget'
    passwordReset(),   // '/auth/password/reset'
  ];
}
```

---

## Global Access Helpers

```dart
// Quick access to AuthLocalManager
final manager = auth();

// Quick access to current user
final currentUser = await user();

// Check auth state anywhere
if (auth().check()) {
  print('User: ${auth().currentUser!.user.name}');
}

// Update stored user info
await auth().updateCurrentUser(name: 'New Name', photo: 'newUrl');
```

---

## Complete Auth Setup Checklist

1. ✅ Create `AppConfig` extending `Config`
2. ✅ Create `AppRoutes` extending `R` with guest routes and redirects
3. ✅ Create `AppInitializer` extending `I` with activate/deactivate
4. ✅ Register `Config`, `R`, `I` in your `Registrar`
5. ✅ Wrap your app with `AppWrapper`
6. ✅ Use `Authenticity.hard()` on protected routes
7. ✅ Use `Authenticity.soft()` for optional auth sections
8. ✅ Call `AuthenticationCubit.login()` after successful API login
9. ✅ Provide logout buttons calling `logout()` or `logoutHard()`
