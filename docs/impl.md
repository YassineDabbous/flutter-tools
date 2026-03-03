# `impl` — Pluggable Implementation Packages

> The `impl/` directory contains 12 independent sub-packages that provide concrete implementations for platform-specific services, navigation adapters, and specialized UI components.

---

## Overview

| Package | Implements | Description |
|---------|-----------|-------------|
| `impl_locator` | `core/Locator` | GPS positioning and map picker |
| `impl_device_info` | `core/DeviceInfo` | Device UUID and name |
| `impl_notifier_onesignal` | `core/Notifier` | OneSignal push notifications |
| `nav_go_router` | `core/AppNavigator` | GoRouter-based navigation |
| `nav_modular` | `core/AppNavigator` | Flutter Modular-based navigation |
| `media` | — | Base media utilities |
| `media_audio` | — | Audio player/recorder |
| `media_video` | — | Video player |
| `file_picker` | — | File/image picker |
| `advanced_editor` | — | Rich text editor |
| `glassmorphism` | — | Glassmorphism UI effects |
| `template_pack` | — | Templated UI screens |

---

## Contract Implementations

### `impl_locator` — GPS & Maps

Implements the `Locator` contract from `core/contracts/locator.dart`:

```dart
// Register in your Registrar
Core.i.addSingleton<Locator>(() => LocatorImpl());

// Usage
final position = await Core.get<Locator>().getCurrentPosition();
print('Lat: ${position.latitude}, Lng: ${position.longitude}');

// Pick from map
final picked = await Core.get<Locator>().pickFromMap(context, currentPosition);

// View in map
await Core.get<Locator>().viewInMap(context, targetPosition);

// Open device location settings
await Core.get<Locator>().openAppSettings();
```

### `impl_device_info` — Device Identification

Implements the `DeviceInfo` contract:

```dart
Core.i.addSingleton<DeviceInfo>(() => DeviceInfoImpl());

final uuid = await Core.get<DeviceInfo>().uuid(); // Unique device ID
final name = await Core.get<DeviceInfo>().name(); // Device model name
```

### `impl_notifier_onesignal` — Push Notifications

Implements the `Notifier` contract using OneSignal:

```dart
Core.i.addSingleton<Notifier>(() => OneSignalNotifier());

// Initialize (typically in your Initializer.init())
await Core.get<Notifier>().init();

// Subscribe to user-specific notifications
await Core.get<Notifier>().subscribe(userId);

// Subscribe to topic
await Core.get<Notifier>().subscribeTo('news_updates');

// Unsubscribe
await Core.get<Notifier>().unsubscribe(userId);
await Core.get<Notifier>().unSubscribeFrom('news_updates');

// On logout
await Core.get<Notifier>().logout();
```

---

## Navigation Adapters

### `nav_go_router` — GoRouter Navigation

Extends `AppNavigator` with `go_router` support, enabling:
- Declarative routing
- Deep linking
- Path and query parameter support
- Nested navigation with shell routes

```dart
// Register the GoRouter-based navigator
Core.i.addSingleton<AppNavigator>(() => GoRouterNavigator(router: goRouter));

// Now Core.nav uses GoRouter under the hood
Core.nav.push('/products/42');
Core.nav.pushReplacement('/login');
```

### `nav_modular` — Flutter Modular Navigation

Alternative navigation adapter using Flutter Modular for:
- Module-based route organization
- Dependency injection per module
- Guard-based route protection

---

## Media Packages

### `media` — Base Media Utilities

Core media helpers shared by audio and video packages.

### `media_audio` — Audio Player/Recorder

Audio playback and recording capabilities:
```dart
// Typically registered and used through the media package
```

### `media_video` — Video Player

Video playback widget:
```dart
// Provides video player widgets for in-app video content
```

### `file_picker` — File & Image Selection

Unified file/image picker interface:
```dart
// Pick images, documents, and other files
// Returns data compatible with FileField for uploads
```

---

## UI Packages

### `advanced_editor` — Rich Text Editor

Full-featured rich text editing with formatting toolbar.

### `glassmorphism` — Glass Effect Widgets

Frosted glass / glassmorphism UI effect widgets for modern design.

### `template_pack` — Pre-built Screen Templates

Ready-to-use templates for common app screens.

---

## How to Use Impl Packages

### 1. Add to `pubspec.yaml`

```yaml
dependencies:
  impl_locator:
    path: ../impl/impl_locator
  nav_go_router:
    path: ../impl/nav_go_router
  impl_notifier_onesignal:
    path: ../impl/impl_notifier_onesignal
```

### 2. Register in Your `Registrar`

```dart
class AppRegistrar extends Registrar {
  @override
  void register() {
    // Contract implementations
    Core.i.addSingleton<Locator>(() => LocatorImpl());
    Core.i.addSingleton<DeviceInfo>(() => DeviceInfoImpl());
    Core.i.addSingleton<Notifier>(() => OneSignalNotifier());
    Core.i.addSingleton<AppNavigator>(() => GoRouterNavigator(router: appRouter));

    // ... app-specific registrations
  }
}
```

### 3. Use Through Contracts

Always access implementations through their abstract contracts:

```dart
// ✅ Good — depends on contract
Core.get<Locator>().getCurrentPosition();

// ❌ Bad — depends on implementation
Core.get<LocatorImpl>().getCurrentPosition();
```

This allows swapping implementations without changing application code.
