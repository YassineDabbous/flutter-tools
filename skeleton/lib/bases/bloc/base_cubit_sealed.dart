import 'package:flutter/widgets.dart';

// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------
// --------------------------------------- SEALED ----------------------------------------
// ---------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------

//
//
// CAN BE USED WITHIN BLoCs
//
//

mixin SealedPagingCubit<Base, Initial, Loading, Loaded, Error> {
  Widget builder({
    required Base state,
    required Widget Function(Initial) initial,
    required Widget Function(Loading) loading,
    required Widget Function(Loaded) loaded,
    required Widget Function(Error) error,
  }) {
    if (state is Initial) {
      initial(state);
    }
    if (state is Loading) {
      loading(state);
    }
    if (state is Loaded) {
      loaded(state);
    }
    return error(state as Error);
  }
}
//
//
// CAN BE USED WITHIN STATES
//
//
mixin SealedPagingState<Initial, Loading, Loaded, Error> {
  Widget builder({
    required Widget Function(Initial) initial,
    required Widget Function(Loading) loading,
    required Widget Function(Loaded) loaded,
    required Widget Function(Error) error,
  }) {
    if (this is Initial) {
      return initial(this as Initial);
    }
    if (this is Loading) {
      return loading(this as Loading);
    }
    if (this is Loaded) {
      return loaded(this as Loaded);
    }
    return error(this as Error);
  }
}
