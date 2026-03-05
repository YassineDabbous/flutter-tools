import 'package:skeleton/skeleton.dart';

/// Automated CRUD logic that eliminates the need to override standard API calls.
/// 
/// It assumes the [ApiType] follows the [BaseApiService] contract.
mixin AutoCrudBloc<
    ApiType extends BaseApiService<Model, Request, Filter>, 
    BaseState extends CrudState<BaseState, Model, ID>, 
    Model, 
    Request, 
    Filter,
    ID> on CrudBloc<ApiType, BaseState, Model, Request, Filter, ID> {
  
  @override
  Future<Model> one({required ID id, Filter? params}) async =>
      (await handle(http().show(id: id, params: params))).data!;

  @override
  Future<ID> save({required ID id, required Request request}) async {
    // Note: We use a convention where id is null, 0, or empty string for creation.
    // This depends on the ID type used.
    final bool isUpdate = (id != null && id != 0 && id != '');

    return (await (isUpdate 
        ? handle(http().update(id: id, request: request)) 
        : handle(http().create(request)))).data!;
  }

  @override
  Future destroy({required ID id, Filter? params}) async =>
      (await handle(http().delete(id: id, params: params))).data;
}

/// Automated Pagination logic.
mixin AutoPaginationBloc<
    ApiType extends BaseApiService<Model, dynamic, Filter, dynamic>, 
    BaseState extends PaginationState<BaseState, Model>, 
    Model, 
    Filter> on PaginationBloc<ApiType, BaseState, Model, Filter> {
  
  @override
  Future<PaginatedResponse<Model>> load() async =>
      (await handle(http().paging(page: page, request: filter))).data!;

  @override
  Future<List<Model>> loadAll() async =>
      (await handle(http().all(request: filter))).data ?? [];
}
