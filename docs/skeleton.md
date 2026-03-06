# skeleton

> **Abstract API contracts, base models, BLoC mixins, and form handlers.**

The `skeleton` package defines the **contracts and abstractions** that all backend providers must implement. It is backend-agnostic — it doesn't know whether your data comes from Laravel, Supabase, or any other source.

**Depends on:** `core`

---

## Table of Contents

- [Model Hierarchy](#model-hierarchy)
- [BaseApiService](#baseapiservice)
- [BaseController](#basecontroller)
- [BaseMaker](#basemaker)
- [BLoC Layer](#bloc-layer)
  - [MyBaseBloc](#mybasebloc)
  - [CrudBloc](#crudbloc)
  - [PaginationBloc](#paginationbloc)
  - [StatisticsBloc](#statisticsbloc)
  - [AutoCrudBloc & AutoPaginationBloc](#autocrudbloc--autopaginationbloc)
  - [OptimisticCrud](#optimisticcrud)
  - [RealtimeSync](#realtimesync)
  - [Sealed States](#sealed-states)
- [HTTP Layer](#http-layer)
- [Form Handlers](#form-handlers)
- [PaginationStrategy](#paginationstrategy)

---

## Model Hierarchy

```
Jsonable                    ← has toJson()
└── JsonableFromTo<T>       ← adds fromJson() + merge()
    └── SuperModel<T>       ← alias for use in generics

Identifiable<T>             ← has id getter
Labelable                   ← has label getter

BaseModel<T>                ← combines Jsonable + Identifiable + Labelable
```

### Usage

**Data model:**
```dart
class User extends BaseModel<int> {
  @override final int id;
  @override final String label;
  final String email;

  User({required this.id, required this.label, required this.email});

  @override
  Map<String, dynamic> toJson() => {'id': id, 'name': label, 'email': email};
}
```

**Request / filter model:**
```dart
class UserRequest extends SuperModel<UserRequest> {
  String? name;
  String? email;

  @override
  Map<String, dynamic> toJson() => {'name': name, 'email': email};

  @override
  UserRequest fromJson(Map<String, dynamic> json) =>
    UserRequest()..name = json['name']..email = json['email'];
}
```

---

## BaseApiService

The **core contract** every API service must implement:

```dart
abstract class BaseApiService<Model, EditRequest, SearchRequest, ID> {
  Future<ApiResponse<Model>> show({required ID id, SearchRequest? params});
  Future<ApiResponse<Model>> showForEdit({required ID id, SearchRequest? params});
  Future<ApiResponse<List<Model>>> all({required SearchRequest request});
  Future<ApiResponse<PaginatedResponse<Model>>> paging({required int page, required SearchRequest request});
  Future<ApiResponse<ID>> delete({required ID id, SearchRequest? params});
  Future<ApiResponse<ID>> create(EditRequest request);
  Future<ApiResponse<ID>> update({required ID id, required EditRequest request});
  Future<ApiResponse<PaginatedResponse<Model>>> pagingCustomPath({...});
  Future<ApiResponse> manageRelations({required ID id, required dynamic request});
}
```

**Type Parameters:**

| Param | Description | Example |
|-------|-------------|---------|
| `Model` | The data model | `User` |
| `EditRequest` | Create/update request | `UserRequest` |
| `SearchRequest` | Filter/search | `UserFilter` |
| `ID` | Resource identifier type | `int` or `String` |

---

## BaseController

Manages **filter state and selection** for list/grid screens:

```dart
abstract class BaseController<TFilterRequest, TModel, ID> {
  String type;           // Resource type name (e.g. "user")
  bool forAdmin;         // Whether using admin API
  TFilterRequest filter; // Active search filter
  TFilterRequest fixed;  // Immutable filter fields
  List<String> fields;   // Requested fields for sparse responses
  
  // Selection
  bool enableSelection;
  List<int> selectedIndexes;
  List<ID> selectedIds;
  void onSelection(List<int> indexes, List<ID> ids);
  
  // Filter management
  TFilterRequest get request;  // Merged filter + fixed
  void clear();
  void fillFromQuery(Map<String, String> params);
  void fillFromJson(Map<String, dynamic> json);
  
  // Callbacks
  Function()? refresh;
  Function(List<TModel> items, UserAction action)? bulkAction;
}
```

### Example

```dart
class UserController extends BaseController<UserFilter, User, int> {
  UserController() : super(type: 'user');

  @override
  UserFilter get newInstance => UserFilter();
}
```

---

## BaseMaker

The **form state holder** for Create/Edit screens. Bridges the gap between a data `Model` and an `EditRequest`:

```dart
abstract class BaseMaker<TModel, TRequest, ID> {
  ID? id;               // null = creation, non-null = editing
  TRequest form;        // Editable fields
  TRequest fixed;       // Unmodifiable fields
  
  TRequest get request; // Merged form + fixed (final submission)
  
  // File attachments
  void setAttachment(String key, dynamic value);
  Map<String, dynamic> get attachments;
  
  // Form lifecycle
  bool Function()? validate;  // Proxy to FormState.validate()
  Function()? fill;           // Read form inputs into request
  set model(TModel data);     // Pre-fill form from model
  
  // Overrides
  TRequest jsonToRequest(Map<String, dynamic> json);
  TRequest get newInstance;
}
```

### Example

```dart
class UserMaker extends BaseMaker<User, UserRequest, int> {
  UserMaker({User? model, UserRequest? request})
      : super(model: model, request: request);

  @override
  UserRequest jsonToRequest(Map<String, dynamic> json) =>
    UserRequest()..name = json['name']..email = json['email'];

  @override
  UserRequest get newInstance => UserRequest();
}
```

---

## BLoC Layer

### MyBaseBloc

The root BLoC class. All feature cubits extend from this:

```dart
abstract class MyBaseBloc<ApiType extends BaseApiService, BaseState extends MyBaseState>
    extends Cubit<BaseState> {
  ApiType? api;
  BaseState bs;          // State factory
  bool forAdmin;

  ApiType http();        // Lazy API accessor (uses Core.get<ApiType>())
  BaseState mapErrorToState(dynamic e);  // Error → state mapping
  Future<T> handle<T>(Future<T> future); // Error-safe wrapper
}
```

### MyBaseState

```dart
abstract class MyBaseState<StateType> extends Equatable {
  StateType get initial;
  StateType error({required String error, int code = 0});
  StateType unauthorized({required String message, int code = 0});
  StateType validation(Map<String, dynamic> bag);
}
```

---

### CrudBloc

Mixin adding **single-resource CRUD** operations:

```dart
mixin CrudBloc<ApiType, BaseState, Model, Request, Filter, ID>
    on MyBaseBloc<ApiType, BaseState> {

  Model? model;

  void show({required ID id, Filter? params});          // Fetch one
  void showForEdit({required ID id, Filter? params});   // Fetch for editing
  void updateOrCreate({required ID id, required Request request}); // Save
  void delete(ID id, {Filter? params});                 // Delete
}
```

**States (via `CrudState` mixin):** `loading`, `loaded(data)`, `saving`, `saved(id)`, `deleting`, `deleted(id)`

---

### PaginationBloc

Mixin adding **paginated list** operations:

```dart
mixin PaginationBloc<ApiType, BaseState, Model, SearchFilter>
    on MyBaseBloc<ApiType, BaseState> {

  List<Model> lista = [];  // In-memory cache
  int page = 0;
  bool maxReached = false;
  int? total, perPage;

  Future loadNext();
  Future loadPrevious();
  Future loadPage(int p);
  Future refresh({SearchFilter? filter});  // Reset + load page 1
  Future refreshAll({SearchFilter? filter}); // Load everything
  Future<bool> getAll();                     // Load all at once
  
  // Offline paging (paginate in-memory data)
  bool offlinePaging = false;
}
```

**States (via `PaginationState` mixin):** `pageLoading`, `pageLoaded(data, maxReached, nextPage)`

---

### StatisticsBloc

Mixin for fetching aggregate data / statistics:

```dart
mixin StatisticsBloc<ApiType, BaseState, Filter>
    on MyBaseBloc<ApiType, BaseState> {
  void getStatistics({dynamic id, required Filter params, String? path});
}
```

**States:** `statisticsLoading`, `statisticsLoaded(data)`

---

### AutoCrudBloc & AutoPaginationBloc

**Zero-boilerplate** mixins that auto-implement the abstract methods using the `BaseApiService` contract:

```dart
mixin AutoCrudBloc<...> on CrudBloc<...> {
  // Automatically implements: one(), save(), destroy()
}

mixin AutoPaginationBloc<...> on PaginationBloc<...> {
  // Automatically implements: load(), loadAll()
}
```

Using these eliminates the need to override `one()`, `save()`, `destroy()`, `load()`, and `loadAll()` in your cubits.

---

### OptimisticCrud

Mixin for **optimistic UI updates** — the UI updates immediately and rolls back on failure:

```dart
mixin OptimisticCrud<...> on CrudBloc<...> {
  void deleteOptimistic(ID id, {Filter? params});
  void updateOptimistic({
    required ID id,
    required Request request,
    required Model Function(Model current, Request request) applyChanges,
  });
}
```

---

### RealtimeSync

Mixin for **real-time data synchronization** via streams:

```dart
mixin RealtimeSync<...> on MyBaseBloc<...> {
  void startSync<T>(Stream<T> stream, void Function(T event) onUpdate);
  void stopSync();
}
```

Automatically cancels the subscription when the cubit is closed.

---

### Sealed States

A modern sealed-class state hierarchy for simpler state matching:

```dart
sealed class AppState extends Equatable {}
class InitialState extends AppState {}
class LoadingState extends AppState {}
class LoadedState<T> extends AppState { final T data; }
class ErrorState extends AppState { final String message; }
class ValidationErrorState extends AppState { final Map<String, dynamic> errors; }
class SavingState extends AppState {}
class DeletingState extends AppState {}
class ActionSuccessState<ID> extends AppState { final ID id; }
```

Use with Dart's `switch` pattern matching:

```dart
return switch (state) {
  InitialState() => Container(),
  LoadingState() => CircularProgressIndicator(),
  LoadedState(:final data) => Text(data.toString()),
  ErrorState(:final message) => Text(message),
  _ => SizedBox.shrink(),
};
```

---

## HTTP Layer

### `ApiResponse<T>`

Generic wrapper for all API responses:

```dart
class ApiResponse<T> {
  final T? data;
  final String? message;
  final dynamic error;
}
```

### `PaginatedResponse<T>`

```dart
class PaginatedResponse<T> {
  final List<T> data;
  final int total;
  final int perPage;
  final int currentPage;
  int get lastPage;
}
```

### `StatisticsResponse`

Defined in `http/stats_response.dart` for aggregate data endpoints.

### `ManageRelationRequest`

A JSON-serializable model for managing many-to-many relationships.

---

## Form Handlers

### `EditForm` + `FormHandler`

For Create/Edit data forms:

```dart
class UserEditForm extends EditForm<User, UserRequest, UserMaker, int> {
  const UserEditForm({required super.maker});

  @override
  State<UserEditForm> createState() => _UserEditFormState();
}

class _UserEditFormState extends State<UserEditForm>
    with FormHandler<User, UserRequest, UserMaker, int> {

  @override
  void fillForm() {
    // Pre-fill text controllers from widget.maker.form
    nameCtrl.text = widget.maker.form.name ?? '';
  }

  @override
  void fillMaker() {
    // Read form inputs back into the maker
    widget.maker.form.name = nameCtrl.text;
  }
}
```

### `FilterForm` + `FilterHandler`

Same pattern but for search/filter forms. Works with `BaseController`:

```dart
class UserFilterForm extends FilterForm<UserFilter, User, UserController, int> {
  const UserFilterForm({required super.controller});
  // ...
}
```

### `EditorHandler`

Mixin for editor screens that bridges `BaseMaker` with `ControlledState`:

```dart
mixin EditorHandler<TModel, TRequest, TMaker, TWidget, TBind, ID>
    on ControlledState<TWidget, TBind> {
  late TMaker maker;  
  void send();  // Validates + fills + saves
  void save();  // Abstract — implement the save logic
}
```

### `ComponentHandler`

Abstract handler for list/grid item interactions:

```dart
abstract class ComponentHandler<TModel, TState> {
  void onAction(TModel item, UserAction action, {int index = -1});
  Widget listBuilder(BuildContext context, TState state);
}
```

---

## PaginationStrategy

Pluggable strategy for different pagination approaches:

```dart
abstract class PaginationStrategy<Model, Filter> {
  Future<PaginatedResponse<Model>> getPage({...});
}

// Built-in strategies:
class OffsetPaginationStrategy<Model, Filter> implements PaginationStrategy<...> {}
class CursorPaginationStrategy<Model, Filter> implements PaginationStrategy<...> {}
```
