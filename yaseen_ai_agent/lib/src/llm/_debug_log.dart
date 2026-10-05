// Internal File, not part of the Public API
//
// Debug-only HTTP logging with secret redaction. The Gemini key travels as a
// `?key=` query parameter, so full-URI logging would print it to the console;
// this interceptor logs method + path (query hidden) plus bodies. Only wired
// into provider-owned Dio clients under `kDebugMode` — never release, never
// injected (fake) clients.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Attaches redacted debug logging to [dio] (debug builds only).
void attachDebugLogging(Dio dio) {
  if (!kDebugMode) return;
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        debugPrint(
          '[yaseen_ai_agent] → ${options.method} ${options.path} '
          '(query hidden)',
        );
        debugPrint('[yaseen_ai_agent] → body: ${options.data}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint(
          '[yaseen_ai_agent] ← ${response.statusCode} '
          '${response.requestOptions.path}',
        );
        debugPrint('[yaseen_ai_agent] ← body: ${response.data}');
        handler.next(response);
      },
      onError: (error, handler) {
        debugPrint(
          '[yaseen_ai_agent] ✕ ${error.response?.statusCode} '
          '${error.requestOptions.path}: ${error.message}',
        );
        handler.next(error);
      },
    ),
  );
}
