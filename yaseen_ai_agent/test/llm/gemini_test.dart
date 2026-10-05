import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaseen_ai_agent/src/llm/llm.dart';
import 'package:yaseen_ai_agent/src/static/yaseen_ai_agent_exceptions.dart';

import '../helpers/fake_dio.dart';

Response<dynamic> _ok(RequestOptions options, Map<String, dynamic> json) =>
    Response(requestOptions: options, statusCode: 200, data: json);

void main() {
  group('Gemini provider (Dio REST)', () {
    test('sends key as query param with REST body shape', () async {
      RequestOptions? seen;
      final dio = fakeDio((options) async {
        seen = options;
        return _ok(options, {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': '{"response": "salam"}'},
                ],
              },
            },
          ],
        });
      });
      final llm = LLM.geminiLLM(
        apiKey: 'secret',
        modelName: 'gemini-2.0-flash',
        client: dio,
      );
      expect(llm.supportsNativeTools, isTrue);
      expect(await llm.generate(prompt: 'hi'), '{"response": "salam"}');
      expect(seen!.queryParameters['key'], 'secret');
      expect(seen!.path, contains('gemini-2.0-flash:generateContent'));
      final body = seen!.data as Map;
      expect((body['contents'] as List).single['role'], 'user');
      expect(body['generationConfig'], isA<Map>());
    });

    test('bridges functionCall to canonical JSON', () async {
      final dio = fakeDio(
        (options) async => _ok(options, {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'functionCall': {
                      'name': 'spy_tool',
                      'args': {'query': 'x'},
                    },
                  },
                ],
              },
            },
          ],
        }),
      );
      final llm = LLM.geminiLLM(apiKey: 'k', modelName: 'm', client: dio);
      final decoded =
          json.decode(await llm.generate(prompt: 'search'))
              as Map<String, dynamic>;
      expect(decoded['tools'], ['spy_tool']);
      expect((decoded['parameters'] as Map)['spy_tool'], {'query': 'x'});
    });

    test('blocked prompt throws LlmException', () async {
      final dio = fakeDio(
        (options) async => _ok(options, {
          'promptFeedback': {'blockReason': 'SAFETY'},
          'candidates': [],
        }),
      );
      final llm = LLM.geminiLLM(apiKey: 'k', modelName: 'm', client: dio);
      expect(() => llm.generate(prompt: 'hi'), throwsA(isA<LlmException>()));
    });

    test('maps 429 to LlmRateLimitException', () async {
      final dio = failingDio(
        (options) => DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: 429,
            headers: Headers.fromMap({
              'retry-after': ['3'],
            }),
          ),
        ),
      );
      final llm = LLM.geminiLLM(apiKey: 'k', modelName: 'm', client: dio);
      try {
        await llm.generate(prompt: 'hi');
        fail('expected LlmRateLimitException');
      } on LlmRateLimitException catch (e) {
        expect(e.retryAfter, const Duration(seconds: 3));
      }
    });

    test('stream chunks join to generate() text', () async {
      const sse =
          'data: {"candidates": [{"content": {"parts": [{"text": "sa"}]}}]}\n\n'
          'data: {"candidates": [{"content": {"parts": [{"text": "lam"}]}}]}\n\n'
          'data: [DONE]\n\n';
      final dio = fakeDio((options) async {
        if ((options.data as Map)['stream'] == true ||
            options.path.contains('streamGenerateContent')) {
          return Response(
            requestOptions: options,
            statusCode: 200,
            data: ResponseBody.fromString(
              sse,
              200,
              headers: {
                Headers.contentTypeHeader: ['text/event-stream'],
              },
            ),
          );
        }
        return _ok(options, {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'salam'},
                ],
              },
            },
          ],
        });
      });
      final llm = LLM.geminiLLM(apiKey: 'k', modelName: 'm', client: dio);
      final chunks = await llm.generateStream(prompt: 'hi').toList();
      expect(chunks.length, greaterThanOrEqualTo(2));
      expect(chunks.join(), await llm.generate(prompt: 'hi'));
    });
  });
}
