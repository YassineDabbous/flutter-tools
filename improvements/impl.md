# Impl Packages — Improvements

---

## 🟡 1. Add Fallback/Mock Implementations for All Contracts

### Problem
If a contract implementation isn't registered (e.g., `Locator` on web), `Core.get<Locator>()` throws. There are no graceful fallbacks or no-op implementations.

### Solution
Create a `Fallback` version of each contract:

```dart
// In core or a new impl_fallback package
class FallbackLocator implements Locator {
  @override
  Future<Position> getCurrentPosition() async => Position.zero;

  @override
  Future<Position> pickFromMap(BuildContext context, Position position) async {
    // Show a dialog: "Location not supported on this platform"
    await showDialog(context: context, builder: (_) =>
        AlertDialog(title: Text('Not available'), content: Text('Map picker is not available on this platform.')));
    return position;
  }

  @override
  Future<Position> viewInMap(BuildContext context, Position position) async {}

  @override
  Future openAppSettings() async {}
}

class FallbackNotifier implements Notifier {
  @override
  Future init() async => logCtrl.info('Notifier: No-op (fallback)');
  @override
  Future<bool> subscribe(int id) async => false;
  @override
  Future<bool> unsubscribe(int id) async => false;
  @override
  Future<bool> subscribeTo(String tag) async => false;
  @override
  Future<bool> unSubscribeFrom(String tag) async => false;
  @override
  Future<bool> logout() async => false;
}

class FallbackDeviceInfo implements DeviceInfo {
  @override
  Future<String?> uuid() async => 'web-${DateTime.now().millisecondsSinceEpoch}';
  @override
  Future<String?> name() async => 'Web Browser';
}
```

**Auto-fallback registration helper:**
```dart
extension SafeInjection on Injector {
  /// Register with a fallback if the primary fails
  void addWithFallback<T>(T Function() primary, T Function() fallback) {
    try {
      addSingleton<T>(primary);
    } catch (e) {
      addSingleton<T>(fallback);
      logCtrl.warning('Using fallback for ${T.toString()}');
    }
  }
}
```

---

## 🟡 2. Platform-Adaptive Contract Resolver

### Problem
Each app must manually choose which impl package to register for each contract. A web app must register `FallbackLocator`, a mobile app registers `LocatorImpl`, etc.

### Solution
Create a platform resolver:

```dart
class PlatformContracts {
  static void registerAll() {
    if (kIsWeb) {
      _registerWeb();
    } else if (Platform.isIOS || Platform.isAndroid) {
      _registerMobile();
    } else {
      _registerDesktop();
    }
  }

  static void _registerMobile() {
    Core.i.addSingleton<Locator>(() => LocatorImpl());
    Core.i.addSingleton<DeviceInfo>(() => DeviceInfoImpl());
    Core.i.addSingleton<Notifier>(() => OneSignalNotifier());
  }

  static void _registerWeb() {
    Core.i.addSingleton<Locator>(() => WebLocator()); // HTML5 Geolocation
    Core.i.addSingleton<DeviceInfo>(() => WebDeviceInfo());
    Core.i.addSingleton<Notifier>(() => FallbackNotifier());
  }

  static void _registerDesktop() {
    Core.i.addSingleton<Locator>(() => FallbackLocator());
    Core.i.addSingleton<DeviceInfo>(() => DesktopDeviceInfo());
    Core.i.addSingleton<Notifier>(() => FallbackNotifier());
  }
}
```

---

## 🟡 3. Navigation Adapter Improvements

### Problem
The current `nav_go_router` and `nav_modular` adapters override `AppNavigator`, but `AppNavigator` has methods that throw `UnimplementedError`. Developers may call an unsupported method and crash at runtime.

