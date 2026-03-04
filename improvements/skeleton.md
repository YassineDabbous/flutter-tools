# Skeleton Package — Improvements

---

## 🟠 1. Automatic CRUD Mixin (Zero-Boilerplate)

### Problem
As seen in the `demo` `ProductCubit`, developers must manually override 5-7 methods (`load`, `one`, `save`, etc.) only to relay calls to the `http()` service.

### Solution
Introduce `AutoCrudBloc` that uses types to find methods:

```dart
mixin AutoCrudBloc<TService extends BaseApiService<TModel, TRequest, TFilter>, TState extends MyBaseState, TModel, TRequest, TFilter> 
    on MyBaseBloc<TService, TState> {
  
  @override
  Future<TModel> one({required int id, TFilter? params}) async => 
      (await handle(http().show(id: id, params: params)))!;
      
  @override
  Future<int> save({required int id, required TRequest request}) async =>
      (await (id != 0 ? handle(http().update(id: id, request: request)) : handle(http().create(request))))!;
}
```

---

## 🟠 2. Use Dart 3 Sealed Classes for Exhaustive State Matching

### Problem
The current state system uses abstract classes (`MyBaseState<StateType>`) with dynamic type checking. Widget builders use `if (state is X)` chains which:
- Don't guarantee exhaustiveness — a missing case compiles fine but breaks at runtime
- The `SealedPagingState` mixin tries to address this but still uses `as` casts

### Solution
Leverage Dart 3's `sealed` classes:

```dart
sealed class ProductState {}

// Shared states
class ProductInitial extends ProductState {}
class ProductError extends ProductState {
  final String message;
  final int code;
  ProductError({required this.message, this.code = 0});
}
class ProductValidation extends ProductState {
  final Map<String, dynamic> bag;
  ProductValidation({required this.bag});
}

// CRUD states
class ProductLoading extends ProductState {}
class ProductLoaded extends ProductState {
  final Product data;
  ProductLoaded(this.data);
}
class ProductSaving extends ProductState {}
class ProductSaved extends ProductState {
  final int id;
  ProductSaved(this.id);
}

// Widget usage — compiler enforces exhaustiveness!
Widget build(context) => switch (state) {
  ProductInitial()   => const SizedBox(),
  ProductLoading()   => const CircularProgressIndicator(),
  ProductLoaded(:final data) => ProductView(data),
  ProductSaving()    => const SavingOverlay(),
  ProductSaved(:final id) => SuccessMessage(id),
  ProductError(:final message) => ErrorView(message),
  ProductValidation(:final bag) => ValidationErrors(bag),
};
```

**Benefits:**
- Compile-time exhaustiveness checking
- Pattern matching with destructuring
- No more `as` casts or missing state handlers
- IDE auto-completes all cases

### Migration Path
1. Make base states `sealed`
2. Convert existing `MyBaseState<StateType>` factory pattern to direct sealed subclasses
3. Replace `BlocBuilder` `if`-chains with `switch` expressions
4. Keep `MyBaseBloc.mapErrorToState()` — it now returns a concrete sealed variant

---

## 🟠 3. Add Repository Layer

### Problem
BLoCs directly call API services via `http().show(...)`. This:
- Mixes data fetching with state management
- Makes testing harder (must mock the full API service)
- Prevents offline data sources, caching at the data layer, or data transformation

### Solution
Introduce a `Repository` abstraction between BLoC and API:

```dart
// Abstract repository
abstract class ProductRepository {
  Future<Product> getById(int id);
  Future<PaginationResponse<Product>> getPage(int page, ProductFilter filter);
  Future<int> save(int id, ProductRequest request);
  Future<void> delete(int id);
}

// Online-only implementation
class ProductRepositoryImpl implements ProductRepository {
  final ProductApiService _api;
  final ExceptionHandler _handler = _ExceptionHandlerImpl();

  ProductRepositoryImpl(this._api);

  @override
  Future<Product> getById(int id) async =>
      (await _handler.handle(_api.show(id: id)))!;

  // ...
}

// Offline-first implementation (future)
class ProductRepositoryOffline implements ProductRepository {
  final ProductApiService _api;
  final ProductDao _dao; // Local database

  @override
  Future<Product> getById(int id) async {
    try {
      final remote = await _api.show(id: id);
      await _dao.upsert(remote.data!);
      return remote.data!;
    } catch (e) {
      return await _dao.getById(id); // Fallback to local
    }
  }
}

// BLoC uses repository, not API directly
class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _repo;

  void show(int id) async {
    try {
      emit(ProductLoading());
      final product = await _repo.getById(id);
      emit(ProductLoaded(product));
    } catch (e) {
      emit(ProductError(message: e.toString()));
    }
  }
}
```

