import 'package:skeleton/skeleton.dart';
import 'laravel_api_service.dart';

/// Mixin to simplify PaginationBloc implementation for Laravel providers.
mixin LaravelPaginationBloc<
  ApiType extends LaravelApiService<Model, dynamic, SearchRequest, ID>,
  BaseState extends PaginationState<BaseState, Model>,
  Model,
  SearchRequest,
  ID
>
    on PaginationBloc<ApiType, BaseState, Model, SearchRequest> {
  @override
  Future<PaginatedResponse<Model>> load() async {
    return (await http().paging(page: page, request: filter)).data!;
  }
}
