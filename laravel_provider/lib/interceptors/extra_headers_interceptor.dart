import 'package:dio/dio.dart';

/// Merges a lazily-computed set of extra headers into every outgoing request.
///
/// Used by persona-scoped apps to inject headers that must accompany every
/// request — e.g. partner apps send `X-Partner-Id`. The factory is invoked
/// per-request so it always reads the latest active context (e.g. after a
/// partner switch), including on retried / token-refreshed calls.
class ExtraHeadersInterceptor extends Interceptor {
  final Map<String, String> Function() extraHeaders;

  ExtraHeadersInterceptor(this.extraHeaders);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final headers = extraHeaders();
    for (final entry in headers.entries) {
      options.headers[entry.key] = entry.value;
    }
    super.onRequest(options, handler);
  }
}
