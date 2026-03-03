import 'package:flutter/widgets.dart';
import 'package:skeleton/skeleton.dart';

//
//
// States
//
//

/// Common CRUD states
mixin CrudState<StateType, Model> on MyBaseState<StateType> {
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
  StateType saved({required int id});

  /// creates a Deleting state
  StateType get deleting;

  /// creates a Successful `Deleted` state
  ///
  /// @param id The deleted resource ID
  StateType deleted({required int id});
}

//
//
// Bloc/Cubit
//
//

mixin CrudBloc<ApiType extends BaseApiService<dynamic, dynamic, dynamic>, BaseState extends CrudState<BaseState, Model>, Model, Request, Filter> on MyBaseBloc<ApiType, BaseState> {
  Model? model;

  /// Make a http call to get `Model` data.
  ///
  /// @param id The resource ID
  /// @param params Additional fields
  @protected
  Future<Model> one({required int id, Filter? params}); // async => (await handle(http().show(id)))!;

  /// This is the method that will be called from widgets to emit `loading` state, gets the requested resource and emit the `loaded` state
  void show({required int id, Filter? params}) async {
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
  Future<Model> oneForEdit({required int id, Filter? params}) async => await one(id: id, params: params);

  /// Same as `show` method but for `Create/Edit` Forms
  void showForEdit({required int id, Filter? params}) async {
    try {
      emit(bs.loading);
      final data = await oneForEdit(id: id, params: params);
      model = data;
      emit(bs.loaded(data: data));
    } catch (e) {
      emit(mapErrorToState(e));
    }
  }

  /// Submit data to API. On creation: ID == 0
  ///
  /// @param id The resource ID
  /// @param request The request body
  @protected
  Future<int> save({required int id, required Request request}); // async => (await (id != 0 ? handle(http().update(id, request)) : handle(http().create(request))))!;

  /// This is the method that will be called from widgets to update or create resources
  void updateOrCreate({required int id, required Request request}) async {
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
  Future destroy({required int id, Filter? params}); // async => (await handle(http().delete(id)))!;

  /// This is the method that will be called from widgets to delete resources by id
  ///
  /// @param id The resource ID
  /// @param params Additional fields
  void delete(int id, {Filter? params}) async {
    try {
      emit(bs.deleting);
      (await destroy(id: id, params: params));
      emit(bs.deleted(id: id));
    } catch (e) {
      emit(mapErrorToState(e));
    }
  }
}
