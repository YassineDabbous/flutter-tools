# impl

> **Optional add-on packages for specific platform features.**

The `impl/` directory contains standalone packages that implement `core` contracts or provide additional functionality. Each is independently importable — only add what your project needs.

---

## Package Index

| Package | Description | Dependencies |
|---------|-------------|-------------|
| `nav_go_router` | Navigation via `go_router` | `core` |
| `nav_modular` | Navigation via `flutter_modular` | `core` |
| `impl_device_info` | Device info via `device_info_plus` | `core` |
| `impl_locator` | GPS location via `geolocator` | `core` |
| `impl_notifier_onesignal` | Push notifications via OneSignal | `core` |
| `media` | Image/file picking and cropping | `core`, `skeleton` |
| `media_audio` | Audio recording and playback | `core`, `skeleton` |
| `media_video` | Video recording and playback | `core`, `skeleton` |
| `file_picker` | File picker implementation | `core` |
| `advanced_editor` | Rich text / advanced editor | `core` |
| `template_pack` | App templates and scaffolding | `core` |
| `glassmorphism` | Glassmorphism UI effects | — |

---

## nav_go_router

Implements `AppNavigator` using `go_router`:

```yaml
dependencies:
  nav_go_router:
    path: ../packages/impl/nav_go_router
```

```dart
// In your Registrar:
Core.i.addSingleton<AppNavigator>(() => GoRouterNavigator(router));
```

---

## nav_modular

Implements `AppNavigator` using `flutter_modular`:

```yaml
dependencies:
  nav_modular:
    path: ../packages/impl/nav_modular
```

---

## impl_device_info

Implements `DeviceInfo` contract using `device_info_plus`:

```dart
Core.i.addSingleton<DeviceInfo>(() => DeviceInfoImpl());

// Usage:
final info = Core.get<DeviceInfo>();
final model = await info.getModel();
```

---

## impl_locator

Implements `Locator` contract using `geolocator`:

```dart
Core.i.addSingleton<Locator>(() => LocatorImpl());

// Usage:
final locator = Core.get<Locator>();
final position = await locator.getCurrentPosition();
```

---

## impl_notifier_onesignal

Implements `Notifier` contract using OneSignal:

```dart
Core.i.addSingleton<Notifier>(() => OneSignalNotifier(appId: config.oneSignalAppID));

// Usage:
final notifier = Core.get<Notifier>();
notifier.init();
notifier.setExternalUserId(userId);
```

---

## media

Provides image/file picking, cropping, and compression:

```dart
// Pick and crop an image
final result = await MediaPicker.pickImage(context, crop: true);
```

---

## media_audio

Audio recording and playback widgets:

```dart
// Record audio
AudioRecorder(onRecorded: (file) => handleAudio(file))

// Play audio
AudioPlayer(url: audioUrl)
```

---

## media_video

Video recording and playback widgets.

---

## file_picker

Implements the `FileField` contract for selecting files from the device:

```dart
Core.i.addSingleton<FileField>(() => FilePickerImpl());
```

---

## advanced_editor

Rich text editor widget for formatted content editing.

---

## template_pack

Project templates and boilerplate generators.

---

## glassmorphism

Ready-made glassmorphism-styled containers and effects:

```dart
GlassmorphicContainer(
  child: Text('Frosted glass effect'),
)
```

---

## Adding to Your Project

Only add the packages you need:

```yaml
# pubspec.yaml
dependencies:
  nav_go_router:
    path: ../packages/impl/nav_go_router
  impl_device_info:
    path: ../packages/impl/impl_device_info
  media:
    path: ../packages/impl/media
```

Register implementation in your `Registrar`:

```dart
class AppRegistrar extends Registrar {
  @override
  void register() {
    // Navigation
    Core.i.addSingleton<AppNavigator>(() => GoRouterNavigator(router));
    
    // Device info
    Core.i.addSingleton<DeviceInfo>(() => DeviceInfoImpl());
    
    // Only register what you use!
  }
}
```
