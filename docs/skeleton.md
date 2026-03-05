# `skeleton` Package

> Abstract base classes and mixins that standardize how features (BLoCs, API services, forms, screens) are built. Depends only on `core`.

---

## Module Overview

| Module | Purpose |
|--------|---------|
| `bases/` | Abstract classes: `Jsonable`, `SuperModel`, `BaseModel`, `BaseMaker`, `BaseController`, `BaseAction`, `DynamicQueryRequest` |
| `bases/bloc/` | BLoC mixins: `MyBaseBloc`, `CrudBloc`, `PaginationBloc`, `StatisticsBloc`, sealed state patterns |
| `http/` | `ExceptionHandler` mixin, `BasicResponse`, `PaginationResponse`, `StatisticsResponse`, `ManageRelationRequest` |
| Root files | UI handler mixins: `ComponentHandler`, `FormHandler`, `FilterHandler`, `EditorHandler` |

---

## Serialization Hierarchy

```
Jsonable              → toJson()
  └── JsonableFromTo  → toJson(), fromJson(), merge()
       └── SuperModel → Same as JsonableFromTo (semantic alias)

BaseModel             → toJson(), getId(), getLabel()
```

### `Jsonable` — Serialization Base
```dart
abstract class Jsonable {
  Map<String, dynamic> toJson();
}
```

### `SuperModel<T>` — Full Serialization + Merge
```dart
abstract class SuperModel<T> extends JsonableFromTo<T> {}

// JsonableFromTo provides:
T fromJson(Map<String, dynamic> json);
T merge(JsonableFromTo fixed);
// merge() combines toJson() of both, with fixed values overriding nulls
```

### `BaseModel` — Domain Models
```dart
abstract class BaseModel extends Jsonable {
  int getId();      // Accesses `this.id` via dynamic
  String getLabel(); // Accesses `this.title` via dynamic
}
```

---

## BLoC System (`bases/bloc/`)

### `MyBaseBloc` — Foundation BLoC

All feature Cubits extend this. It provides:
- **API instance management** — Lazy-initialized from DI
- **Error-to-state mapping** — Automatically converts exceptions to BLoC states
- **Auth error handling** — Auto hard-logout on `AuthException`

```dart
class ProductCubit extends MyBaseBloc<ProductApiService, ProductState> {
  ProductCubit() : super(bs: ProductState());

  // `bs` is the state factory. Use it to create states:
  // bs.initial, bs.error(error: 'message'), bs.validation(bag)

  // `http()` returns the lazily-initialized API service
  void loadProduct(int id) async {
    try {
      emit(bs.loading);
      final data = await handle(http().show(id: id));
      emit(bs.loaded(data: data));
    } catch (e) {
      emit(mapErrorToState(e)); // Auto-maps exceptions to error states
    }
  }
}
```

### `MyBaseState` — State Factory Contract

```dart
abstract class MyBaseState<StateType> extends Equatable {
  StateType get initial;
  StateType error({required String error, int code = 0});
  StateType unauthorized({required String message, int code = 0});
  StateType validation(Map<String, dynamic> bag);
}
```

**Error mapping flow:**
```
DioException → ExceptionHandler.ex() → Custom Exception → mapErrorToState() → State
                                         ↕
                              AuthException → auto hard logout
                              ValidationException → bs.validation(bag)
                              PermissionException → bs.unauthorized()
                              ExceptionWithMessage → bs.error()
```

### `CrudBloc` — CRUD Operations Mixin

Add to any `MyBaseBloc` for standard show/save/delete lifecycle:

```dart
class ProductCubit extends MyBaseBloc<ProductApiService, ProductState>
    with CrudBloc<ProductApiService, ProductState, Product, ProductRequest, ProductFilter> {

  @override
  Future<Product> one({required int id, ProductFilter? params}) async =>
      (await handle(http().show(id: id, params: params)))!;

  @override
  Future<int> save({required int id, required ProductRequest request}) async =>
      (await handle(id != 0 ? http().update(id: id, request: request) : http().create(request)))!;

  @override
  Future destroy({required int id, ProductFilter? params}) async =>
      await handle(http().delete(id: id, params: params));
}
```

