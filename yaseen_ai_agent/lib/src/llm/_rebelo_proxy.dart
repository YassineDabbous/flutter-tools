// Internal File, not part of the Public API

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:yaseen_ai_agent/src/llm/_debug_log.dart';
import 'package:yaseen_ai_agent/src/llm/llm.dart';
import 'package:yaseen_ai_agent/src/llm/llm_config.dart';
import 'package:yaseen_ai_agent/src/static/yaseen_ai_agent_exceptions.dart';
import 'package:yaseen_ai_agent/src/tools/tool.dart';

/// Rebelo AI-proxy LLM implementation (`POST {baseUrl}/ai/assistant`).
///
/// A secure server-side proxy: the app sends the conversation and receives
/// text back. Provider credentials live on the server, so there is no API key
/// here — authentication comes from the injected [client] (the app's
/// authenticated Dio, whose interceptors attach the Sanctum token plus
/// `Tenant-Id`/locale headers).
///
/// Contract notes (see `.local/reports/backend-ai.md`):
/// - Relative [endpoint] (`ai/assistant`, no leading slash): the shared Dio's
///   base URL already ends in `/api/v1`; a leading slash would resolve to the
///   host root and drop the prefix.
/// - `Accept` is set per mode, but the app's `AuthInterceptor` unconditionally
///   rewrites it to `application/json` — the server keys streaming off the
///   `stream` body flag, so this is advisory only.
/// - `RetryInterceptor` never replays POSTs and `OfflineQueueInterceptor`
///   only queues while offline (a stale queued turn replays once on flush;
///   the stateless server answers and the response is discarded) — both are
///   safe to share.
/// - `provider`/`model` are intentionally never sent (server default); the
///   backend owns routing. `request_id` (uuid v4) goes out per call for
///   server-side tracing.
/// - Text-only: [rawData] images and native [tools] are ignored. Tool specs
///   travel inside the system messages (JSON-text fallback path), and tool
///   execution stays client-side in the agent loop.
class RebeloProxy extends LLM {
  /// Relative endpoint — resolved against the injected Dio's base URL.
  static const String endpoint = '/ai/assistant';

  final LlmConfig _config;
  final Dio _client;

