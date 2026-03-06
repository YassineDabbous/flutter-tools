# action

> **Bulk actions, undo/redo, batch progress tracking, and action UI widgets.**

The `action` package provides a system for running server-side bulk operations on selected resources, with UI components for confirmation dialogs and progress tracking.

**Depends on:** `core`, `skeleton`, `concrete`

---

## Table of Contents

- [Core Concepts](#core-concepts)
- [BaseAction & ActionRequest](#baseaction--actionrequest)
- [ActionCubit](#actioncubit)
- [ActionHandler (UI Mixin)](#actionhandler-ui-mixin)
- [ActionButton & BulkActionForm](#actionbutton--bulkactionform)
- [UndoableAction & UndoManager](#undoableaction--undomanager)
- [BatchProgress](#batchprogress)

---

## Core Concepts

The action system works in 3 steps:

1. **Define** a `BaseAction` with a route and optional form
2. **Present** it via `ActionButton` (which shows a confirmation dialog)
3. **Execute** it through `ActionCubit`, which calls the `ActionApiService`

---

## BaseAction & ActionRequest

### `BaseAction`

Defines a bulk action that can be performed on selected resources:

```dart
class BaseAction {
  final BaseController controller;  // Source of selected items & filters
  final String route;               // Action identifier (e.g. 'delete', 'assign-driver')
  final String? title;
  final String? description;
  final Function(dynamic)? onHandled;  // Callback after success
  bool requireConfirmation = true;
  final Widget Function(BaseAction)? formBuilder;  // Optional form
  
  ActionRequest request();        // Builds the action request
  void set(String key, dynamic value); // Set payload fields
  dynamic get(String key);        // Get payload fields
}
```

### `ActionRequest`

The serializable request payload sent to the API:

```dart
class ActionRequest extends SuperModel<ActionRequest> {
  String action;                    // Action route
  String type;                      // Resource type
  List<dynamic>? keys;              // Selected resource IDs
  Map<String, dynamic>? filter;     // Active filter
  Map<String, dynamic>? payload;    // Custom action data
}
```

The `toJson()` merges payload + filter + meta fields (`_action_`, `_type_`, `_keys_`).

---

## ActionCubit

BLoC that executes actions via `ActionApiService`:

```dart
class ActionCubit extends MyBaseBloc<ActionApiService, ActionState> {
  void runAction(ActionRequest request);
}
```

**States:**

| State | When |
|-------|------|
| `ActionInitialState` | Initial |
| `ActionHandlingState` | Request in progress |
| `ActionHandledState` | Success (contains `ApiResponse data`) |
| `ActionErrorState` | Error (contains `String message`) |
| `ActionValidationErrorState` | Validation errors (contains `Map bag`) |

---

## ActionHandler (UI Mixin)

Mixin for action form screens. Provides the full UI lifecycle:

```dart
mixin ActionHandler<TAction extends BaseAction>
    on ControlledState<ActionForm<TAction>, ActionCubit> {

  void fillAction();     // Fill action payload from form inputs
  bool validateAction(); // Validate the form
  void runAction();      // Execute with optional confirmation
  void listener(BuildContext context, ActionState state); // State listener
  
  bool get showActionView;
  Widget? actionView(BuildContext context, ActionState state);
}
```

The default `build()` renders a card with:
- Title and description
- Validation errors
- Custom action form (if `showActionView` is true)
- Confirm / Cancel buttons
- Loading overlay during execution
- Success overlay on completion

---

## ActionButton & BulkActionForm

### `ActionButton`

A pre-built button that opens the action dialog:

```dart
ActionButton(
  icon: Icon(Icons.delete),
  label: 'Delete Selected',
  action: GeneralAction(
    controller: myController,
    route: 'delete',
    description: 'Delete :count items',
    onHandled: (result) => cubit.refresh(),
  ),
)

// Factory shortcut:
ActionButton.delete(controller: myController)
```

### `GeneralActionView`

The default action form view. Uses `GeneralAction` and the `ActionHandler` mixin.

---

## UndoableAction & UndoManager

Client-side undo/redo support:

```dart
abstract class UndoableAction {
  Future<void> execute();
  Future<void> undo();
  String get label;
}

class UndoManager {
  void execute(UndoableAction action);
  void undoLast();
  bool get canUndo;
}
```

### Example

```dart
class DeletePostAction extends UndoableAction {
  final Post post;
  DeletePostAction(this.post);

  @override String get label => 'Delete ${post.title}';
  @override Future<void> execute() => api.deletePost(post.id);
  @override Future<void> undo() => api.restorePost(post);
}

// Usage:
final manager = UndoManager();
await manager.execute(DeletePostAction(post));
// Show snackbar with "Undo" button
if (userTappedUndo) manager.undoLast();
```

---

## BatchProgress

Tracks the progress of batch operations:

```dart
class BatchProgress extends Equatable {
  final int total;
  final int completed;
  final int failed;
  final String? currentActionLabel;

  double get progress;   // 0.0 to 1.0
  bool get isFinished;   // completed + failed >= total
}
```

Use it to show progress bars for multi-step operations:

```dart
// Track batch deletion
var progress = BatchProgress(total: items.length);
for (final item in items) {
  try {
    await api.delete(item.id);
    progress = progress.copyWith(completed: progress.completed + 1);
  } catch (_) {
    progress = progress.copyWith(failed: progress.failed + 1);
  }
  emit(BatchInProgress(progress));
}
```
