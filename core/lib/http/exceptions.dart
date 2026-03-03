/// Exception thrown for validation errors (usually HTTP 422).
class ValidationException implements Exception {
  /// Map containing field-specific validation messages.
  final Map<String, dynamic> bag;
  ValidationException({required this.bag});
}

/// Generic exception for cache failures.
class CacheException implements Exception {}

/// Base class for exceptions that carry a readable message and optional code.
class ExceptionWithMessage implements Exception {
  final int code;
  final String message;
  ExceptionWithMessage({required this.message, this.code = 0});
}

/// HTTP 5xx errors.
class ServerException extends ExceptionWithMessage {
  ServerException({super.message = '🤔 Server error occurred.'});
}

/// HTTP 4xx errors (general client-side errors).
class ClientException extends ExceptionWithMessage {
  ClientException({super.message = '😏 Client error occurred.', super.code});
}

/// HTTP 404 error.
class NotFoundException extends ExceptionWithMessage {
  NotFoundException({super.message = '😵‍💫 Data not found.'});
}

/// HTTP 401 error.
class AuthException extends ExceptionWithMessage {
  AuthException({super.message = '🙃 Login first!'});
}

/// HTTP 403 error.
class PermissionException extends ExceptionWithMessage {
  PermissionException({super.message = '⛔ Unauthorized, need permission'});
}

/// Thrown when a network connection is unavailable.
class NoInternetException extends ExceptionWithMessage {
  NoInternetException({super.message = '🙄 No internet connection!'});
}
