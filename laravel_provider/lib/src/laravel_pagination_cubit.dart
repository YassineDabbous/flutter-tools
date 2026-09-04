import 'package:skeleton/skeleton.dart';
import 'laravel_api_service.dart';

/// Mixin to simplify PaginationCubit implementation for Laravel providers.
mixin LaravelPaginationBloc<
  ApiType extends LaravelApiService<Model, ID>,
  BaseState extends PaginationState<BaseState, Model>,
  Model,
  ID
>
    on PaginationCubit<ApiType, BaseState, Model, Map<String, dynamic>> {
  @override
  Future<PaginatedList<Model>> load() async {
    return (await http().paging(page: page, params: filter)).data!;
  }
}
