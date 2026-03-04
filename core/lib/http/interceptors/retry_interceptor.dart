import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:core/core.dart';

/// Interceptor that retries failed requests with exponential backoff.
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration initialDelay;
  final Set<int> retryableStatusCodes;

  RetryInterceptor({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.retryableStatusCodes = const {408, 429, 500, 502, 503, 504},
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final attempt = (err.requestOptions.extra['retry_attempt'] ?? 0) as int;

    if (attempt >= maxRetries || !_shouldRetry(err)) {
      return handler.next(err);
    }

    final delay = initialDelay * pow(2, attempt);
    logNet.warning('Retrying request (attempt ${attempt + 1}) in ${delay.inSeconds}s...');
    
    await Future.delayed(delay);

    err.requestOptions.extra['retry_attempt'] = attempt + 1;

    try {
      // Use the same Dio instance to fulfill the request
      final response = await Core.get<BaseDio>().dio.fetch(err.requestOptions);
      handler.resolve(response);
    } catch (e) {
      // If the retry itself fails, the next call to onError will handle it (or stop if reached maxRetries)
      if (e is DioException) {
        // We don't call handler.next(err) here because the recursive call to fetch 
        // will trigger another onError which will eventually call handler.next.
      } else {
        handler.next(err);
      }
    }
  }

  bool _shouldRetry(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError) return true;
        
    if (err.response != null &&
        retryableStatusCodes.contains(err.response!.statusCode)) return true;
        
    return false;
  }
}
