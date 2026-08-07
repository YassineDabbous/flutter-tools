import 'package:flutter/widgets.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:core/core.dart';
import 'package:skeleton/skeleton.dart';

abstract class MyBaseState<StateType> extends Equatable {
  @override
  List<Object> get props => [];
  StateType get initial;

  /// creates a general Error state
  StateType error({required String error, int code = 0});

  /// creates an Authorization Error state
  StateType unauthorized({required String message, int code = 0}) =>
      error(error: message, code: code);

  /// creates a Validation Error state
  StateType validation(Map<String, dynamic> bag);
}

abstract class MyBaseCubit<
  ApiType extends BaseApiService<dynamic, dynamic, dynamic, dynamic>,
  BaseState extends MyBaseState
>
    extends Cubit<BaseState> {
  /// API instance
  ApiType? api;

  /// The base state, use as a factor for other states
  BaseState bs;

  MyBaseCubit({required this.bs}) : super(bs.initial) {
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

  /// Transform an Error/Exception to a bloc state
  BaseState _mapErrorToState(dynamic e) {
    if (e is AuthFailure) {
      onAuthError();
      return bs.error(error: e.message ?? 'auth_error'.i18n());
    } else if (e is ValidationFailure) {
      return bs.validation(e.errors);
    } else if (e is PermissionFailure) {
      return bs.unauthorized(message: _friendlyMessage(e));
    } else if (e is AppFailure) {
      return bs.error(error: _friendlyMessage(e));
    }

    return bs.error(error: 'error_occurred'.i18n());
  }

  /// Maps an [AppFailure] to a user-facing, localized message.
  /// Backend-provided messages are kept only when they are user-facing;
  /// technical exception/stack-trace text is replaced with a generic message.
  String _friendlyMessage(AppFailure failure) {
    if (failure is NetworkFailure) return 'network_error'.i18n();

    final message = failure.message;
    if (failure is NotFoundFailure) {
      final isBlank = message == null || message.trim().isEmpty;
      return isBlank || _looksTechnical(message)
          ? 'resource_not_found'.i18n()
          : message;
    }

    if (message == null || message.trim().isEmpty || _looksTechnical(message)) {
      return 'error_occurred'.i18n();
    }
    return message;
  }

  /// Heuristic: messages that look like raw backend internals should never
  /// be shown to the user verbatim.
  bool _looksTechnical(String message) {
    return message.contains('\\') ||
        message.contains('Exception') ||
        message.contains('SQLSTATE') ||
        message.contains('No query results for model') ||
        message.contains('<!DOCTYPE');
  }

  /// Listen for auth errors
  void onAuthError() {
    Core.get<AuthenticationCubit>().logoutHard();
  }

  /// Executes a future and handles any failures by throwing them
  /// so they can be caught by the calling method's try/catch blocks
  /// which then use mapErrorToState.
  @protected
  Future<T> handle<T>(Future<T> future) async {
    try {
      return await future;
    } catch (e) {
      // If it's already an AppFailure, just rethrow
      if (e is AppFailure) rethrow;

      // Otherwise, the caller's try/catch will handle the unknown error
      rethrow;
    }
  }
}
