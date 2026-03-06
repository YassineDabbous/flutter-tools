# New Feature Ideas

Features that would expand the SDK's capabilities without breaking existing APIs.

---

## 1. Local Caching Layer

**Problem:** Every `show()` and `paging()` call hits the network. There's no caching mechanism, which means:
- Navigating back-and-forth between list and detail views re-fetches data each time
- There's no offline-first capability beyond the interceptor queue

**Suggestion:** Add a `CachingApiService` decorator that wraps any `BaseApiService`:

```dart
class CachingApiService<M, E, S, ID> implements BaseApiService<M, E, S, ID> {
  final BaseApiService<M, E, S, ID> _remote;
  final Cache _cache;
  final Duration ttl;

  CachingApiService(this._remote, this._cache, {this.ttl = const Duration(minutes: 5)});

  @override
  Future<ApiResponse<M>> show({required ID id, S? params}) async {
    final cached = _cache.get<M>('${M.runtimeType}:$id');
    if (cached != null) return ApiResponse(data: cached);
    
    final result = await _remote.show(id: id, params: params);
    if (result.data != null) _cache.put('${M.runtimeType}:$id', result.data!, ttl);
    return result;
  }
}
```

This follows the decorator pattern and requires zero changes to existing code.

---

## 2. Debounced Search in `PaginationBloc`

**Problem:** When a user types in a filter/search field, `refresh()` is called on every keystroke, flooding the API with requests.

**Suggestion:** Add a built-in debounce mechanism:

```dart
mixin DebouncedSearchBloc<...> on PaginationBloc<...> {
  Timer? _debounceTimer;
  Duration debounceDuration = const Duration(milliseconds: 500);

  void search(SearchFilter filter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () => refresh(filter: filter));
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
```

---

## 3. Auto-Dispose BLoC Provider

