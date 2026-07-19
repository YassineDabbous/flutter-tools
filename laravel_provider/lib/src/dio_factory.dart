import 'package:dio/dio.dart';
import 'package:core/core.dart';
import '../interceptors/interceptors.dart';

class DioClientFactory {
  static Dio createDio(String baseUrl) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
  }

  static void addInterceptors(
    Dio dio, {
    required Config config,
    required AuthLocalManager authManager,
    required SharedPrefHelper prefHelper,
    bool debug = false,
  }) {
    final interceptors = [
      AuthInterceptor(config, authManager, prefHelper),
      TokenRefreshInterceptor(authManager, dio),
      RetryInterceptor(dio),
      OfflineQueueInterceptor(),
    ];

    if (debug) {
      interceptors.add(PrettyLogInterceptor( logPrint: (o) => Object().logNet.info(o.toString()), ) );
    }

    dio.interceptors.addAll(interceptors);

  }
}
