import 'package:flutter/widgets.dart';
import 'package:skeleton/skeleton.dart';

//
//
// States
//
//
//

/// Common CRUD states
mixin CrudState<StateType, Model, ID> on MyBaseState<StateType> {
  /// Helper returns the runtime Type for `Loading` state
  Type get loadingType => StateType;

  /// Helper returns the runtime Type for `Loaded` state
  Type get loadedType => StateType;

  /// creates a Loading state
  StateType get loading;

  /// creates a Successful `Loaded` state
  ///
  /// @param data The data model
  StateType loaded({required Model data});

  /// creates a Loading state
  StateType get saving;

  /// creates a Successful `Saved` state
  ///
  /// @param id The saved resource ID
  StateType saved({required ID id});

  /// creates a Deleting state
  StateType get deleting;

  /// creates a Successful `Deleted` state
  ///
  /// @param id The deleted resource ID
  StateType deleted({required ID id});
}

//
//
// Bloc/Cubit
//
//
//

mixin CrudCubit<
  ApiType extends BaseApiService<Model, Request, Filter, ID>,
  BaseState extends CrudState<BaseState, Model, ID>,
  Model,
  Request,
  Filter,
  ID
>
    on MyBaseCubit<ApiType, BaseState> {
  Model? model;

  /// Make a http call to get `Model` data.
  ///
  /// @param id The resource ID
  /// @param params Additional fields
  @protected
  Future<Model> one({required ID id, Filter? params});

  /// This is the method that will be called from widgets to emit `loading` state, gets the requested resource and emit the `loaded` state
  void show({required ID id, Filter? params}) async {
    try {
      emit(bs.loading);
      final data = await one(id: id, params: params);
      model = data;
      emit(bs.loaded(data: data));
    } catch (e) {
      emit(mapErrorToState(e));
    }
  }

  /// Same as `one` method but for `Create/Edit` Forms
  @protected
  Future<Model> oneForEdit({required ID id, Filter? params}) async =>
      await one(id: id, params: params);

  /// Same as `show` method but for `Create/Edit` Forms
  void showForEdit({required ID id, Filter? params}) async {
    try {
      emit(bs.loading);
      final data = await oneForEdit(id: id, params: params);
      model = data;
      emit(bs.loaded(data: data));
    } catch (e) {
      emit(mapErrorToState(e));
    }
  }

  /// Submit data to API.
  ///
  /// @param id The resource ID
  /// @param request The request body
  @protected
  Future<ID> save({required ID id, required Request request});

  /// This is the method that will be called from widgets to update or create resources
  void updateOrCreate({required ID id, required Request request}) async {
    try {
      emit(bs.saving);
      final data = await save(id: id, request: request);
      emit(bs.saved(id: data));
    } catch (e) {
      emit(mapErrorToState(e));
    }
  }

  /// Calls the API/Repository to delete the specified data resource
  ///
  /// @param id The resource ID
  /// @param params Additional fields
  @protected
  Future destroy({required ID id, Filter? params});

  /// This is the method that will be called from widgets to delete resources by id
  ///
  /// @param id The resource ID
  /// @param params Additional fields
  void delete(ID id, {Filter? params}) async {
    try {
      emit(bs.deleting);
      (await destroy(id: id, params: params));
      emit(bs.deleted(id: id));
    } catch (e) {
      emit(mapErrorToState(e));
    }
  }
}
