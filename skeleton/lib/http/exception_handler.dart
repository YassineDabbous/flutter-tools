import 'dart:io';
import 'package:dio/dio.dart';
import 'package:core/core.dart';
import 'package:skeleton/skeleton.dart';

/// Mixin providing utility methods to handle and convert various exceptions
/// (especially [DioException]) into custom app exceptions.
mixin ExceptionHandler {
  /// Handles a future response, unwrapping the data or throwing a custom exception.
  Future<T?> handle<T>(Future<BasicResponse<T>> r) async {
    try {
      return (await r).data;
    } on Exception catch (e) {
      throw ex(e);
    }
  }

  /// Handles a future response, returning the root [BasicResponse] object.
  Future<BasicResponse<T?>> handleRoot<T>(Future<BasicResponse<T>> r) async {
    try {
      return (await r);
    } on Exception catch (e) {
      throw ex(e);
    }
  }

  /// Converts a raw [Exception] into a custom app exception based on type/status code.
  Exception ex(Exception err) {
    logNet.error('API Error: ${err.runtimeType} \n $err');

    if (err is DioException) {
      logNet.error('DioError type: ${err.type} \n status: ${err.response?.statusCode}');

      if (err.type == DioExceptionType.badResponse) {
        final res = err.response!;
        final r = BasicResponse.tryParse(res.data);

        if (res.statusCode == 401) return AuthException();
        if (res.statusCode == 403) return PermissionException(message: r?.error ?? 'No permission.');
        if (res.statusCode == 404) return NotFoundException();

        if (res.statusCode == 422) {
          if (r?.validation != null) return ValidationException(bag: r!.validation!);
        }

        if (res.statusCode! >= 400 && res.statusCode! <= 499) {
          return ClientException(message: r?.error ?? 'Client error.', code: r?.code ?? 0);
        }

        if (res.statusCode! >= 500) {
          return ServerException(message: 'ServerSide error: ${res.statusMessage}');
        }
      }

      if (err.error is SocketException) {
        return NoInternetException();
      }
    } else if (err is SocketException) {
      return NoInternetException();
    }

    return err; // Return the original error if it cannot be mapped
  }
}
