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

/// Gemini LLM implementation over the Generative Language REST API.
///
/// Unlike the OpenAI-compatible providers, Gemini is NOT OpenAI-shaped:
/// the API key travels as a `?key=` query parameter, the body uses
/// `{system_instruction, contents, generationConfig}`, and streaming uses
/// `streamGenerateContent?alt=sse`.
class Gemini extends LLM {
  final String _modelName;
  final String _apiKey;
  final LlmConfig _config;
  final Dio _client;
  final List<Map<String, dynamic>>? _safety;

  /// Creates a Gemini instance with the given API key, model name, and optional config.
  ///
  /// [safetySettings], when a `List<Map<String, dynamic>>`, is forwarded
  /// verbatim as the request `safetySettings` ( HarmCategory/HarmBlockThreshold
  /// maps). Any other type is ignored.
  Gemini({
    required String apiKey,
    required String modelName,
    LlmConfig config = const LlmConfig(),
    Object? safetySettings,
    Dio? client,
    String baseUrl = 'https://generativelanguage.googleapis.com',
  }) : _modelName = modelName,
       _apiKey = apiKey,
       _config = config,
       _safety = safetySettings is List
           ? safetySettings
                 .whereType<Map>()
                 .map((e) => Map<String, dynamic>.from(e))
                 .toList()
           : null,
       _client =
           client ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               connectTimeout: config.timeout,
               receiveTimeout: config.timeout,
               sendTimeout: config.timeout,
               headers: {'Content-Type': 'application/json'},
             ),
           );

  @override
  String get modelId => _modelName;

  @override
  LlmConfig get config => _config;

  @override
  bool get supportsNativeTools => true;

  Map<String, dynamic> _generationConfig() => {
    if (_config.temperature != null) 'temperature': _config.temperature,
    if (_config.maxOutputTokens != null)
      'maxOutputTokens': _config.maxOutputTokens,
    if (_config.topP != null) 'topP': _config.topP,
    if (_config.topK != null) 'topK': _config.topK,
    if (_config.stopSequences != null && _config.stopSequences!.isNotEmpty)
      'stopSequences': _config.stopSequences,
    if (_config.jsonMode) 'responseMimeType': 'application/json',
  };

  Map<String, dynamic> _requestBody(
    String prompt,
    String? systemInstruction,
    Uint8List? rawData,
    String mimeType,
    List<Tool>? tools,
  ) {
    final userParts = <Map<String, dynamic>>[
      {'text': prompt},
      if (rawData != null)
        {
          'inlineData': {'mimeType': mimeType, 'data': base64Encode(rawData)},
        },
    ];
    return {
      if (systemInstruction != null)
        'system_instruction': {
          'parts': [
            {'text': systemInstruction},
          ],
        },
      'contents': [
        {'role': 'user', 'parts': userParts},
      ],
      'generationConfig': _generationConfig(),
      if (_safety != null) 'safetySettings': _safety,
      if (tools != null && tools.isNotEmpty)
        'tools': [
          {
            'functionDeclarations': [
              for (final t in tools) geminiToolSchema(t),
            ],
          },
        ],
    };
  }

  String _path(String action) => '/v1beta/models/$_modelName:$action';

  Map<String, dynamic> _query({bool stream = false}) => {
    'key': _apiKey,
    if (stream) 'alt': 'sse',
  };

  @override
  Future<String> generate({
    required String prompt,
    String? systemInstruction,
    Uint8List? rawData,
    String mimeType = 'image/jpeg',
    List<Tool>? tools,
  }) async {
    try {
      final response = await _client
          .post(
            _path('generateContent'),
            queryParameters: _query(),
            data: _requestBody(
              prompt,
              systemInstruction,
              rawData,
              mimeType,
              tools,
            ),
          )
          .timeout(_config.timeout);
      return _extractText(response.data);
    } on TimeoutException catch (e, st) {
      throw LlmTimeoutException(
        'Gemini request exceeded ${_config.timeout.inSeconds}s',
        cause: e,
        causeStack: st,
      );
    } on DioException catch (e, st) {
      throw _mapDio(e, st);
    } on YaseenAiAgentException {
      rethrow;
    } catch (e, st) {
      throw LlmException('Gemini call failed: $e', cause: e, causeStack: st);
    }
  }

  @override
  Stream<String> generateStream({
    required String prompt,
    String? systemInstruction,
    Uint8List? rawData,
    String mimeType = 'image/jpeg',
    List<Tool>? tools,
  }) async* {
    try {
      final response = await _client
          .post<ResponseBody>(
            _path('streamGenerateContent'),
            queryParameters: _query(stream: true),
            data: _requestBody(
              prompt,
              systemInstruction,
              rawData,
              mimeType,
              tools,
            ),
            options: Options(responseType: ResponseType.stream),
          )
          .timeout(_config.timeout);
      var yieldedAny = false;
      await for (final chunk in sseJsonObjects(response.data!.stream)) {
        final text = _chunkText(chunk);
        if (text != null && text.isNotEmpty) {
          yieldedAny = true;
          yield text;
        }
        final call = _chunkFunctionCall(chunk);
        if (call != null) {
          yieldedAny = true;
          yield json.encode({
            'tools': [call.$1],
            'parameters': {call.$1: call.$2},
          });
        }
      }
      if (!yieldedAny) {
        throw const LlmException('Gemini stream returned no content');
      }
    } on TimeoutException catch (e, st) {
      throw LlmTimeoutException(
        'Gemini request exceeded ${_config.timeout.inSeconds}s',
        cause: e,
        causeStack: st,
      );
    } on DioException catch (e, st) {
      throw _mapDio(e, st);
    } on YaseenAiAgentException {
      rethrow;
    } catch (e, st) {
      throw LlmException('Gemini stream failed: $e', cause: e, causeStack: st);
    }
  }

  YaseenAiAgentException _mapDio(DioException e, StackTrace st) {
    final status = e.response?.statusCode;
    final msg = 'Gemini call failed: ${e.message} (status $status)';
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

  Duration? _parseRetryAfter(Headers? headers) {
    final value = headers?.value('retry-after');
    if (value == null) return null;
    final seconds = int.tryParse(value.trim());
    return seconds != null ? Duration(seconds: seconds) : null;
  }

  /// Extracts text — or bridges a native `functionCall` into the canonical
  /// JSON-text contract — from a `generateContent` response.
  String _extractText(dynamic data) {
    try {
      final map = data as Map?;
      final blockReason = (map?['promptFeedback'] as Map?)?['blockReason']
          ?.toString();
      if (blockReason != null &&
          blockReason.isNotEmpty &&
          blockReason != 'BLOCK_REASON_UNSPECIFIED') {
        throw LlmException('Gemini blocked the prompt ($blockReason)');
      }
      final candidates = map?['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw const LlmException('Gemini returned no candidates');
      }
      final parts =
          ((candidates.first as Map)['content'] as Map?)?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw const LlmException(
          'Gemini returned empty response (possible safety block)',
        );
      }
      for (final part in parts) {
        final call = (part as Map)['functionCall'] as Map?;
        if (call != null) {
          final name = call['name']?.toString() ?? '';
          final args = call['args'] is Map
              ? Map<String, dynamic>.from(call['args'] as Map)
              : <String, dynamic>{};
          return json.encode({
            'tools': [name],
            'parameters': {name: args},
          });
        }
      }
      final text = parts
          .map((p) => (p as Map)['text']?.toString() ?? '')
          .join();
      if (text.isEmpty) {
        throw const LlmException(
          'Gemini returned empty response (possible safety block)',
        );
      }
      return text;
    } on YaseenAiAgentException {
      rethrow;
    } catch (e, st) {
      throw LlmException(
        'Failed to parse Gemini response: $e',
        cause: e,
        causeStack: st,
      );
    }
  }

  String? _chunkText(Map<String, dynamic> chunk) {
    try {
      final candidates = chunk['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return null;
      final parts =
          ((candidates.first as Map)['content'] as Map?)?['parts'] as List?;
      if (parts == null) return null;
      final text = parts
          .map((p) => (p as Map)['text']?.toString() ?? '')
          .join();
      return text.isEmpty ? null : text;
    } catch (_) {
      return null;
    }
  }

  (String, Map<String, dynamic>)? _chunkFunctionCall(
    Map<String, dynamic> chunk,
  ) {
    try {
      final candidates = chunk['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return null;
      final parts =
          ((candidates.first as Map)['content'] as Map?)?['parts'] as List?;
      if (parts == null) return null;
      for (final part in parts) {
        final call = (part as Map)['functionCall'] as Map?;
        if (call != null) {
          return (
            call['name']?.toString() ?? '',
            call['args'] is Map
                ? Map<String, dynamic>.from(call['args'] as Map)
                : <String, dynamic>{},
          );
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