**Problem:** The `ControlledState.dispose()` closes BLoCs unconditionally (see architecture.md #1). But there's also no easy way to create "scoped" BLoCs that auto-dispose correctly.

**Suggestion:** Add a `ScopedBlocProvider` widget that creates and owns a BLoC:

```dart
class ScopedBlocProvider<T extends Cubit> extends StatefulWidget {
  final T Function() create;
  final Widget child;
  
  @override
  State<ScopedBlocProvider<T>> createState() => _ScopedBlocProviderState<T>();
}

class _ScopedBlocProviderState<T extends Cubit> extends State<ScopedBlocProvider<T>> {
  late final T _bloc = widget.create();

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(value: _bloc, child: widget.child);
}
```

---

## 4. Batch CRUD Operations on `PaginationBloc`

**Problem:** `PaginationBloc` manages an in-memory `lista` but has no methods for local list manipulation (optimistic add, remove, reorder).

**Suggestion:** Add local list management methods:

```dart
mixin ListManagement<Model extends Identifiable> {
  /// Remove an item from the local list by ID
  void removeLocal(dynamic id) {
    lista.removeWhere((item) => item.id == id);
    _emitCurrentPage();
  }

  /// Add an item to the beginning of the local list
  void prependLocal(Model item) {
    lista.insert(0, item);
    _emitCurrentPage();
  }

  /// Update an item in the local list
  void updateLocal(Model item) {
    final index = lista.indexWhere((e) => e.id == item.id);
    if (index >= 0) {
      lista[index] = item;
      _emitCurrentPage();
    }
  }
}
```

---

## 5. Form Attachment Upload Progress

**Problem:** `BaseMaker` has an `_attachments` map for file uploads, but there's no way to track upload progress. For large files (photos, documents), users see no progress indicator.

**Suggestion:** Add an upload progress callback:

```dart
abstract class BaseMaker<TModel, TRequest, ID> {
  // existing...
  
  /// Stream of upload progress events
  final StreamController<UploadProgress> _uploadProgress = StreamController.broadcast();
  Stream<UploadProgress> get uploadProgress => _uploadProgress.stream;
  
  void reportProgress(String key, double progress) {
    _uploadProgress.add(UploadProgress(key: key, progress: progress));
  }
}

class UploadProgress {
  final String key;
  final double progress; // 0.0 to 1.0
  UploadProgress({required this.key, required this.progress});
}
```

Dio already supports `onSendProgress` — just wire it through `superRequestTransform`.

---

## 6. Typed Action System

**Problem:** `BaseAction` payload is `Map<String, dynamic>` with untyped `set(key, value)` / `get(key)`. There's no type safety or documentation of what fields an action expects.

**Suggestion:** Use typed actions:

```dart
abstract class TypedAction<TPayload extends Jsonable> extends BaseAction {
  TPayload payload;
  
  @override
  ActionRequest request() {
    final base = super.request();
    base.payload = payload.toJson();
    return base;
  }
}

// Usage:
class AssignDriverAction extends TypedAction<AssignDriverPayload> {
  AssignDriverAction({required super.controller, required this.driverId})
    : super(route: 'assign-driver'),
      payload = AssignDriverPayload(driverId: driverId);
}

class AssignDriverPayload extends Jsonable {
  final int driverId;
  @override Map<String, dynamic> toJson() => {'driver_id': driverId};
}
```

---

## 7. Multi-Provider Support

**Problem:** A single app can only use one backend provider at a time. There's no built-in way to mix Laravel and Supabase in the same project (e.g., main API on Laravel but real-time/auth on Supabase).

**Suggestion:** Allow provider-specific DI keys:

```dart
// Register both
Core.i.addSingleton<AuthLocalManager>(() => SupabaseAuthBridge(supabase), key: 'supabase');
Core.i.addSingleton<ProductApiService>(() => ProductLaravelService(dio), key: 'laravel');

// Or use named types
Core.i.addSingleton<ProductApiService>(() => ProductLaravelService(dio));
Core.i.addSingleton<ChatApiService>(() => ChatSupabaseService(supabase));
```

The DI key system already exists in `Injector` — just needs documentation and patterns.

---

## 8. Export / Import Feature for `BaseController` Filters

**Problem:** Filters set via `BaseController` are in-memory only. If the user navigates away and comes back, filters are lost. There's also no way to share a filtered view via URL.

**Suggestion:**

```dart
extension FilterPersistence<T extends SuperModel<T>> on BaseController<T, dynamic, dynamic> {
  /// Serialize current filter to URL query string
  String toQueryString() {
    return request.toJson()
      .entries
      .where((e) => e.value != null)
      .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
      .join('&');
  }

  /// Restore filter from URL query string
  void fromQueryString(String query) {
    final params = Uri.splitQueryString(query);
    fillFromQuery(params);
  }

  /// Persist filter to local storage
  Future<void> saveFilter(String key) async {
    final prefs = Core.get<SharedPrefHelper>();
    await prefs.set<String>('filter_$key', jsonEncode(request.toJson()));
  }

  /// Restore filter from local storage
  Future<void> loadFilter(String key) async {
    final prefs = Core.get<SharedPrefHelper>();
    final json = prefs.get<String>('filter_$key');
    if (json != null) fillFromJson(jsonDecode(json));
  }
}
```

---

## 9. Event Bus / Cross-Cubit Communication

**Problem:** When a resource is created/updated/deleted in one cubit, other cubits displaying the same resource type don't know about it. For example, deleting a product in `ProductCubit` doesn't auto-refresh `ProductListCubit`.

**Suggestion:** Lightweight event bus:

```dart
class CrudEvent<T> {
  final CrudEventType type;
  final dynamic id;
  final T? data;
  CrudEvent({required this.type, this.id, this.data});
}

enum CrudEventType { created, updated, deleted }

// In CrudBloc:
void updateOrCreate(...) async {
  // ... existing logic ...
  emit(bs.saved(id: data));
  CrudEventBus.fire(CrudEvent<Model>(type: CrudEventType.created, id: data));
}

// In PaginationBloc:
mixin AutoRefreshOnCrud<Model> {
  @override
  void init() {
    CrudEventBus.on<Model>().listen((event) => refresh());
    super.init();
  }
}
```
