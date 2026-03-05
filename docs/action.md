# `action` Package

> Provides a complete bulk action system for performing server-side operations on selected resources. Depends on `core`, `skeleton`, and `concrete`.

---

## Architecture

```
┌─────────────────────────────────────────────┐
│              ActionButton Widget             │
│  (Shows dialog with GeneralActionView)       │
├─────────────────────────────────────────────┤
│           ActionHandler Mixin               │
│  (Validates, fills, confirms, sends action) │
├─────────────────────────────────────────────┤
│            ActionCubit (BLoC)               │
│  (Calls ActionApiService.handleAction())    │
├─────────────────────────────────────────────┤
│           ActionApiService                  │
│  (POST multipart to /_action_ endpoint)     │
└─────────────────────────────────────────────┘
```

---

## How It Works

1. User selects items in a list (via `BaseController.selectedIds`)
2. User clicks an `ActionButton` which opens a dialog
3. The dialog shows the action form (if any) with confirm/cancel buttons
4. On confirm: validates form → fills action payload → sends to API
5. API processes the bulk action server-side

---

## Quick Start

### Define an Action

```dart
// Simple action (no custom form)
final deleteAction = GeneralAction(
  controller: productController,
  route: 'delete',
  title: 'Delete Selected',
  description: 'Delete :count selected items',
);

// Action with custom payload
final statusAction = GeneralAction(
  controller: orderController,
  route: 'change_status',
  title: 'Change Status',
  description: 'Update status for :count orders',
  formBuilder: (action) => DropdownButton(
    onChanged: (val) => action.set('status', val),
    items: [...],
  ),
);
```

### Add ActionButton to Your UI

```dart
// Generic action button
ActionButton(
  action: statusAction,
  icon: Icon(Icons.edit),
  label: 'Change Status',
)

// Built-in delete button
ActionButton.delete(controller: productController)
```

### What Gets Sent to the Server

The `ActionRequest.toJson()` produces:

```json
{
  "_action_": "change_status",
  "_type_": "product",
  "_keys_": [1, 5, 12],
  "status": "active",
  "category_id": 3
}
```

Where:
- `_action_` — The action route identifier
- `_type_` — Resource type from `BaseController.type`
- `_keys_` — Selected item IDs
- Other fields — Merged from controller filter + action payload

---

## Components Reference

### `ActionCubit`

```dart
class ActionCubit extends MyBaseBloc<ActionApiService, ActionState> {
  void runAction(ActionRequest request);
}
```

**States:**

| State | Description |
|-------|-------------|
| `ActionInitialState` | Initial idle state |
| `ActionHandlingState` | Processing the action |
| `ActionHandledState` | Action completed (contains `BasicResponse`) |
| `ActionErrorState` | Error (contains `message`) |
| `ActionValidationErrorState` | Validation error (contains `bag`) |

### `ActionApiService`

```dart
class ActionApiService extends BaseApiService {
  Future<BasicResponse<dynamic>> handleAction(ActionRequest request);
}
```

> [!TIP]
> Use `LaravelActionApiService` from the `laravel_provider` package when working with Laravel backends.

Sends a multipart POST to `{baseUrl}/_action_` using `superRequestTransform`.

### `BaseAction` / `GeneralAction`

```dart
abstract class BaseAction {
  final BaseController controller;   // Source of selected IDs + filter
  final String route;                // Action identifier
  final String? title;               // Display title
  final String? description;         // Description (:count is replaced with selection count)
  bool requireConfirmation = true;   // Show confirm dialog
  final Function(dynamic)? onHandled; // Callback after success
  final Widget Function(BaseAction)? formBuilder; // Custom form builder

  ActionRequest request();           // Builds the final request
  dynamic get(String key);           // Get payload value
  void set(String key, dynamic val); // Set payload value
}
```

### `ActionHandler` Mixin

For creating custom action views with full control:

```dart
class CustomActionView extends ActionForm<MyCustomAction> {
  const CustomActionView({required super.action});
  @override
  State createState() => _CustomActionViewState();
}

class _CustomActionViewState extends ControlledState<ActionForm<MyCustomAction>, ActionCubit>
    with ActionHandler<MyCustomAction> {

  @override
  void fillAction() {
    // Set payload values from form inputs
    widget.action.set('reason', reasonController.text);
  }

  @override
  bool get showActionView => true;

  @override
  Widget? actionView(BuildContext context, ActionState state) {
    return Form(
      key: formkey,
      child: TextFormField(controller: reasonController),
    );
  }
}
```

**ActionHandler provides:**
- Automatic BLoC wiring (`BlocProvider` + `BlocListener` + `BlocBuilder`)
- Confirmation dialog before execution
- Loading overlay during processing
- Success view with callback trigger
- Validation error display
- Error snackbar display

---

## Registration

Register the action services in your `Registrar.register()`:

```dart
Core.i.add<ActionApiService>(() => ActionApiService.instance());
Core.i.add<ActionCubit>(() => ActionCubit());
```
