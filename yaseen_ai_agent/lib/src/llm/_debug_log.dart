// Internal File, not part of the Public API
//
// Debug-only HTTP logging in the `pretty_dio_logger` style (compact,
// `maxWidth: 160`), mirroring `laravel_provider`'s `PrettyLogInterceptor`.
// Two deliberate differences from that interceptor:
//
// 1. Headers and the query string are NEVER logged: the Gemini key travels as
//    `?key=` and OpenAI/Bearer tokens travel in `Authorization`. What would be
//    a readable log line elsewhere is a credential leak here.
// 2. The `home`/`customization` path skip is Laravel-specific and not copied.
//
// Only wired into provider-owned Dio clients under `kDebugMode` — never
// release, never injected (fake) clients.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

/// Pretty request/response logger with credential redaction.
///
/// Extends [PrettyDioLogger] for the compact format, but routes every line
/// through [_redactedPrint], which strips query strings (`?key=...`) and
/// bearer tokens before they reach the console.
class AiPrettyLogger extends PrettyDioLogger {
  AiPrettyLogger()
    : super(
        requestHeader: false,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 160,
        logPrint: _redactedPrint,
      );

  static final _queryPattern = RegExp(r'\?[^\s]*');
  static final _bearerPattern = RegExp(r'Bearer [^\s]+');

  static void _redactedPrint(Object line) {
    var text = line.toString();
    // Gemini `?key=` and any other query material never reach the console.
    text = text.replaceAll(_queryPattern, ' (query hidden)');
    // Defense in depth: bodies carrying a pasted token stay redacted too.
    text = text.replaceAll(_bearerPattern, 'Bearer ***');
    debugPrint('[yaseen_ai_agent] $text');
  }
}

/// Attaches redacted pretty logging to [dio] (debug builds only).
void attachDebugLogging(Dio dio) {
  if (!kDebugMode) return;
  dio.interceptors.add(AiPrettyLogger());
}
