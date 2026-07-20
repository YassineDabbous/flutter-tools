import 'package:skeleton/skeleton.dart';

/// Automated CRUD logic that eliminates the need to override standard API calls.
///
/// It assumes the [ApiType] follows the [BaseApiService] contract.
mixin AutoCrudCubit<
  ApiType extends BaseApiService<Model, Request, Filter, ID>,
  BaseState extends CrudState<BaseState, Model, ID>,
  Model,
  Request,
  Filter,
  ID
>
    on CrudCubit<ApiType, BaseState, Model, Request, Filter, ID> {
  @override
  Future<Model> one({required ID id, Filter? params}) async =>
      (await handle(http().show(id: id, params: params))).data!;

  @override
  Future<ID> save({required ID id, required Request request}) async {
    // Note: We use a convention where id is null, 0, or empty string for creation.
    // This depends on the ID type used.
    final bool isUpdate = (id != null && id != 0 && id != '');

    return (await (isUpdate
            ? handle(http().update(id: id, body: request))
            : handle(http().create(body: request))))
        .data!;
  }

  @override
  Future destroy({required ID id, Filter? params}) async =>
      (await handle(http().delete(id: id, params: params))).data;
}

/// Automated Pagination logic.
mixin AutoPaginationCubit<
  ApiType extends BaseApiService<Model, dynamic, Filter, dynamic>,
  BaseState extends PaginationState<BaseState, Model>,
  Model,
  Filter
>
    on PaginationCubit<ApiType, BaseState, Model, Filter> {
  @override
  Future<PaginatedList<Model>> load() async =>
      (await handle(http().paging(page: page, params: filter))).data!;

  @override
  Future<List<Model>> loadAll() async =>
      (await handle(http().all(params: filter))).data ?? [];
}
