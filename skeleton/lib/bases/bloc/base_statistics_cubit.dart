import 'package:flutter/widgets.dart';
import 'package:skeleton/skeleton.dart';

//
//
// States
//
//

/// Common STATISTICS states
mixin StatisticsState<StateType> on MyBaseState<StateType> {
  /// Helper returns the runtime Type for `Loading` state
  Type get loadingType => StateType;

  /// Helper returns the runtime Type for `Loaded` state
  Type get loadedType => StateType;

  /// creates a Loading state
  StateType get statisticsLoading;

  /// creates a Successful `Loaded` state
  StateType statisticsLoaded({required StatisticsResponse data});
}

//
//
// Bloc/Cubit
//
//

mixin StatisticsBloc<
    ApiType extends BaseApiService<dynamic, dynamic, dynamic>,
    BaseState extends StatisticsState<BaseState>,
    Filter
  > on MyBaseBloc<ApiType, BaseState> {
  StatisticsResponse? statistics;

  /// Make a http call to get `StatisticsResponse` data.
  ///
  /// @param id The resource ID
  /// @param params Additional fields
  @protected
  Future<StatisticsResponse> loadStatistics({required Filter params, String? path}); // async => (await handle(http().show(id)))!;

  /// This is the method that will be called from widgets to emit `loading` state, gets the requested resource and emit the `loaded` state
  void getStatistics({required Filter params, String? path}) async {
    try {
      emit(bs.statisticsLoading);
      final data = await loadStatistics(params: params, path: path);
      statistics = data;
      emit(bs.statisticsLoaded(data: data));
    } catch (e) {
      emit(mapErrorToState(e));
    }
  }
}
