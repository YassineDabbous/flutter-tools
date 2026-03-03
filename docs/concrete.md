# `concrete` Package

> Reusable UI widgets and utility tools that provide concrete implementations on top of `core` and `skeleton`. This is the visual and tooling layer of the SDK.

---

## Dependencies

```yaml
dependencies:
  core: (path)
  skeleton: (path)
  flutter_screenutil: ^5.9.3
  responsive_framework: ^1.5.1
  visibility_detector: ^0.4.0+2
  scrollable_positioned_list: ^0.3.8
  shimmer: ^3.0.0
  flutter_staggered_grid_view: ^0.4.1
  cached_network_image: ^3.4.1
  flutter_svg: ^2.0.10+1
  internet_connection_checker: ^3.0.1
  flutter_parsed_text: ^2.2.1
  url_launcher: ^6.3.0
  whatsapp_unilink: ^2.1.0
  share_plus: ^11.0.0
  url_strategy: ^0.3.0
```

---

## Module Overview

| Module | Description |
|--------|-------------|
| `ui/inputs/` | Form input widgets (text, dropdown, date picker, tags, rating, JSON editor, translation fields) |
| `ui/modals/` | Dialog helpers (confirmation, info, custom view) |
| `ui/display/` | Display widgets (messages, errors, interactive text with clickable links/emails) |
| `ui/media/` | Image viewer, cached image widget, SVG support |
| `ui/scroll/` | Data grid views, load-more widgets, relation managers, drag-to-scroll |
| `ui/geo/` | Coordinates display and geo-locator button |
| `ui/sidebar/` | Sidebar navigation widget with items |
| `ui/snackbar.dart` | SnackBar helper |
| `tools/` | Utility classes: Linker, Clipboard, Sharer, NetworkChecker |
| `restarter.dart` | App restart widget |

---

## Utility Tools (`tools/`)

### `Linker` — URL/Phone/WhatsApp Launcher

```dart
// Open any URL
Linker.open('https://example.com');

// Open phone dialer
Linker.openPhone('+1234567890');

// Open WhatsApp chat
Linker.openWhatsapp('+1234567890');
```

### `MyClipboard` — Clipboard Helper

```dart
MyClipboard.copy('Text to copy');
```

### `Sharer` — Social Sharing

```dart
// Share text
Sharer.share('Check this out!', subject: 'Cool stuff');

// Share app link (auto-detects iOS/Android store URL from Config)
Sharer.shareApp('Download our app:');
```

### `NetworkInfoImpl` — Network Connectivity

Implements the `NetworkInfo` contract from `core`:

```dart
// Real implementation
final networkInfo = NetworkInfoImpl(InternetConnectionChecker());
await networkInfo.isConnected; // true/false

// Fake implementation (for testing or web)
final fakeNetwork = NetworkInfoFake();
await fakeNetwork.isConnected; // always true
```

---

## UI Widgets

### Input Widgets (`ui/inputs/`)

| Widget | Description |
|--------|-------------|
| `TextInput` | Standard text form field with validation support |
| `DropdownSearch` | Searchable dropdown selector |
| `DropdownMulti` | Multi-select dropdown |
| `DateTimePicker` | Date and time selection |
| `TagsInput` | Tag/chip input field |
| `RatingBar` | Star rating input |
| `ChoiceButton` | Choice/toggle button |
| `JsonEditor` | Raw JSON editing field |
| `JsonTableEditor` | JSON displayed as editable table |
| `TranslationFields` | Multi-language text input fields |
| `TextEditorScreen` | Full-screen text editor |

### Display Widgets (`ui/display/`)

| Widget | Description |
|--------|-------------|
| `Message` | Status message display (info, error, success) |
| `ValidationMessage` | Renders validation error bag from server |
| `ErrorInteractiveWidget` | Error display with retry action |
| `InteractiveText` | Parsed text with clickable emails, URLs, hashtags, phone numbers |

### Modal Dialogs (`ui/modals/`)

```dart
// Confirmation dialog
await dialogConfirmation(
  context: context,
  title: 'Delete item?',
  onConfirm: () => deleteItem(),
);

// Information dialog
await dialogInfoSuccess(context: context);

// Custom view dialog
dialogView(
  context: context,
  view: MyCustomWidget(),
  maxWidth: 400,
  maxHeight: 300,
);
```

### Media Widgets (`ui/media/`)

| Widget | Description |
|--------|-------------|
| `ImageWidget` | Cached network image with placeholder and error handling |
| `ImageViewerScreen` | Full-screen zoomable image viewer |
| `Svg` | SVG rendering helper |

### Scroll Widgets (`ui/scroll/`)

| Widget | Description |
|--------|-------------|
| `GridData` | Staggered grid for data display |
| `GridDataSuper` | Enhanced grid with header and pagination |
| `GridDataSuperSelection` | Grid with multi-select support |
| `LoadMoreWidget` | Infinite scroll trigger |
| `RelationManager` | Manages related resource lists (link/unlink) |
| `DragToScroll` | Horizontal drag-to-scroll wrapper |

### Sidebar (`ui/sidebar/`)

| Widget | Description |
|--------|-------------|
| `SidebarWidget` | Collapsible sidebar navigation |
| `SidebarItem` | Individual navigation item with icon and label |

### SnackBar Helper

```dart
showSnackBar(context, 'Operation completed!');
```

---

## `RestartWidget` — Full App Restart

Wraps the root widget to enable programmatic app restart:

```dart
// In main.dart
RestartWidget(child: MyApp())

// Anywhere in the app
RestartWidget.restartApp(context);
```

This triggers a full widget tree rebuild by changing a `UniqueKey`, causing all state to be reset.

---

## Re-exports

The `concrete` package re-exports the entire `core` package, so importing `concrete` gives you everything from both:

```dart
import 'package:concrete/concrete.dart';
// This includes: core.dart, ui/ui.dart, tools/tools.dart, restarter.dart
```
