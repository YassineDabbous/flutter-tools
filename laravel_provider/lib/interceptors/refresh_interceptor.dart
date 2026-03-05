import 'package:dio/dio.dart';
import 'package:core/core.dart';

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
      return handler.next(err);
    }

    _isRefreshing = true;
    try {
      final newToken = await _refreshToken();
      if (newToken != null) {
        await _authManager.updateToken(newToken);
        
        final options = err.requestOptions;
        options.headers['Authorization'] = 'Bearer $newToken';
        
        final response = await _dio.fetch(options);
        return handler.resolve(response);
      }
    } catch (e) {
      // Refresh failed
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
