import 'dart:io';

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/foundation.dart'; 

/// Overrides default HTTP client behavior (e.g., ignoring bad certificates).
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = ((X509Certificate cert, String host, int port) {
        return true; // Allows all bad certificates (for development)
      });
  }
}

/// Base class for the Dio HTTP client instance.
class BaseDio {
  late Dio dio;

  /// The constructor now accepts an optional list of custom interceptors.
  BaseDio({List<Interceptor>? customInterceptors}) {
    logNet.debug('BaseDio instance created.');
    HttpOverrides.global = MyHttpOverrides(); // Apply security overrides
    dio = Dio();

    // --- App-Provided Custom Interceptors ---
    // Use the spread operator to add all interceptors from the provided list.
    if (customInterceptors != null && customInterceptors.isNotEmpty) {
      // dio.interceptors.addAll(customInterceptors);
      for (var element in customInterceptors) {
        dio.interceptors.add(element);
      }
      logNet.debug('${customInterceptors.length} custom interceptor(s) added.');
    }

    // Add logging interceptor for non-release builds
    if (!kReleaseMode) {
      dio.interceptors.add(
        PrettyLogInterceptor(
          logPrint: (x) => kReleaseMode ? null : debugPrint(x.toString()),
        ),
      );
    }

    // Add caching interceptor
    dio.interceptors.add(DioCacheInterceptor(options: Cache.cacheOptions));

    // Set the base URL from the config. This is one of the few direct
    // interactions needed, as it's a fundamental property of the client.
    dio.options.baseUrl = Core.get<Config>().baseUrl;

    logNet.debug('BaseDio initialized with standard interceptors.');
  }

  /// Factory constructor to get the current BaseDio instance and ensure
  /// the main user account auth token is applied (used primarily for switch between profiles).
  factory BaseDio.auth() {
    BaseDio instance = Core.get<BaseDio>();
    final u = Core.get<AuthLocalManager>();

    // Apply real token if available
    if (u.realToken != null) {
      instance.dio.options.headers["Authorization"] = "Bearer ${u.realToken}";
    }
    return instance..logAuth.debug('BaseDio.auth() token checked/updated.');
  }
}