  /// Creates a Rebelo proxy instance.
  ///
  /// Pass the app's authenticated Dio as [client] (or a fake Dio in tests).
  /// [baseUrl] is only used to build an owned client when [client] is null
  /// (unauthenticated use will 401 — logged-out turns surface the generic
  /// retryable UI key by design).
  RebeloProxy({
    Dio? client,
    String? baseUrl,
    LlmConfig config = const LlmConfig(timeout: Duration(seconds: 180)),
  }) : assert(
         client != null || baseUrl != null,
         'RebeloProxy needs an injected Dio or a baseUrl.',
       ),
       _config = config,
       _client =
           client ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl!,
               connectTimeout: config.timeout,
               receiveTimeout: config.timeout,
               sendTimeout: config.timeout,
               headers: {'Content-Type': 'application/json'},
             ),
           ) {
    // Debug traffic only on owned clients (never injected fakes/app Dio,
    // which has its own pretty logger), and only in debug builds.
    if (client == null) attachDebugLogging(_client);
  }

  @override
  String get modelId => 'rebelo-proxy';

  @override
  LlmConfig get config => _config;

  @override
  bool get supportsNativeTools => false;

  @override
  bool get prefersStructuredHistory => true;

  /// Client-side wire validation: 1–20 messages, each a `role`/`content` pair
  /// within the char cap. Throws before any HTTP call so violations are loud
  /// in dev logs instead of server 422s.
  void _checkWireLimits(List<Map<String, String>> messages) {
    if (messages.isEmpty || messages.length > 20) {
      throw ConfigException(
        'Rebelo proxy needs 1–20 messages, got ${messages.length}.',
      );
    }
    for (final m in messages) {
      final content = m['content'] ?? '';
      if (content.length > 4000) {
        throw ConfigException(
          'Rebelo proxy message (${m['role']}) exceeds 4000 chars '
          '(${content.length}); trim client-side before sending.',
        );
      }
    }
  }

  Options _options({required bool stream}) => Options(
    headers: {
      'Content-Type': 'application/json',
      // Advisory: AuthInterceptor rewrites Accept on the shared Dio.
      'Accept': stream ? 'text/event-stream' : 'application/json',
    },
    // The shared app Dio defaults to 15 s; the proxy (especially via
    // cold-start Ollama) needs the full configured window per request.
    sendTimeout: _config.timeout,
    receiveTimeout: _config.timeout,
  );

  Map<String, dynamic> _body(
    List<Map<String, String>> messages, {
    required bool stream,
  }) => {
    'messages': messages,
    'stream': stream,
    'request_id': const Uuid().v4(),
  };

  Duration? _parseRetryAfter(Headers? headers) {
    final value = headers?.value('retry-after');
    if (value == null) return null;
    final seconds = int.tryParse(value.trim());
    return seconds != null ? Duration(seconds: seconds) : null;
  }

  YaseenAiAgentException _mapDio(DioException e, StackTrace st) {
    final status = e.response?.statusCode;
    final msg =
        'Rebelo proxy call failed: ${e.message} (status $status) '
        'body=${e.response?.data}';
    if (status == 429) {
      return LlmRateLimitException(
        msg,
        cause: e,
        causeStack: st,
        retryAfter: _parseRetryAfter(e.response?.headers),
      );
    }
    return LlmException(msg, cause: e, causeStack: st, statusCode: status);
  }

  /// Unwraps the `data.text` envelope; throws on error envelopes and empty
  /// replies instead of letting them masquerade as success.
  String _extractText(dynamic data) {
    try {
      final map = data as Map?;
      final error = map?['error'];
      if (error != null && error.toString().isNotEmpty) {
        throw LlmException('Rebelo proxy error envelope: $error');
      }
      final inner = map?['data'];
      final text = inner is Map ? inner['text'] as String? : null;
      if (text == null || text.isEmpty) {
        throw const LlmException('Rebelo proxy returned no text');
      }
      return text;
    } on YaseenAiAgentException {
      rethrow;
    } catch (e, st) {
      throw LlmException(
        'Failed to parse Rebelo proxy response: $e',
        cause: e,
        causeStack: st,
      );
    }
  }

  @override
  Future<String> generateWithMessages({
    required List<Map<String, String>> messages,
    Uint8List? rawData,
    String mimeType = 'image/jpeg',
    List<Tool>? tools,
  }) async {
    // Text-only proxy: images and native tools are ignored (specs travel in
    // the system messages; execution stays client-side).
    _checkWireLimits(messages);
    try {
      final response = await _client
          .post(
            endpoint,
            data: _body(messages, stream: false),
            options: _options(stream: false),
          )
          .timeout(_config.timeout);
      return _extractText(response.data);
    } on TimeoutException catch (e, st) {
      throw LlmTimeoutException(
        'Rebelo proxy request exceeded ${_config.timeout.inSeconds}s',
        cause: e,
        causeStack: st,
      );
    } on DioException catch (e, st) {
      throw _mapDio(e, st);
    } on YaseenAiAgentException {
      rethrow;
    } catch (e, st) {
      throw LlmException(
        'Rebelo proxy call failed: $e',
        cause: e,
        causeStack: st,
      );
    }
  }

  @override
  Stream<String> generateStreamWithMessages({
    required List<Map<String, String>> messages,
    Uint8List? rawData,
    String mimeType = 'image/jpeg',
    List<Tool>? tools,
  }) async* {
    _checkWireLimits(messages);
    try {
      final response = await _client
          .post<ResponseBody>(
            endpoint,
            data: _body(messages, stream: true),
            options: _options(
              stream: true,
            ).copyWith(responseType: ResponseType.stream),
          )
          .timeout(_config.timeout);
      var yieldedAny = false;
      var buf = '';
      // cast: Utf8Decoder is a StreamTransformer<List<int>, String>, while
      // the Dio byte stream is typed Stream<Uint8List>.
      final textStream = response.data!.stream.cast<List<int>>().transform(
        utf8.decoder,
      );
      await for (final chunk in textStream) {
        buf += chunk;
        // Frames are `event:` + `data:` lines separated by a blank line;
        // the last (possibly incomplete) part stays buffered.
        final parts = buf.split('\n\n');
        buf = parts.removeLast();
        for (final frame in parts) {
          String? event;
          String? data;
          for (final line in frame.split('\n')) {
            final trimmed = line.trim();
            if (trimmed.startsWith('event:')) {
              event = trimmed.substring(6).trim();
            } else if (trimmed.startsWith('data:')) {
              data = trimmed.substring(5).trim();
            }
          }
          if (data == null || data.isEmpty) continue;
          if (data == '[DONE]') return;
          if (event == 'error') {
            throw LlmException('Rebelo proxy stream interrupted: $data');
          }
          if (event == 'meta') continue;
          try {
            final decoded = json.decode(data);
            final delta = decoded is Map ? decoded['delta'] : null;
            if ((event == null || event == 'delta') &&
                delta is String &&
                delta.isNotEmpty) {
              yieldedAny = true;
              yield delta;
            }
            // Unknown event types are ignored (forward-compat).
          } catch (_) {
            // Skip malformed frames; an empty stream still fails below.
          }
        }
      }
      if (!yieldedAny) {
        throw const LlmException('Rebelo proxy stream returned no content');
      }
    } on TimeoutException catch (e, st) {
      throw LlmTimeoutException(
        'Rebelo proxy request exceeded ${_config.timeout.inSeconds}s',
        cause: e,
        causeStack: st,
      );
    } on DioException catch (e, st) {
      throw _mapDio(e, st);
    } on YaseenAiAgentException {
      rethrow;
    } catch (e, st) {
      throw LlmException(
        'Rebelo proxy stream failed: $e',
        cause: e,
        causeStack: st,
      );
    }
  }

  /// Legacy single-prompt path (used by summarization/reasoning helpers):
  /// wraps the prompt as one final `user` message. Large prompts hit the
  /// client-side wire guard instead of a server 422.
  @override
  Future<String> generate({
    required String prompt,
    String? systemInstruction,
    Uint8List? rawData,
    String mimeType = 'image/jpeg',
    List<Tool>? tools,
  }) => generateWithMessages(
    messages: [
      if (systemInstruction != null && systemInstruction.isNotEmpty)
        {'role': 'system', 'content': systemInstruction},
      {'role': 'user', 'content': prompt},
    ],
  );
}
