import 'package:dio/dio.dart';
import 'package:core/core.dart';

/// Interceptor to handle 401 Unauthorized errors by attempting to refresh the token.
class TokenRefreshInterceptor extends QueuedInterceptor {
  final AuthLocalManager _authManager;
  final Dio _dio;
  bool _isRefreshing = false;

  TokenRefreshInterceptor(this._authManager, this._dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    if (_isRefreshing) {
      // If already refreshing, let the error propagate or queue if needed.
      // QueuedInterceptor handles serializing requests during error handling.
      return handler.next(err);
    }

    _isRefreshing = true;
    try {
      final newToken = await _refreshToken();
      if (newToken != null) {
        await _authManager.updateToken(newToken);
        
        // Retry the original request with the new token
        final options = err.requestOptions;
        options.headers['Authorization'] = 'Bearer $newToken';
        
        final response = await _dio.fetch(options);
        return handler.resolve(response);
      }
    } catch (e) {
      logAuth.error('Token refresh failed: $e');
      // On fatal refresh failure, trigger a logout
      // Core.get<AuthenticationCubit>().logout(); // Assume this exists in blocs
    } finally {
      _isRefreshing = false;
    }

    handler.next(err);
  }

  Future<String?> _refreshToken() async {
    final response = await _dio.post('/auth/refresh', options: Options(
      headers: {'Authorization': 'Bearer ${_authManager.currentUser?.token}'},
    ));
    return response.data?['token'];
  }
}
