import 'package:skeleton/skeleton.dart';

/// Automated CRUD logic that eliminates the need to override standard API calls.
/// 
/// It assumes the [ApiType] follows the [BaseApiService] contract.
mixin AutoCrudBloc<
    ApiType extends BaseApiService<Model, Request, Filter>, 
    BaseState extends CrudState<BaseState, Model>, 
    Model, 
    Request, 
    Filter> on CrudBloc<ApiType, BaseState, Model, Request, Filter> {
  
  @override
  Future<Model> one({required int id, Filter? params}) async =>
      (await handle(http().show(id: id, params: params)))!;

  @override
  Future<int> save({required int id, required Request request}) async =>
      (await (id != 0 
          ? handle(http().update(id: id, request: request)) 
          : handle(http().create(request))))!;

  @override
  Future destroy({required int id, Filter? params}) async =>
      await handle(http().delete(id: id));
}

/// Automated Pagination logic.
mixin AutoPaginationBloc<
    ApiType extends BaseApiService<Model, dynamic, Filter>, 
    BaseState extends PaginationState<BaseState, Model>, 
    Model, 
    Filter> on PaginationBloc<ApiType, BaseState, Model, Filter> {
  
  @override
  Future<PaginationResponse<Model>> load() async =>
      (await handle(http().paging(page: page, request: filter)))!;

  @override
  Future<List<Model>> loadAll() async =>
      (await handle(http().all(request: filter))) ?? [];
}
