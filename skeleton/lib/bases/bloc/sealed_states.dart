import 'package:equatable/equatable.dart';

/// A standard sealed state hierarchy for applications.
/// Features can define their own sealed states by following this pattern.
sealed class AppState extends Equatable {
  const AppState();

  @override
  List<Object?> get props => [];
}

/// Initial state, before any action is taken.
class InitialState extends AppState {
  const InitialState();
}

/// Loading state, typically used for initial data fetching.
class LoadingState extends AppState {
  const LoadingState();
}

/// Success state with generic data.
class LoadedState<T> extends AppState {
  final T data;
  const LoadedState(this.data);

  @override
  List<Object?> get props => [data];
}

/// Error state with message and optional code.
class ErrorState extends AppState {
  final String message;
  final int code;
  const ErrorState(this.message, {this.code = 0});

  @override
  List<Object?> get props => [message, code];
}

/// Validation error state with form field messages.
class ValidationErrorState extends AppState {
  final Map<String, dynamic> errors;
  const ValidationErrorState(this.errors);

  @override
  List<Object?> get props => [errors];
}

/// CRUD specifically: Saving/Deleting states.
class SavingState extends AppState {
  const SavingState();
}

class DeletingState extends AppState {
  const DeletingState();
}

/// Success after a CRUD action (create/update/delete).
/// ID is generic to support both int and UUID.
class ActionSuccessState<ID> extends AppState {
  final ID id;
  const ActionSuccessState(this.id);

  @override
  List<Object?> get props => [id];
}
