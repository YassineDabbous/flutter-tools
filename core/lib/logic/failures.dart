import 'package:equatable/equatable.dart';

/// Base class for all application failures.
/// Renamed to AppFailure to avoid collision with Result.Failure.
abstract class AppFailure extends Equatable {
  final String? message;
  const AppFailure([this.message]);

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'Network connection problem.']);
}

class AuthFailure extends AppFailure {
  const AuthFailure([super.message = 'Authentication failed.']);
}

class ValidationFailure extends AppFailure {
  final Map<String, dynamic> errors;
  const ValidationFailure({this.errors = const {}, String? message}) : super(message ?? 'Validation failed.');

  @override
  List<Object?> get props => [super.props, errors];
}

class ServerFailure extends AppFailure {
  const ServerFailure([super.message = 'Internal server error.']);
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = 'Resource not found.']);
}

class PermissionFailure extends AppFailure {
  const PermissionFailure([super.message = 'Permission denied.']);
}
