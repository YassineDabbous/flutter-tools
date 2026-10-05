// Internal File, not part of the Public API

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:yaseen_ai_agent/src/llm/_sse.dart';
import 'package:yaseen_ai_agent/src/llm/_tool_schemas.dart';
import 'package:yaseen_ai_agent/src/llm/llm.dart';
import 'package:yaseen_ai_agent/src/llm/llm_config.dart';
import 'package:yaseen_ai_agent/src/static/yaseen_ai_agent_exceptions.dart';
import 'package:yaseen_ai_agent/src/tools/tool.dart';
import 'package:dio/dio.dart';

/// OpenAI Chat Completions LLM implementation.
class OpenAI extends LLM {
  final String _modelName;
  final LlmConfig _config;
  final Dio _client;

  /// Creates an OpenAI instance. [modelName] is e.g. `gpt-4o`, `gpt-4o-mini`,
  /// `gpt-4.1`, or any chat-completions compatible model.
  ///
  /// Pass [baseUrl] to point at an OpenAI-compatible endpoint (DeepSeek, Grok,
  /// Groq, OpenRouter, etc.); defaults to `https://api.openai.com/v1`.
  OpenAI({
    required String apiKey,
    required String modelName,
    LlmConfig config = const LlmConfig(),
    String baseUrl = 'https://api.openai.com/v1',
    Map<String, String> extraHeaders = const {},
    Dio? client,
  }) : _modelName = modelName,
       _config = config,
       _client =
           client ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               connectTimeout: config.timeout,
               receiveTimeout: config.timeout,
               sendTimeout: config.timeout,
               headers: {
                 'Authorization': 'Bearer $apiKey',
                 'Content-Type': 'application/json',
                 ...extraHeaders,
               },
             ),
           );

  @override
  String get modelId => _modelName;

  @override
  LlmConfig get config => _config;

  @override
  bool get supportsNativeTools => true;

  @override
  Future<String> generate({
    required String prompt,
    String? systemInstruction,
    Uint8List? rawData,
    String mimeType = 'image/jpeg',
    List<Tool>? tools,
  }) async {
    try {
      final messages = _buildMessages(
        prompt,
        systemInstruction,
        rawData,
        mimeType,
      );

      final body = _requestBody(messages, tools);

      final response = await _client
          .post('/chat/completions', data: body)
          .timeout(_config.timeout);

      return _extractMessage(response.data);
    } on TimeoutException catch (e, st) {
      throw LlmTimeoutException(
        'OpenAI request exceeded ${_config.timeout.inSeconds}s',
        cause: e,
        causeStack: st,
      );
    } on DioException catch (e, st) {
      final status = e.response?.statusCode;
      final msg = 'OpenAI call failed: ${e.message} (status $status)';
      if (status == 429) {
        throw LlmRateLimitException(
          msg,
          cause: e,
          causeStack: st,
          retryAfter: _parseRetryAfter(e.response?.headers),
        );
      }
      throw LlmException(msg, cause: e, causeStack: st, statusCode: status);
    } on YaseenAiAgentException {
      rethrow;
    } catch (e, st) {
      throw LlmException('OpenAI call failed: $e', cause: e, causeStack: st);
    }
  }

  List<Map<String, dynamic>> _buildMessages(
    String prompt,
    String? systemInstruction,
    Uint8List? rawData,
    String mimeType,
  ) {
    final messages = <Map<String, dynamic>>[];

    // OpenAI requires the literal word "json" in messages when response_format is json_object.
    final sys = <String>[
      if (systemInstruction != null) systemInstruction,
      if (_config.jsonMode)
        'Respond with ONLY a valid json object. No prose, no markdown fences.',
    ].join('\n\n');

    if (sys.isNotEmpty) {
      messages.add({'role': 'system', 'content': sys});
    }

    if (rawData == null) {
      messages.add({'role': 'user', 'content': prompt});
    } else {
      messages.add({
        'role': 'user',
        'content': [
          {'type': 'text', 'text': prompt},
          {
            'type': 'image_url',
            'image_url': {
              'url': 'data:$mimeType;base64,${base64Encode(rawData)}',
            },
          },
        ],
      });
    }

    return messages;
  }

  Duration? _parseRetryAfter(Headers? headers) {
    final value = headers?.value('retry-after');
    if (value == null) return null;
    final seconds = int.tryParse(value.trim());
    return seconds != null ? Duration(seconds: seconds) : null;
  }

  Map<String, dynamic> _requestBody(
    List<Map<String, dynamic>> messages,
    List<Tool>? tools,
  ) {
    final effectiveTools = tools ?? const <Tool>[];
    return <String, dynamic>{
      'model': _modelName,
      'messages': messages,
      if (_config.temperature != null) 'temperature': _config.temperature,
      if (_config.topP != null) 'top_p': _config.topP,
      if (_config.maxOutputTokens != null)
        'max_tokens': _config.maxOutputTokens,
      if (_config.stopSequences != null && _config.stopSequences!.isNotEmpty)
        'stop': _config.stopSequences,
      // Native tools and json_object mode are mutually exclusive.
      if (effectiveTools.isNotEmpty) ...{
        'tools': [for (final t in effectiveTools) openAiToolSchema(t)],
        'tool_choice': 'auto',
      } else if (_config.jsonMode)
        'response_format': {'type': 'json_object'},
    };
  }

  /// Extracts the assistant message. Native `tool_calls` are bridged into the
  /// canonical JSON-text contract so the agent parser stays uniform.
  String _extractMessage(dynamic data) {
    try {
      final choices = data['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        throw const LlmException('OpenAI returned empty choices array');
      }
      final message = (choices.first as Map)['message'] as Map?;
      final toolCalls = message?['tool_calls'] as List?;
      if (toolCalls != null && toolCalls.isNotEmpty) {
        return _canonicalToolsJson(toolCalls);
      }
      final content = message?['content'] as String?;
      if (content == null || content.isEmpty) {
        throw const LlmException('OpenAI returned empty message content');
      }
      return content.trim();
    } on YaseenAiAgentException {
      rethrow;
    } catch (e, st) {
      throw LlmException(
        'Failed to parse OpenAI response: $e',
        cause: e,
        causeStack: st,
      );
    }
  }

  /// Serializes native tool calls into `{"tools": [...], "parameters": {...}}`.
  String _canonicalToolsJson(List<dynamic> toolCalls) {
    final names = <String>[];
    final params = <String, dynamic>{};
    for (final call in toolCalls) {
      final fn = (call as Map)['function'] as Map?;
      final name = fn?['name']?.toString() ?? '';
      if (name.isEmpty) continue;
      names.add(name);
      final rawArgs = fn?['arguments'];
      try {
        params[name] = rawArgs is String
            ? json.decode(rawArgs) as Map<String, dynamic>
            : <String, dynamic>{};
      } catch (_) {
        params[name] = <String, dynamic>{};
      }
    }
    return json.encode({'tools': names, 'parameters': params});
  }

  @override
  Stream<String> generateStream({
    required String prompt,
    String? systemInstruction,
    Uint8List? rawData,
    String mimeType = 'image/jpeg',
    List<Tool>? tools,
  }) async* {
    final messages = _buildMessages(
      prompt,
      systemInstruction,
      rawData,
      mimeType,
    );
    final body = _requestBody(messages, tools)..['stream'] = true;
    try {
      final response = await _client
          .post<ResponseBody>(
            '/chat/completions',
            data: body,
            options: Options(responseType: ResponseType.stream),
          )
          .timeout(_config.timeout);
      final toolCalls = <dynamic>[];
      var yieldedAny = false;
      await for (final chunk in sseJsonObjects(response.data!.stream)) {
        final choices = chunk['choices'] as List?;
        final delta =
            (choices != null && choices.isNotEmpty
                    ? choices.first as Map?
                    : null)?['delta']
                as Map?;
        final content = delta?['content'];
        if (content is String && content.isNotEmpty) {
          yieldedAny = true;
          yield content;
        }
        final deltaCalls = delta?['tool_calls'] as List?;
        if (deltaCalls != null) toolCalls.addAll(deltaCalls);
      }
      if (toolCalls.isNotEmpty) {
        yieldedAny = true;
        yield _mergeToolCallDeltas(toolCalls);
      }
      if (!yieldedAny) {
        throw const LlmException('OpenAI stream returned no content');
      }
    } on TimeoutException catch (e, st) {
      throw LlmTimeoutException(
        'OpenAI request exceeded ${_config.timeout.inSeconds}s',
        cause: e,
        causeStack: st,
      );
    } on DioException catch (e, st) {
      final status = e.response?.statusCode;
      final msg = 'OpenAI call failed: ${e.message} (status $status)';
      if (status == 429) {
        throw LlmRateLimitException(
          msg,
          cause: e,
          causeStack: st,
          retryAfter: _parseRetryAfter(e.response?.headers),
        );
      }
      throw LlmException(msg, cause: e, causeStack: st, statusCode: status);
    } on YaseenAiAgentException {
      rethrow;
    } catch (e, st) {
      throw LlmException('OpenAI stream failed: $e', cause: e, causeStack: st);
    }
  }

  /// Merges streamed `tool_calls` index-deltas into one canonical JSON string.
  String _mergeToolCallDeltas(List<dynamic> deltas) {
    final byIndex = <int, Map<String, dynamic>>{};
    for (final d in deltas) {
      final m = Map<String, dynamic>.from(d as Map);
      final index = (m['index'] as num?)?.toInt() ?? 0;
      final slot = byIndex.putIfAbsent(index, () => <String, dynamic>{});
      final fn = m['function'] as Map?;
      if (fn == null) continue;
      if (fn['name'] != null) slot['name'] = fn['name'].toString();
      slot['arguments'] =
          (slot['arguments'] as String? ?? '') +
          (fn['arguments']?.toString() ?? '');
    }
    return _canonicalToolsJson([
      for (final slot in byIndex.values)
        {
          'function': {
            'name': slot['name'] ?? '',
            'arguments': slot['arguments'] ?? '{}',
          },
        },
    ]);
  }
}
