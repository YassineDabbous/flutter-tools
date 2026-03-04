import 'package:skeleton/skeleton.dart';

/// Mixin for optimistic UI updates in CRUD operations.
mixin OptimisticCrud<
    ApiType extends BaseApiService<Model, Request, Filter>, 
    BaseState extends CrudState<BaseState, Model>, 
    Model extends Identifiable, 
    Request, 
    Filter> on CrudBloc<ApiType, BaseState, Model, Request, Filter> {

  /// Executes a delete operation optimistically.
  void deleteOptimistic(int id, {Filter? params}) async {
    final previousModel = model;
    try {
      // Emit 'deleted' state immediately if we have a way to reflect this in UI
      // For single resource Cubits, this usually means moving to a specific state.
      emit(bs.deleted(id: id));
      await destroy(id: id, params: params);
    } catch (e) {
      // Rollback on failure
      if (previousModel != null) {
        emit(bs.loaded(data: previousModel));
      } else {
        emit(bs.initial);
      }
      emit(mapErrorToState(e));
    }
  }

  /// Executes an update operation optimistically.
  /// Requires a way to transform the [Request] back into a [Model].
  void updateOptimistic({
    required int id, 
    required Request request,
    required Model Function(Model current, Request request) applyChanges,
  }) async {
    final previousModel = model;
    if (previousModel == null) {
      updateOrCreate(id: id, request: request);
      return;
    }

    try {
      final optimisticModel = applyChanges(previousModel, request);
      emit(bs.loaded(data: optimisticModel));
      await save(id: id, request: request);
      emit(bs.saved(id: id));
    } catch (e) {
      // Rollback
      emit(bs.loaded(data: previousModel));
      emit(mapErrorToState(e));
    }
  }
}
