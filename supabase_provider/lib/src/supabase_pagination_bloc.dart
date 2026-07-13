import 'package:skeleton/skeleton.dart';
import 'supabase_api_service.dart';

/// Mixin for Supabase-specific pagination (range-based).
mixin SupabasePaginationBloc<
  ApiType extends SupabaseApiService<Model, dynamic, SearchFilter, ID>,
  BaseState extends PaginationState<BaseState, Model>,
  Model,
  SearchFilter,
  ID
>
    on
        PaginationBloc<ApiType, BaseState, Model, SearchFilter>,
        RealtimeMixin<ApiType, BaseState, Model, SearchFilter> {
  @override
  Future<PaginatedList<Model>> load() async {
    // Current page is 1-indexed in skeleton, Supabase uses 0-indexed range
    return (await http().paging(page: page, params: filter)).data!;
  }
}

/// A generic paginated response implementation for Supabase.
class SupabasePaginatedList<T> implements PaginatedList<T> {
  @override
  final List<T> data;
  @override
  final int total;
  @override
  final int perPage;
  @override
  final int currentPage;

  SupabasePaginatedList({
    required this.data,
    required this.total,
    required this.perPage,
    required this.currentPage,
  });

  @override
  int get lastPage => (total / perPage).ceil();
}