**Methods available after mixin:**

| Method | Effect | States Emitted |
|--------|--------|----------------|
| `show(id:)` | Fetch one resource | `loading` → `loaded(data:)` |
| `showForEdit(id:)` | Fetch for edit form | `loading` → `loaded(data:)` |
| `updateOrCreate(id:, request:)` | Create (id=0) or update | `saving` → `saved(id:)` |
| `delete(id)` | Delete resource | `deleting` → `deleted(id:)` |

### `CrudState` — CRUD State Mixin

```dart
class ProductState extends MyBaseState<dynamic>
    with CrudState<dynamic, Product> {
  @override
  get loading => ProductLoadingState();
  @override
  loaded({required Product data}) => ProductLoadedState(data: data);
  @override
  get saving => ProductSavingState();
  @override
  saved({required int id}) => ProductSavedState(id: id);
  @override
  get deleting => ProductDeletingState();
  @override
  deleted({required int id}) => ProductDeletedState(id: id);
  // ... plus initial, error, validation from MyBaseState
}
```

### `PaginationBloc` — Paginated Data Mixin

Add for paginated list features:

```dart
class ProductListCubit extends MyBaseBloc<ProductApiService, ProductListState>
    with PaginationBloc<ProductApiService, ProductListState, Product, ProductFilter> {

  @override
  ProductFilter defaultFilter() => ProductFilter();

  @override
  Future<PaginationResponse<Product>> load() async =>
      (await handle(http().paging(page: page, request: filter)))!;

  @override
  Future<List<Product>> loadAll() async =>
      (await handle(http().all(request: filter)))!;
}
```

**Properties and methods:**

| Property/Method | Type | Description |
|-----------------|------|-------------|
| `lista` | `List<Model>` | In-memory cache of loaded items |
| `page` | `int` | Current page number |
| `total` | `int?` | Total items from server |
| `perPage` | `int?` | Items per page |
| `maxReached` | `bool` | True when no more pages |
| `pages` | `List<int>` | Page number list |
| `filter` | `SearchFilter` | Active filter |
| `loadNext()` | — | Load next page |
| `loadPrevious()` | — | Load previous page |
| `loadPage(p)` | — | Load specific page |
| `refresh()` | — | Reset and reload page 1 |
| `refreshAll()` | — | Reset and load all at once |
| `refreshPage()` | — | Reload current page |
| `getAll()` | — | Load all results |
| `offlinePaging` | `bool` | Enable client-side paging of cached data |

### `StatisticsBloc` — Statistics Data Mixin

```dart
mixin StatisticsBloc<...> on MyBaseBloc<...> {
  StatisticsResponse? statistics;

  Future<StatisticsResponse> loadStatistics({required Filter params, String? path});

  void getStatistics({required Filter params, String? path});
  // Emits: statisticsLoading → statisticsLoaded(data:)
}
```

### Sealed State Pattern

Helper mixins for exhaustive state matching in widgets:

```dart
// On the state class
class MyState with SealedPagingState<Initial, Loading, Loaded, Error> {}

// In widgets
state.builder(
  initial: (s) => EmptyView(),
  loading: (s) => CircularProgressIndicator(),
  loaded: (s) => ListView(...),
  error: (s) => ErrorView(s.message),
);
```

---

## HTTP Layer (`http/`)

### `ExceptionHandler` Mixin

Provides two key methods for handling API responses in Cubits:

```dart
// Unwrap response.data, throw custom exception on failure
final data = await handle(http().show(id: 1));

// Get the full BasicResponse envelope
final response = await handleRoot(http().show(id: 1));
print(response.message);
```

**`ex()` — Exception Conversion:**

