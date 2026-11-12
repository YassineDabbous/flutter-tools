import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:laravel_provider/src/laravel_response.dart';

class LaravelErrorMapper {
  static AppFailure map(dynamic error) {
    if (error is! DioException) {
      if (error is AppFailure) {
        Object().logNet.warning('${error.runtimeType}: ${error.message}');
        return error;
      }
      Object().logNet.error('Non-Dio error: $error');
      return ServerFailure(error.toString());
    }

    final dioError = error;
    final response = dioError.response;

    if (dioError.type == DioExceptionType.connectionTimeout ||
        dioError.type == DioExceptionType.receiveTimeout ||
        dioError.type == DioExceptionType.sendTimeout ||
        dioError.type == DioExceptionType.connectionError) {
      Object().logNet.warning('Network timeout: ${dioError.type}');
      return const NetworkFailure();
    }

    if (response != null) {
      final data = response.data;
      final basicResponse = BasicResponseParser.tryParse(data);
      final msg = basicResponse?.error ?? basicResponse?.message;
      final code = basicResponse?.code;

      if (response.statusCode == 401) {
        Object().logNet.warning('Auth failure: 401');
        return AuthFailure(msg ?? 'Authentication failed.', code);
      }
      if (response.statusCode == 403) {
        // Prefer the `error` field: gates return `{"error": "...", "data":
        // {"code": "KYC_REQUIRED"|...}}` with no `message` (previously this
        // fell through to null → generic). Still user-facing text only —
        // `_friendlyMessage` strips anything technical downstream.
        final errorMsg = msg ?? 'Forbidden';
        Object().logNet.warning('Permission denied: $errorMsg (code: $code)');
        return PermissionFailure(errorMsg, code);
      }
      if (response.statusCode == 404) {
        Object().logNet.warning('Not found: ${response.realUri} ($msg, code: $code)');
        return NotFoundFailure(msg, code);
      }
      if (response.statusCode == 422) {
        Object().logNet.warning(
          'Validation failure: ${basicResponse?.message} (code: $code)',
        );
        return ValidationFailure(
          errors: basicResponse?.validation ?? {},
          message: basicResponse?.message,
          code: code,
        );
      }
      if (response.statusCode == 409) {
        Object().logNet.warning('Conflict: $msg (code: $code)');
        return ConflictFailure(msg, code);
      }

      if (response.statusCode! >= 500) {
        final errorMsg = msg ?? 'Server error';
        Object().logNet.error('Server error ($errorMsg, code: $code)');
        return ServerFailure(errorMsg, code);
      }

      if (response.statusCode! >= 400) {
        final errorMsg =
            msg ?? dioError.message ?? 'Server error';
        Object().logNet.error('Client error ($errorMsg, code: $code)');
        return ServerFailure(errorMsg, code);
      }
    }

    Object().logNet.error('Unexpected error: ${dioError.message}');
    return ServerFailure(dioError.message ?? 'An unexpected error occurred');
  }
}

extension BasicResponseParser on BasicResponse<dynamic> {
  static BasicResponse<dynamic>? tryParse(dynamic json) {
    if (json == null || json is! Map<String, dynamic>) return null;
    try {
      return BasicResponse<dynamic>.fromJson(json, (j) => null);
    } catch (_) {
      return null;
    }
  }
}
