import 'package:equatable/equatable.dart';

/// A standard sealed state hierarchy for Caky applications.
/// Features can define their own sealed states by following this pattern.
sealed class CakyState extends Equatable {
  const CakyState();

  @override
  List<Object?> get props => [];
}

/// Initial state, before any action is taken.
class InitialState extends CakyState {
  const InitialState();
}

/// Loading state, typically used for initial data fetching.
class LoadingState extends CakyState {
  const LoadingState();
}

/// Success state with generic data.
class LoadedState<T> extends CakyState {
  final T data;
  const LoadedState(this.data);

  @override
  List<Object?> get props => [data];
}

/// Error state with message and optional code.
class ErrorState extends CakyState {
  final String message;
  final int code;
  const ErrorState(this.message, {this.code = 0});

  @override
  List<Object?> get props => [message, code];
}

/// Validation error state with form field messages.
class ValidationErrorState extends CakyState {
  final Map<String, dynamic> errors;
  const ValidationErrorState(this.errors);

  @override
  List<Object?> get props => [errors];
}

/// CRUD specifically: Saving/Deleting states.
class SavingState extends CakyState {
  const SavingState();
}

class DeletingState extends CakyState {
  const DeletingState();
}

class ActionSuccessState extends CakyState {
  final int id;
  const ActionSuccessState(this.id);
  @override
  List<Object?> get props => [id];
}
