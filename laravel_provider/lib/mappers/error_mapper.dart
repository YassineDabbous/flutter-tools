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

      if (response.statusCode == 401) {
        Object().logNet.warning('Auth failure: 401');
        return const AuthFailure();
      }
      if (response.statusCode == 403) {
        final msg = basicResponse?.message ?? 'Forbidden';
        Object().logNet.warning('Permission denied: $msg');
        return PermissionFailure(msg);
      }
      if (response.statusCode == 404) {
        Object().logNet.warning('Not found: ${response.realUri}');
        return const NotFoundFailure();
      }
      if (response.statusCode == 422) {
        Object().logNet.warning('Validation failure: ${basicResponse?.message}');
        return ValidationFailure(
          errors: basicResponse?.validation ?? {},
          message: basicResponse?.message,
        );
      }

      if (response.statusCode! >= 500) {
        final msg = basicResponse?.message ?? 'Server error';
        Object().logNet.error('Server error ($msg)');
        return ServerFailure(msg);
      }

      if (response.statusCode! >= 400) {
        final msg = basicResponse?.message ??
            dioError.message ??
            'Server error';
        Object().logNet.error('Client error ($msg)');
        return ServerFailure(msg);
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
