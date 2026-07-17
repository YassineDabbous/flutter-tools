import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:laravel_provider/src/laravel_response.dart';

class LaravelErrorMapper {
  static AppFailure map(dynamic error) {
    if (error is! DioException) {
      if (error is AppFailure) return error;
      return ServerFailure(error.toString());
    }

    final dioError = error;
    final response = dioError.response;

    if (dioError.type == DioExceptionType.connectionTimeout ||
        dioError.type == DioExceptionType.receiveTimeout ||
        dioError.type == DioExceptionType.sendTimeout ||
        dioError.type == DioExceptionType.connectionError) {
      return const NetworkFailure();
    }

    if (response != null) {
      final data = response.data;
      final basicResponse = BasicResponseParser.tryParse(data);

      if (response.statusCode == 401) return const AuthFailure();
      if (response.statusCode == 403) {
        return PermissionFailure(basicResponse?.message ?? 'Forbidden');
      }
      if (response.statusCode == 404) return const NotFoundFailure();
      if (response.statusCode == 422) {
        return ValidationFailure(
          errors: basicResponse?.validation ?? {},
          message: basicResponse?.message,
        );
      }

      if (response.statusCode! >= 500) {
        return ServerFailure(basicResponse?.message ?? 'Server error');
      }

      if (response.statusCode! >= 400) {
        return ServerFailure(
          basicResponse?.message ?? dioError.message ?? 'Server error',
        );
      }
    }

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