**Migration:** This is additive. Old `MyBaseBloc` → `http()` pattern still works. New features can adopt the repository pattern.

---

## 🟠 4. Cursor-Based Pagination Support

### Problem
`PaginationBloc` only supports offset-based pagination (`page=1,2,3...`). Many modern APIs use cursor-based pagination for:
- Better performance on large datasets
- Consistent results when data changes between pages

### Solution
Make the pagination strategy pluggable:

```dart
abstract class PaginationStrategy<Cursor> {
  Cursor get initialCursor;
  Cursor nextCursor(dynamic responseData);
  bool isComplete(dynamic responseData);
}

class OffsetPagination extends PaginationStrategy<int> {
  @override
  int get initialCursor => 0;

  @override
  int nextCursor(dynamic data) => (data as PaginationResponse).data!.isEmpty
      ? initialCursor
      : initialCursor + 1; // simplified

  @override
  bool isComplete(dynamic data) => (data as PaginationResponse).data!.isEmpty;
}

class CursorPagination extends PaginationStrategy<String?> {
  @override
  String? get initialCursor => null;

  @override
  String? nextCursor(dynamic data) => data['meta']?['next_cursor'];

  @override
  bool isComplete(dynamic data) => data['meta']?['next_cursor'] == null;
}
```

Then `PaginationBloc` becomes strategy-aware:

```dart
mixin PaginationBloc<..., Strategy extends PaginationStrategy> {
  late Strategy strategy;
  // Use strategy.nextCursor() instead of page++
}
```

---

## 🟡 5. Optimistic Updates in `CrudBloc`

### Problem
When updating a resource, the UI shows a loading state until the server responds. This feels slow for simple edits.

### Solution
Add optimistic update support:

```dart
mixin OptimisticCrud<...> on CrudBloc<...> {
  /// Optimistically update the model in memory and UI,
  /// then sync with the server in the background
  void optimisticUpdate({
    required int id,
    required Request request,
    required Model optimisticModel,
  }) {
    // 1. Immediately update UI
    final previousModel = model;
    model = optimisticModel;
    emit(bs.loaded(data: optimisticModel));

    // 2. Sync with server
    save(id: id, request: request).then((_) {
      // Success — nothing to do, UI already updated
    }).catchError((e) {
      // Rollback on failure
      model = previousModel;
      emit(bs.loaded(data: previousModel!));
      emit(bs.error(error: 'Save failed, changes reverted'));
    });
  }
}
```

---

## 🟡 6. Code Generator for BLoC Boilerplate

### Problem
For each new feature, developers must create:
- State class with 7+ subclasses
- Cubit with `CrudBloc` + `PaginationBloc` mixins
- Controller class
- Maker class
- API service

This is ~200 lines of repetitive boilerplate per feature.

### Solution
Create a `build_runner` code generator or a CLI tool:

```bash
dart run caky_gen feature product \
  --model=Product \
  --request=ProductRequest \
  --filter=ProductFilter
```

This generates all the boilerplate files with proper types filled in. The developer only needs to:
1. Define the model fields
2. Define the request fields
3. Implement the form widget's `build()` method

Alternatively, use annotations:

```dart
@CakyFeature(
  model: Product,
  request: ProductRequest,
  filter: ProductFilter,
  endpoint: '/products',
)
class ProductFeature {}
```

---

## 🟡 7. WebSocket Integration for Real-Time Sync

### Problem
`PaginationBloc.lista` is a static in-memory cache. If another user creates/updates/deletes a resource, the current user won't see it until they manually refresh.

### Solution
Add a `RealtimeSync` mixin that listens for server-side events:

