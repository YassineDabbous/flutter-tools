import 'package:dio/dio.dart';
import 'package:core/core.dart';
import '../interceptors/interceptors.dart';

class DioClientFactory {
  static Dio create({
    required String baseUrl,
    required Config config,
    required AuthLocalManager authManager,
    required SharedPrefHelper prefHelper,
    bool debug = false,
  }) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    final interceptors = [
      AuthInterceptor(config, authManager, prefHelper),
      TokenRefreshInterceptor(authManager, dio),
      RetryInterceptor(dio),
      OfflineQueueInterceptor(),
    ];

    if (debug) {
      interceptors.add(PrettyLogInterceptor());
    }

    dio.interceptors.addAll(interceptors);
    return dio;
  }
}