### Solution A — Capability API:
```dart
abstract class AppNavigator {
  /// Check if a capability is supported
  bool supports(NavCapability capability);

  /// Safe call with fallback
  void safeCall(NavCapability cap, VoidCallback action, {VoidCallback? fallback}) {
    if (supports(cap)) {
      action();
    } else {
      fallback?.call();
      logCtrl.warning('Navigation capability $cap not supported');
    }
  }
}

enum NavCapability {
  push, replace, popUntil, deepLinking, queryParams, nestedNavigation
}
```

### Solution B — Remove intermediate `AppNavigator` defaults:
Make all methods abstract (no default implementation that throws). This forces each adapter to implement everything, and compile-time errors catch missing methods.

---

## 🟢 4. Add `impl_biometric` — Biometric Authentication

### Idea
A contract and implementation for local biometric authentication (Face ID, fingerprint):

```dart
// Contract in core
abstract class BiometricAuth {
  Future<bool> isAvailable();
  Future<bool> authenticate({required String reason});
  Future<List<BiometricType>> getAvailableTypes();
}

// Implementation using local_auth package
class BiometricAuthImpl implements BiometricAuth {
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  Future<bool> isAvailable() async => await _auth.canCheckBiometrics;

  @override
  Future<bool> authenticate({required String reason}) async {
    return await _auth.authenticate(
      localizedReason: reason,
      options: const AuthenticationOptions(
        stickyAuth: true,
        biometricOnly: false,
      ),
    );
  }

  @override
  Future<List<BiometricType>> getAvailableTypes() async =>
      await _auth.getAvailableBiometrics();
}
```

**Use cases:**
- App lock screen
- Confirming sensitive operations (payments, account deletion)
- Quick re-authentication after timeout

---

## 🟢 5. Add `impl_analytics` — Event Tracking

### Idea
A contract for analytics that can be implemented with Firebase, Mixpanel, or any other provider:

```dart
// Contract in core
abstract class Analytics {
  Future<void> init();
  void logEvent(String name, {Map<String, dynamic>? params});
  void setUserId(String id);
  void setUserProperty(String name, String value);
  void logScreenView(String screenName);
}

// Firebase implementation
class FirebaseAnalyticsImpl implements Analytics {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  @override
  void logEvent(String name, {Map<String, dynamic>? params}) {
    _analytics.logEvent(name: name, parameters: params);
  }

  @override
  void logScreenView(String screenName) {
    _analytics.logScreenView(screenName: screenName);
  }
  // ...
}

// Auto-tracking integration with AppNavigator
class AnalyticsNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    if (route.settings.name != null) {
      Core.get<Analytics>().logScreenView(route.settings.name!);
    }
  }
}
```

---

## 🟢 6. Add `impl_deep_link` — Universal Link Handling

### Idea
Handle incoming deep links and universal links:

```dart
abstract class DeepLinkHandler {
  Stream<Uri> get onLink;
  Future<Uri?> getInitialLink();
  void handleLink(Uri uri);
}

class DeepLinkService implements DeepLinkHandler {
  @override
  void handleLink(Uri uri) {
    final route = Core.get<R>().resolveDeepLink(uri);
    if (route != null) {
      Core.nav.push(route);
    }
  }
}
```

---

## 🟢 7. Standardize Impl Package Structure

### Problem
Impl packages have inconsistent internal structures. Some have complex directory trees, others are single files.

### Solution
Define a standard template:

```
impl_example/
├── lib/
│   ├── impl_example.dart      # Public API barrel file
│   └── src/
│       ├── example_impl.dart  # Implementation class
│       └── adapters/          # Platform adapters if needed
├── test/
│   └── example_impl_test.dart
├── pubspec.yaml
├── README.md
└── CHANGELOG.md
```

With a standard `pubspec.yaml` template:
```yaml
name: impl_example
description: Implementation of ExampleContract for the Caky SDK
version: 1.0.0

environment:
  sdk: ^3.0.0
  flutter: ^3.10.0

dependencies:
  flutter:
    sdk: flutter
  core:
    path: ../../core
```