```dart
mixin RealtimeSync<Model> {
  StreamSubscription? _subscription;

  void startListening(String channel) {
    _subscription = Core.get<RealtimeClient>().listen(channel, (event) {
      switch (event.type) {
        case 'created':
          _onItemCreated(event.data as Model);
        case 'updated':
          _onItemUpdated(event.data as Model);
        case 'deleted':
          _onItemDeleted(event.data['id'] as int);
      }
    });
  }

  void _onItemCreated(Model item) {
    lista.insert(0, item);
    _emitRefresh();
  }

  void _onItemUpdated(Model item) {
    final index = lista.indexWhere((e) => (e as dynamic).id == (item as dynamic).id);
    if (index != -1) {
      lista[index] = item;
      _emitRefresh();
    }
  }

  void _onItemDeleted(int id) {
    lista.removeWhere((e) => (e as dynamic).id == id);
    _emitRefresh();
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
```

---

## 🟡 8. Improve `BaseMaker` with Attachment Tracking

### Problem
The commented-out `attachments` map in `BaseMaker` shows that file attachment management was planned but never completed. Currently, each Maker must manually manage `FileField` objects.

### Solution
Add first-class attachment support:

```dart
abstract class BaseMaker<TModel, TRequest> {
  final Map<String, FileField> _attachments = {};

  /// Register a file field
  FileField attachment(String key, {FileType type = FileType.IMAGE}) {
    return _attachments.putIfAbsent(key, () => FileField(name: key, type: type));
  }

  /// Get attachment map for upload (filtered: only non-null data)
  Map<String, MultipartFile> get attachmentsMap =>
      Map.fromEntries(
        _attachments.entries
            .where((e) => e.value.formPart() != null)
            .map((e) => e.value.formPart()!),
      );

  /// Check if any attachments were modified
  bool get hasModifiedAttachments =>
      _attachments.values.any((f) => f.data != null || f.shouldBeRemoved);
}
```

Usage:
```dart
class ProductMaker extends BaseMaker<Product, ProductRequest> {
  late final image = attachment('image');
  late final documents = attachment('documents', type: FileType.PDF);
}
```

---

## 🟡 9. Add `DynamicQueryRequest` Convenience Builders

### Problem
Building filters with operators, sorting, and BI parameters requires knowing the raw JSON key names (`_sort[]`, `_operators`, etc.).

### Solution
Add fluent builder methods:

```dart
abstract class DynamicQueryRequest<T> extends SuperModel<T> {
  // Existing fields...

  /// Fluent sorting
  T sortBy(String field, {bool desc = false}) {
    sort ??= [];
    sort!.add(desc ? '-$field' : field);
    return this as T;
  }

  /// Fluent operators
  T where(String field, String operator) {
    operators ??= {};
    operators![field] = operator;
    return this as T;
  }

  /// Fluent field selection
  T selectFields(List<String> f) {
    fields = f;
    return this as T;
  }

  /// BI shortcut
  T metric(String m, {List<String>? groupBy, String? transform}) {
    this.metric = m;
    group = groupBy;
    this.transform = transform;
    return this as T;
  }
}

// Usage
final filter = ProductFilter()
    .sortBy('created_at', desc: true)
    .where('price', '>')
    .selectFields(['id', 'title', 'price']);
```

---

## 🟡 10. Add Form State Preservation

### Problem
If the user navigates away from an edit form and comes back, all input data is lost. The `FormHandler` doesn't save draft state.

### Solution
Add auto-save draft support:

```dart
mixin DraftFormHandler<...> on FormHandler<...> {
  String get draftKey => '${widget.maker.runtimeType}_draft';

  @override
  void initState() {
    super.initState();
    _restoreDraft();
  }

  void _restoreDraft() {
    final draft = Core.get<SharedPrefHelper>().get<Map<String, dynamic>>(draftKey);
    if (draft != null) {
      widget.maker.form = widget.maker.form.fromJson(draft);
      fillForm(); // Update text controllers
    }
  }

  void saveDraft() {
    fillMaker();
    Core.get<SharedPrefHelper>().set<Map<String, dynamic>>(
        draftKey, widget.maker.form.toJson());
  }

  void clearDraft() {
    Core.get<SharedPrefHelper>().remove(draftKey);
  }

  @override
  void dispose() {
    saveDraft();
    super.dispose();
  }
}
```