| DioException Status | Custom Exception |
|---------------------|-----------------|
| 401 | `AuthException` |
| 403 | `PermissionException` |
| 404 | `NotFoundException` |
| 422 | `ValidationException` (with bag) |
| 4xx | `ClientException` |
| 5xx | `ServerException` |
| `SocketException` | `NoInternetException` |

### `BasicResponse<T>` — Standard API Envelope

```dart
class BasicResponse<T> {
  final int? code;
  final String? message;
  final String? error;
  final Map<String, dynamic>? validation;
  final T? data;
}
```

Expected server JSON format:
```json
{
  "code": 200,
  "message": "Success",
  "data": { ... },
  "error": null,
  "validation": null
}
```

### `PaginationResponse<T>` — Paginated Data Wrapper

```dart
class PaginationResponse<T> {
  List<T>? data;
  int? total;
  int? perPage;
}
```

### `StatisticsResponse` — BI/Analytics Data

```dart
class StatisticsResponse {
  final StatMeta meta;        // metric, currency, timezone, granularity
  final StatsSummary? summary; // value, formatted, trend
  final List<StatPoint> dataset; // label, group, value, previousValue, transforms
}
```

### `ManageRelationRequest` — Relationship Management

```dart
ManageRelationRequest(
  name: 'roles',       // Relationship name
  action: 'link',      // 'link', 'unlink', or null for sync
  ids: [1, 2, 3],      // Related IDs
  additional: {'pivot_field': 'value'},
)
```

---

## `BaseApiService` — CRUD API Contract

All API services extend this to get a standardized CRUD interface with Retrofit:

```dart
abstract class BaseApiService<Model, EditRequest, SearchRequest, ID> {
  Future<BasicResponse<Model>> show({required ID id, SearchRequest? params});
  Future<BasicResponse<Model>> showForEdit({required ID id, SearchRequest? params});
  Future<BasicResponse<List<Model>>> all({required SearchRequest request});
  Future<BasicResponse<PaginationResponse<Model>>> paging({required int page, required SearchRequest request});
  Future<BasicResponse<ID>> delete({required ID id, SearchRequest? params});
  Future<BasicResponse<ID>> create(EditRequest request);
  Future<BasicResponse<ID>> update({required ID id, required EditRequest request});
  Future<BasicResponse> manageRelations({required ID id, required ManageRelationRequest request});
}
```

> [!TIP]
> Use `LaravelApiService` or `SupabaseApiService` from their respective provider packages instead of implementing this from scratch.

---

## `BaseController` — Filter & Selection Manager

Coordinates filter state and item selection for list screens:

```dart
class ProductController extends BaseController<ProductFilter, Product> {
  ProductController() : super(type: 'product');

  @override
  ProductFilter get newInstance => ProductFilter();
}
```

**Key properties:**

| Property | Type | Description |
|----------|------|-------------|
| `type` | `String` | Resource type name (e.g., 'product') |
| `filter` | `TFilterRequest` | Active filter state |
| `fixed` | `TFilterRequest` | Unmodifiable base filter (prevents user from clearing) |
| `request` | `TFilterRequest` | Merged filter + fixed |
| `fields` | `List<String>` | Requested API fields |
| `forAdmin` | `bool` | Targets admin API |
| `selectedIds` | `List<int>` | Currently selected item IDs |
| `selectedIndexes` | `List<int>` | Currently selected indexes |
| `enableSelection` | `bool` | Whether selection is enabled |

---

## `BaseMaker` — Model ↔ Request Bridge

Bridges data models and edit request objects for CRUD forms:

```dart
class ProductMaker extends BaseMaker<Product, ProductRequest> {
  ProductMaker({super.model, super.request, super.fixed});

  @override
  ProductRequest get newInstance => ProductRequest();
}
```

**Lifecycle:**
1. Constructor receives either a `model` (edit mode) or nothing (create mode)
2. `fillFromModel()` converts Model → Request via `modelToRequest()`
3. Form widget uses `maker.form` to bind inputs
4. On submit: `maker.fill!()` populates `maker.form` from inputs
5. `maker.request` returns merged form + fixed data for the API call

