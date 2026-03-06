# Architecture Improvements

Structural changes that would improve maintainability, scalability, and clarity of the SDK.

---

## 1. `ControlledState` Closes BLoCs It Doesn't Own

**File:** `core/lib/app/controlled_state.dart`

**Problem:** `ControlledState` fetches a BLoC from DI and **closes it on dispose**. If the same BLoC is registered as a singleton (which is the default via `Registrar`), disposing it in one widget kills it for every other widget that references it.

```dart
// Current — dangerous with singletons:
@override
void dispose() {
  if (store is Bloc) {
    (store as Bloc).close();  // 💥 kills a shared singleton
  }
  super.dispose();
}
```

**Suggestion:** Make closing opt-in. The widget creating the BLoC should be the one that decides whether to close it:

```dart
abstract class ControlledState<TWidget extends StatefulWidget, TStore extends Object>
    extends State<TWidget> {
  final TStore store = Core.get<TStore>();
  
  /// Override and return true if this widget "owns" the BLoC lifecycle.
  bool get ownsStore => false;

  @override
  void dispose() {
    if (ownsStore && store is Bloc) {
      (store as Bloc).close();
    }
    super.dispose();
  }
}
```

**Impact:** 🔴 High — prevents subtle bugs where navigation or widget rebuild silently kills a global BLoC.

---

## 2. Move `BaseApiService` to a Pure Dart Package

**Problem:** `skeleton` depends on Flutter (`flutter_bloc`, `flutter/widgets.dart`) even though `BaseApiService`, `Jsonable`, `ApiResponse`, and `PaginatedResponse` are pure Dart contracts with zero Flutter dependency. This makes them unusable in CLI tools, server-side Dart, or `dart:isolate` workers.

**Suggestion:** Extract a `skeleton_core` (or `contracts`) pure Dart package:

```
skeleton_core/  (pure Dart, no Flutter)
├── base_api.dart
├── jsonable.dart
├── response.dart
├── pagination_strategy.dart
└── failures.dart          (move from core)

skeleton/  (Flutter, depends on skeleton_core)
├── bases/bloc/...
├── form_handler.dart
└── ...
```

**Impact:** 🟡 Medium — enables sharing models and API contracts with backend Dart code and isolates.

---

## 3. Remove Circular Re-Export in `concrete`

**File:** `concrete/lib/concrete.dart`

**Problem:** `concrete.dart` re-exports `package:core/core.dart`. This creates a confusing dependency where importing `concrete` gives you everything from `core` too. It makes it hard to trace where a symbol actually comes from and can cause ambiguous import conflicts.

```dart
// Current:
export 'package:core/core.dart';  // ← re-exports all of core
export 'ui/ui.dart';
export 'tools/tools.dart';
```

**Suggestion:** Remove the re-export. Let consumers explicitly import the packages they need:

```dart
// Improved:
export 'ui/ui.dart';
export 'tools/tools.dart';
export 'restarter.dart';
// consumers add: import 'package:core/core.dart'; themselves
```

**Impact:** 🟢 Low — cleaner imports, no behavior change.

---

## 4. Decouple `action` Package from `concrete`

**Problem:** The `action` package depends on `concrete` purely for UI helpers like `dialogConfirmation`, `showSnackBar`, `ValidationMessage`, and `Edges`/`Sz` constants. This means any project that wants the action *logic* (ActionCubit, ActionRequest, UndoManager) must also pull in the entire UI package with 50+ widgets.

**Suggestion:** Split `action` into two packages:

```
action_core/   (pure logic, depends only on skeleton)
├── action_cubit.dart
├── action_request.dart
├── undoable_action.dart
└── batch_progress.dart

action/        (UI layer, depends on action_core + concrete)
├── action_handler.dart
└── bulk_action_form.dart
```

**Impact:** 🟡 Medium — allows using action logic without the UI layer.

---

## 5. Make the `Initializer` Class Name More Descriptive

**File:** `core/lib/app/initializer.dart`

**Problem:** The initializer interface is simply called `I`, which is extremely cryptic and collides with common naming conventions:

```dart
abstract class I {
  Future init();
  void refresh();
  void activate({required AuthResponse user});
  void deactivate({AuthResponse? user});
}
```

**Suggestion:** Rename to something self-documenting:

```dart
abstract class ServiceInitializer { ... }
// or
abstract class LifecycleService { ... }
```

**Impact:** 🟢 Low — readability improvement, easy refactor.

---

## 6. `DynamicQueryRequest.toJson()` is Not Implemented

**File:** `skeleton/lib/bases/dynamic_query_request.dart`

**Problem:** `DynamicQueryRequest` has a rich field set (pagination, sorting, operators, statistics) but `toJson()` and `fromJson()` are commented out. The `@JsonSerializable` annotation is also commented out. This means any subclass must manually implement serialization, defeating the purpose of having a base class.

```dart
// Commented out:
// @JsonSerializable(genericArgumentFactories: true, includeIfNull: false)
// ...
// factory DynamicQueryRequest.fromJson(...) => _$DynamicQueryRequestFromJson(json);
// Map<String, dynamic> toJson() => _$DynamicQueryRequestToJson(this);
```

**Suggestion:** Uncomment the `@JsonSerializable` annotation and run `build_runner`, or manually implement `toJson()`/`fromJson()` so subclasses inherit serialization for free.

**Impact:** 🟡 Medium — unlocks the fluent query builder pattern shown in the code.

---

## 7. Standardize the Provider Package API Surface

**Problem:** `LaravelApiService` and `SupabaseApiService` have asymmetric API surfaces:

| Feature | Laravel Provider | Supabase Provider |
|---------|-----------------|-------------------|
| Built-in CRUD | ❌ Abstract only | ✅ show/create/update/delete |
| `showForEdit` | ❌ Not implemented | ❌ Not implemented |
| `all()` | ❌ Not implemented | ❌ Not implemented |
| `paging()` | ✅ Works | ❌ Throws `UnimplementedError` |
| `manageRelations()` | ❌ Not implemented | ❌ Throws `UnimplementedError` |
| Error mapping | ✅ Via `LaravelErrorMapper` | ✅ Built into `handle()` |

**Suggestion:** Both providers should either implement or explicitly document which methods they support. Consider using `@mustBeOverridden` annotations or a "supported operations" set:

```dart
Set<CrudOperation> get supportedOperations => {
  CrudOperation.show,
  CrudOperation.create,
  CrudOperation.update,
  CrudOperation.delete,
  CrudOperation.paging,
};
```

**Impact:** 🟡 Medium — prevents runtime `UnimplementedError` surprises.

---

## 8. The `forAdmin` Flag Pattern is Fragile

**Problem:** A `forAdmin` boolean exists in `BaseController`, `MyBaseBloc`, and `PaginationBloc`. It controls behavior like clearing the list before appending new pages (line 146-148 of `base_pagination_cubit.dart`). This conflates "admin mode" with "replace-vs-append pagination" and makes the behavior implicit.

```dart
// In PaginationBloc.move():
if (forAdmin) {
  lista.clear();  // Admin = replace mode
}
lista.addAll(l);  // Non-admin = append mode (infinite scroll)
```

**Suggestion:** Replace with an explicit `PagingMode` enum:

```dart
enum PagingMode { infiniteScroll, paginated }

// In PaginationBloc:
PagingMode pagingMode = PagingMode.infiniteScroll;

// In move():
if (pagingMode == PagingMode.paginated) {
  lista.clear();
}
```

**Impact:** 🟡 Medium — makes behavior explicit and self-documenting.
