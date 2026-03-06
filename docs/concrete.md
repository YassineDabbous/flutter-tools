# concrete

> **UI widgets, display components, input fields, tools, and shared utilities.**

The `concrete` package provides the **presentation layer** — reusable Flutter widgets, input components, media display, navigation components, data grids, and utility tools. It re-exports `core` for convenience.

**Depends on:** `core`, `skeleton`

---

## Table of Contents

- [Module Structure](#module-structure)
- [Display Components](#display-components)
- [Input Components](#input-components)
- [Media Components](#media-components)
- [Modal Dialogs](#modal-dialogs)
- [Scroll & Data Grids](#scroll--data-grids)
- [Sidebar Navigation](#sidebar-navigation)
- [State Widgets](#state-widgets)
- [Feedback](#feedback)
- [Geo Components](#geo-components)
- [Loader Components](#loader-components)
- [Tools](#tools)
- [Restarter](#restarter)

---

## Module Structure

```
concrete/lib/
├── concrete.dart            # barrel export
├── restarter.dart           # Hot restart widget
├── tools/                   # Utility classes
│   ├── linker.dart         # Deep link handler
│   ├── my_clipboard.dart   # Clipboard helper
│   ├── network_checker.dart# Connectivity monitor
│   └── sharer.dart         # Share via platform sheet
├── ui/
│   ├── display/            # Text, messages, errors
│   ├── feedback/           # Snackbars
│   ├── geo/                # Coordinates, geo button
│   ├── inputs/             # Form fields
│   ├── loaders/            # Shimmer placeholders
│   ├── media/              # Images, SVG
│   ├── modals/             # Dialogs, bottom sheets
│   ├── scroll/             # Data grids, load more, relations
│   ├── sidebar/            # Sidebar navigation
│   └── states/             # Empty state, error state
└── actions/                # UI action extensions
```

---

## Display Components

| Widget | File | Description |
|--------|------|-------------|
| `InteractiveText` | `InteractiveText.dart` | Text with clickable emails, URLs, hashtags |
| `Message` | `message.dart` | Status messages (info, success, error) |
| `Message.error()` | `message.dart` | Error message display |
| `ValidationMessage` | `message_validation.dart` | Renders validation error bags |
| `ErrorInteractiveWidget` | `error_interactive_widget.dart` | Error display with retry |

### Example

```dart
// Clickable text with auto-detected URLs and emails
InteractiveText(text: 'Contact us at hello@app.com or visit https://app.com')

// Validation errors from API
ValidationMessage(bag: {'email': 'Email is required', 'name': 'Too short'})
```

---

## Input Components

| Widget | File | Description |
|--------|------|-------------|
| `TextInput` | `text_input.dart` | Styled text field with validation |
| `DropdownSearch` | `dropdown_search.dart` | Searchable dropdown |
| `DropdownMulti` | `dropdown_multi.dart` | Multi-select dropdown |
| `ChoiceButton` | `choice_button.dart` | Option selector |
| `DateTimePicker` | `date_time_picker.dart` | Date/time input |
| `TagsInput` | `tags_input.dart` | Tag entry widget |
| `RatingBar` | `rating_bar.dart` | Star rating input |
| `JsonEditor` | `json_editor.dart` | JSON key-value editor |
| `JsonTableEditor` | `json_table_editor.dart` | Tabular JSON editor |
| `TranslationFields` | `translation_fields.dart` | Multi-locale text inputs |
| `TextEditorScreen` | `text_editor_screen.dart` | Full-screen text editor |

---

## Media Components

| Widget | File | Description |
|--------|------|-------------|
| `ImageWidget` | `image_widget.dart` | Network image with caching and fallback |
| `ImageViewerScreen` | `image_viewer_screen.dart` | Full-screen image viewer |
| `SvgWidget` | `svg.dart` | SVG asset display |

---

## Modal Dialogs

Helper functions for common dialogs:

```dart
// Confirmation dialog
dialogConfirmation(
  context: context,
  title: 'Delete item?',
  onConfirm: () => cubit.delete(id),
);

// Info dialog
dialogInfoSuccess(context: context);

// Custom view dialog
dialogView(
  context: context,
  view: MyCustomWidget(),
  maxWidth: 400,
  maxHeight: 300,
);
```

---

## Scroll & Data Grids

| Widget | File | Description |
|--------|------|-------------|
| `GridData` | `grid_data.dart` | Basic data grid |
| `GridDataSuper` | `grid_data_super.dart` | Advanced data grid with sorting |
| `GridDataSuperSelection` | `grid_data_super_selection.dart` | Grid with row selection |
| `LoadMoreWidget` | `load_more_widget.dart` | "Load more" / infinite scroll |
| `RelationManager` | `relation_manager.dart` | Manage many-to-many relations UI |
| `DragToScroll` | `drag_to_scroll.dart` | Desktop drag-to-scroll |

---

## Sidebar Navigation

| Widget | File | Description |
|--------|------|-------------|
| `SidebarWidget` | `sidebar_widget.dart` | Full sidebar component |
| `SidebarItem` | `sidebar_item.dart` | Sidebar menu item |
| `Sidebar` | `sidebar.dart` | Sidebar data model |

---

## State Widgets

| Widget | Description |
|--------|-------------|
| `EmptyState` | "No data" placeholder with icon and message |
| `ErrorState` | Error display with retry button |

---

## Feedback

| Function | Description |
|----------|-------------|
| `showSnackBar(context, message)` | Show a styled snackbar |

---

## Geo Components

| Widget | Description |
|--------|-------------|
| `Coordinates` | Display lat/lng coordinates |
| `GeoLocatorButton` | Button that fetches current GPS location |

---

## Loader Components

| Widget | Description |
|--------|-------------|
| `ShimmerPlaceholder` | Shimmer loading animation |

---

## Tools

### `NetworkChecker`

Monitors internet connectivity:
```dart
final checker = Core.get<NetworkChecker>();
final isOnline = await checker.isConnected;
```

### `MyClipboard`

Copy to clipboard:
```dart
MyClipboard.copy('text to copy', context);
```

### `Sharer`

Share content via platform sharing sheet:
```dart
Sharer.share('Check out this app!', context);
```

### `Linker`

Deep link URL handling and generation.

---

## Restarter

A widget that can fully restart the widget tree (useful for logout, language change, etc.):

```dart
// Wrap your app
Restarter(child: MyApp())

// Trigger restart from anywhere:
Restarter.restartApp(context);
```
