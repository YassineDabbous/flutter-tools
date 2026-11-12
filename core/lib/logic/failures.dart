import 'package:equatable/equatable.dart';

/// Base class for all application failures.
/// Renamed to AppFailure to avoid collision with Result.Failure.
abstract class AppFailure extends Equatable {
  final String? message;
  final String? code;
  const AppFailure([this.message, this.code]);

  @override
  List<Object?> get props => [message, code];
}

class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'Network connection problem.', super.code]);
}

class AuthFailure extends AppFailure {
  const AuthFailure([super.message = 'Authentication failed.', super.code]);
}

class ValidationFailure extends AppFailure {
  final Map<String, dynamic> errors;
  const ValidationFailure({this.errors = const {}, String? message, String? code})
    : super(message ?? 'Validation failed.', code);

  @override
  List<Object?> get props => [super.props, errors];
}

class ServerFailure extends AppFailure {
  const ServerFailure([super.message = 'Internal server error.', super.code]);
}

class ConflictFailure extends AppFailure {
  const ConflictFailure([super.message = 'Conflict error.', super.code]);
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = 'Resource not found.', super.code]);
}

class PermissionFailure extends AppFailure {
  const PermissionFailure([super.message = 'Permission denied.', super.code]);
}