**Key properties:**

| Property | Description |
|----------|-------------|
| `id` | 0 for creation, model's ID for editing |
| `form` | Mutable request being edited |
| `fixed` | Immutable fields merged into final request |
| `request` | `form.merge(fixed)` — the final submission payload |
| `validate` | Proxy to FormState.validate() |
| `fill` | Proxy to fillMaker() in FormHandler |

---

## `BaseAction` — Bulk Action Definition

```dart
class ExportAction extends BaseAction {
  ExportAction({required super.controller})
    : super(
        route: 'export',
        title: 'Export Selected',
        description: 'Export :count items',
      );
}
```

### `ActionRequest` — Action Payload

Serialized with:
- `_action_` — The action route identifier
- `_type_` — The resource type from the controller
- `_keys_` — Selected item IDs
- Filter fields from `controller.request`
- Custom `payload` fields

---

## `DynamicQueryRequest` — Advanced Query Builder

Base class for filter request models. Supports the backend query engine:

```dart
class ProductFilter extends DynamicQueryRequest<ProductFilter> {
  String? name;
  int? categoryId;

  // Inherited query parameters:
  // page, perPage, limit, getAll
  // fields (field selection: _fields[])
  // sort (_sort[])
  // logic (_logic: AND/OR)
  // operators (_operators: {'price': '>', 'name': 'like%'})
  // clauses (_clauses: {'count': 'having'})
  // metric, group, transform, compare, compareOn, timezone (BI engine)
}
```

---

## UI Handlers

### `FormHandler` — Edit Form State Mixin

```dart
class ProductFormWidget extends EditForm<Product, ProductRequest, ProductMaker> {
  const ProductFormWidget({required super.maker});

  @override
  State createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductFormWidget>
    with FormHandler<Product, ProductRequest, ProductMaker> {

  @override
  void fillForm() {
    // Fill text controllers from widget.maker.form
    nameCtrl.text = widget.maker.form.name ?? '';
  }

  @override
  void fillMaker() {
    // Fill maker.form from text controllers
    widget.maker.form.name = nameCtrl.text;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formkey,
      child: Column(children: [
        if (isVisibleField('name'))
          TextFormField(
            controller: nameCtrl,
            validator: (v) => validation?['name'],
          ),
      ]),
    );
  }
}
```

### `FilterHandler` — Search Filter Form Mixin

Same pattern as `FormHandler` but uses `BaseController` instead of `BaseMaker`:

```dart
class ProductFilterWidget extends FilterForm<ProductFilter, Product, ProductController> {
  const ProductFilterWidget({required super.controller});
  @override
  State createState() => _ProductFilterState();
}

class _ProductFilterState extends State<ProductFilterWidget>
    with FilterHandler<ProductFilter, Product, ProductController> {

  @override
  void fillForm() { /* Fill inputs from controller.filter */ }

  @override
  void fillFilter() { /* Fill controller.filter from inputs */ }
}
```

### `EditorHandler` — Editor Screen Mixin

Combines `ControlledState` with `BaseMaker` for complete CRUD screens:

```dart
class _ProductEditorState extends ControlledState<ProductEditor, ProductCubit>
    with EditorHandler<Product, ProductRequest, ProductMaker, ProductEditor, ProductCubit> {

  @override
  void initState() {
    maker = ProductMaker(model: widget.product);
    super.initState();
  }

  @override
  void save() {
    store.updateOrCreate(id: maker.id, request: maker.request);
  }

  // Call `send()` to validate-then-save
}
```

### `ComponentHandler` — List Item Handler

```dart
abstract class ComponentHandler<TModel, TState> {
  void onAction(TModel item, UserAction action, {int index = -1});
  void setController();
  Widget listBuilder(BuildContext context, TState state);
}
```
