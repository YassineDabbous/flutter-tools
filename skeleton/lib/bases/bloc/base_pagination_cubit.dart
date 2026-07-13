import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:skeleton/skeleton.dart';

//
//
// States
//
//

/// Adds data paging states
mixin PaginationState<StateType, Model> on MyBaseState<StateType> {
  /// creates a `PageLoading` state
  StateType get pageLoading;

  /// creates a Successful `PageLoaded` state
  StateType pageLoaded({
    required List<Model> data,
    required bool maxReached,
    required int nextPage,
  });
}

//
//
// Bloc/Cubit
//
//

enum PagingMode {
  /// Appends new pages to the existing list (Standard for Mobile feeds)
  infiniteScroll,

  /// Replaces the current page (Standard for Admin Tables)
  paginated,
}

mixin PaginationBloc<
  ApiType extends BaseApiService<dynamic, dynamic, dynamic, dynamic>,
  BaseState extends PaginationState<BaseState, Model>,
  Model,
  SearchFilter
>
    on MyBaseBloc<ApiType, BaseState> {
  /// Timer for debouncing search/refresh calls
  Timer? _debounceTimer;

  /// In-memory cache for loaded results
  List<Model> lista = [];

  /// The search request filter
  late SearchFilter filter;

  int? total;

  int? perPage;

  /// current page
  int page = 0;

  /// max results reached
  bool maxReached = false;

  /// Paging the previously loaded results
  bool offlinePaging = false;

  /// Guard to prevent concurrent paging requests
  bool _isMoving = false;

  /// How to handle new data pages.
  PagingMode pagingMode = PagingMode.paginated;

  /// Generate page numbers from `total` and `total`.
  List<int> get pages => total == null || perPage == null || perPage == 0
      ? []
      : List.generate(
          (total! / perPage!).ceil(),
          (index) => index,
        ).map((e) => e + 1).toList();

  /// Initialize default values
  @override
  init() {
    filter = defaultFilter();
    super.init();
  }

  /// Creates a default filter instance
  SearchFilter defaultFilter();

  /// Load the specified page
  Future loadPage(int p) async =>
      offlinePaging ? await moveOffline(toPage: p) : await move(toPage: p);

  /// Load the next page
  Future loadNext() async => offlinePaging ? await moveOffline() : await move();

  /// Load the previous page
  Future loadPrevious() async =>
      offlinePaging ? await moveOffline(back: true) : await move(back: true);

  Future loadPageOffline(int p) async => await moveOffline(toPage: p);
  Future loadNextOffline() async => await moveOffline();
  Future loadPreviousOffline() async => await moveOffline(back: true);
  @protected
  List<Model> _loadOffline() {
    total = lista.length;
    perPage ??= 50;
    var start = page < 2 ? 0 : ((page - 1) * perPage! + 1);
    start = start == 0 ? start : start - 1;
    final end = (total! - start) > perPage! ? (start + perPage!) : (total!);
    return lista.getRange(start, end).toList();
  }

  @protected
  Future moveOffline({bool back = false, int? toPage}) async {
    if (_isMoving) return;
    int aux = page;
    _isMoving = true;
    try {
      if (toPage != null) {
        page = toPage;
      } else {
        back ? page-- : page++;
      }
      if (page < 1) {
        page = 1;
      }
      emit(bs.pageLoading);

      final l = _loadOffline();
      maxReached = l.isEmpty;
      emit(bs.pageLoaded(data: l, maxReached: maxReached, nextPage: page));
    } catch (e) {
      if (toPage != null) {
        page = aux;
      } else {
        back ? page++ : page--;
      }
      emit(mapErrorToState(e));
    } finally {
      _isMoving = false;
    }
  }

  /// Move to a specified page or loading next/previous page
  @protected
  Future move({bool back = false, int? toPage}) async {
    if (_isMoving) return;
    int aux = page;
    _isMoving = true;
    try {
      if (toPage != null) {
        page = toPage;
      } else {
        back ? page-- : page++;
      }
      if (page < 1) {
        page = 1;
      }
      emit(bs.pageLoading);
      final p = await load();
      total = p.total;
      perPage = p.perPage;
      final l = p.data;
      if (pagingMode == PagingMode.paginated) {
        lista.clear();
        lista.addAll(l);
      } else {
        // Prevent duplicates in infinite scroll
        final existingIds = lista.map((e) {
          if (e is Identifiable) return e.id;
          try {
            return (e as dynamic).id;
          } catch (_) {
            return e.hashCode;
          }
        }).toSet();

        for (final item in l) {
          final dynamic id = item is Identifiable
              ? item.id
              : (item as dynamic).id;
          if (!existingIds.contains(id)) {
            lista.add(item);
          }
        }
      }
      maxReached = l.isEmpty;
      emit(bs.pageLoaded(data: l, maxReached: maxReached, nextPage: page));
    } catch (e) {
      if (toPage != null) {
        page = aux;
      } else {
        back ? page++ : page--;
      }
      emit(mapErrorToState(e));
    } finally {
      _isMoving = false;
    }
  }

  // Reset and Get the first resources page
  @mustCallSuper
  Future refresh({SearchFilter? filter}) async {
    _debounceTimer?.cancel();
    lista.clear();
    page = 0;
    maxReached = false;
    this.filter = filter ?? this.filter;
    emit(bs.initial);
    await loadNext();
  }

  /// Debounced version of [refresh].
  /// Useful for search fields to avoid hitting the API on every keystroke.
  void debouncedRefresh({
    SearchFilter? filter,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, () => refresh(filter: filter));
  }

  // --- Local List Management (Optimistic UI) ---

  /// Emits the current state with the updated [lista].
  void _emitCurrentPage() {
    emit(
      bs.pageLoaded(
        data: List.of(lista),
        maxReached: maxReached,
        nextPage: page,
      ),
    );
  }

  /// Remove an item from the local list by its ID.
  /// Note: The [Model] must implement [Identifiable] or have an 'id' property.
  void removeLocal(dynamic id) {
    lista.removeWhere((item) {
      if (item is Identifiable) return item.id == id;
      try {
        return (item as dynamic).id == id;
      } catch (_) {
        return false;
      }
    });
    _emitCurrentPage();
  }

  /// Add an item to the beginning of the local list.
  void prependLocal(Model item) {
    lista.insert(0, item);
    _emitCurrentPage();
  }

  /// Update an item in the local list if it exists.
  void updateLocal(Model item) {
    final dynamic id = item is Identifiable ? item.id : (item as dynamic).id;
    final index = lista.indexWhere((e) {
      if (e is Identifiable) return e.id == id;
      try {
        return (e as dynamic).id == id;
      } catch (_) {
        return false;
      }
    });
    if (index >= 0) {
      lista[index] = item;
      _emitCurrentPage();
    }
  }

  // Refresh the current resources page.
  Future refreshPage() async {
    emit(bs.pageLoading);
    try {
      final l = await load();
      emit(bs.pageLoaded(data: l.data, maxReached: maxReached, nextPage: page));
    } catch (e) {
      emit(mapErrorToState(e));
    }
  }

  // Reset and get all resources
  @mustCallSuper
  Future refreshAll({SearchFilter? filter}) async {
    lista.clear();
    page = 0;
    maxReached = false;
    this.filter = filter ?? this.filter;
    emit(bs.initial);
    await getAll();
  }

  /// Get all resources
  Future<bool> getAll() async {
    try {
      emit(bs.pageLoading);
      final l = await loadAll();
      lista.addAll(l);
      if (offlinePaging) {
        perPage = null;
        moveOffline(toPage: 1);
        return true;
      }
      emit(bs.pageLoaded(data: lista, maxReached: true, nextPage: page));
      return true;
    } catch (e) {
      emit(mapErrorToState(e));
      return false;
    }
  }

  /// Call the API/Repository for resources paging.
  @protected
  Future<PaginatedResponse<Model>> load();

  /// Load all results at once
  /// Call the API/Repository to get all resources at once.
  @protected
  Future<List<Model>> loadAll() {
    throw UnimplementedError();
  } // async => (await handle(http().all(request: filter))) ?? [];

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}

/// Mixin for [PaginationBloc] to support live data streams.
mixin RealtimeMixin<
  ApiType extends BaseApiService<dynamic, dynamic, dynamic, dynamic>,
  BaseState extends PaginationState<BaseState, Model>,
  Model,
  SearchFilter
>
    on PaginationBloc<ApiType, BaseState, Model, SearchFilter> {
  StreamSubscription? _realtimeSubscription;

  /// Starts listening to the live stream for the current filter.
  void startRealtime() {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = http().stream(data: filter).listen((items) {
      _handleRealtimeUpdate(List<Model>.from(items));
    });
  }

  void _handleRealtimeUpdate(List<Model> items) {
    // Basic logic: if pagingMode is infiniteScroll, we might want to
    // merge new items. If it's paginated, we might just refresh.
    // For now, let's just update 'lista' optimistically.
    for (final item in items) {
      updateLocal(item);
    }
  }

  @override
  Future<void> close() {
    _realtimeSubscription?.cancel();
    return super.close();
  }
}
