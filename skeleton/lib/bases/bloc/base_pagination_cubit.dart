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
  StateType pageLoaded({required List<Model> data, required bool maxReached, required int nextPage});
}

//
//
// Bloc/Cubit
//
//

mixin PaginationBloc<ApiType extends BaseApiService<dynamic, dynamic, dynamic, dynamic>, BaseState extends PaginationState<BaseState, Model>, Model, SearchFilter>
    on MyBaseBloc<ApiType, BaseState> {
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

  /// Generate page numbers from `total` and `total`.
  List<int> get pages => total == null || perPage == null || perPage == 0 ? [] : List.generate((total! / perPage!).ceil(), (index) => index).map((e) => e + 1).toList();

  /// Initialize default values
  @override
  init() {
    filter = defaultFilter();
    super.init();
  }

  /// Creates a default filter instance
  SearchFilter defaultFilter();

  /// Load the specified page
  Future loadPage(int p) async => offlinePaging ? await moveOffline(toPage: p) : await move(toPage: p);

  /// Load the next page
  Future loadNext() async => offlinePaging ? await moveOffline() : await move();

  /// Load the previous page
  Future loadPrevious() async => offlinePaging ? await moveOffline(back: true) : await move(back: true);

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
    int aux = page;
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
      // if (forAdmin) {
      //   lista.clear(); // DON'T CLEAR loaded resources on offline mode
      // }
      // lista.addAll(l);
      maxReached = l.isEmpty;
      emit(bs.pageLoaded(data: l, maxReached: maxReached, nextPage: page));
    } catch (e) {
      if (toPage != null) {
        page = aux;
      } else {
        back ? page++ : page--;
      }
      emit(mapErrorToState(e));
    }
  }

  /// Move to a specified page or loading next/previous page
  @protected
  Future move({bool back = false, int? toPage}) async {
    int aux = page;
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
      total = p.total ?? total;
      perPage = p.perPage ?? perPage;
      final l = p.data!;
      if (forAdmin) {
        lista.clear();
      }
      lista.addAll(l);
      maxReached = l.isEmpty;
      emit(bs.pageLoaded(data: l, maxReached: maxReached, nextPage: page));
    } catch (e) {
      if (toPage != null) {
        page = aux;
      } else {
        back ? page++ : page--;
      }
      emit(mapErrorToState(e));
    }
  }

  // Reset and Get the first resources page
  @mustCallSuper
  Future refresh({SearchFilter? filter}) async {
    lista.clear();
    page = 0;
    maxReached = false;
    this.filter = filter ?? this.filter;
    emit(bs.initial);
    await loadNext();
  }

  // Refresh the current resources page.
  Future refreshPage() async {
    emit(bs.pageLoading);
    try {
      final l = await load();
      emit(bs.pageLoaded(data: l.data!, maxReached: maxReached, nextPage: page));
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
}
