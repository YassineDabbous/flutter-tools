import 'package:flutter/widgets.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:core/core.dart';
import 'package:skeleton/skeleton.dart';

//
//
// States
//
//

abstract class MyBaseState<StateType> extends Equatable {
  @override
  List<Object> get props => [];
  StateType get initial;

  /// creates a general Error state
  StateType error({required String error, int code = 0});

  /// creates an Authorization Error state
  StateType unauthorized({required String message, int code = 0}) => error(error: message, code: code);

  /// creates a Validation Error state
  ///
  /// @param bag Contains form validation messages
  StateType validation(Map<String, dynamic> bag);
}

//
//
// Bloc/Cubit
//
//

abstract class MyBaseBloc<ApiType extends BaseApiService, BaseState extends MyBaseState> extends Cubit<BaseState> with ExceptionHandler {
  /// API instance (usualy a Retrofit interface instance)
  ApiType? api;

  /// The base state, use as a factor for other states
  BaseState bs;

  /// True when targeting the Admin API
  bool forAdmin;

  MyBaseBloc({required this.bs, this.forAdmin = false}) : super(bs.initial) {
    init();
  }

  /// Initialize any required instance
  void init() {}

  /// returns the API instance
  ApiType http() {
    if (api != null) {
      return api!;
    }
    return api = apiInstance();
  }

  /// Creates an API instance
  ApiType apiInstance() => Core.get<ApiType>();

  @protected
  BaseState mapErrorToState(dynamic e) => _mapErrorToState(e);

  /// Transform and Error/Exception to a bloc state
  BaseState _mapErrorToState(dynamic e) {
    if (e is AuthException) {
      onAuthError();
      return bs.error(error: e.message);
    } else if (e is ValidationException) {
      return bs.validation(e.bag);
    } else if (e is PermissionException) {
      return bs.unauthorized(message: e.message, code: e.code);
    } else if (e is ExceptionWithMessage) {
      return bs.error(error: e.message, code: e.code);
    }
    logNet.error(e.toString());
    return bs.error(error: e.toString());
  }

  /// Listen for auth errors
  void onAuthError() {
    /// Trigger all cached auth data (Tokens, User data, ...)
    Core.get<AuthenticationCubit>().logoutHard();
  }
}
