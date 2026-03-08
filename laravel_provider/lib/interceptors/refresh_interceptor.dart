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

    // Don't refresh if the request itself is a refresh request or if we're already refreshing
    if (err.requestOptions.path.contains('auth/refresh') || _isRefreshing) {
      return handler.next(err);
    }

    _isRefreshing = true;
    try {
      final newToken = await _refreshToken(err.requestOptions.baseUrl);
      if (newToken != null) {
        await _authManager.updateToken(newToken);

        final options = err.requestOptions;
        options.headers['Authorization'] = 'Bearer $newToken';

        try {
          final response = await _dio.fetch(options);
          return handler.resolve(response);
        } catch (retryError) {
          return handler.next(retryError is DioException ? retryError : err);
        }
      } else {
        logAuth.error('○○○○○○○ Token refresh returned null ○○○○○○○');
        Core.get<AuthenticationCubit>().logoutHard();
      }
    } catch (refreshError) {
      logAuth.error('○○○○○○○ Token refresh failed: $refreshError ○○○○○○○');
      Core.get<AuthenticationCubit>().logoutHard();
    } finally {
      _isRefreshing = false;
    }

    handler.next(err);
  }

  Future<String?> _refreshToken(String baseUrl) async {
    // Use a clean Dio instance to avoid interceptor recursion
    final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
    final response = await refreshDio.post(
      '/auth/refresh',
      options: Options(
        headers: {'Authorization': 'Bearer ${_authManager.currentUser?.token}'},
      ),
    );
    return response.data?['token'];
  }
}
