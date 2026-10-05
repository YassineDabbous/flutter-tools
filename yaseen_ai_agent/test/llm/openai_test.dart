import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaseen_ai_agent/src/llm/llm.dart';
import 'package:yaseen_ai_agent/src/static/yaseen_ai_agent_exceptions.dart';
import 'package:yaseen_ai_agent/src/tools/param_spec.dart';
import 'package:yaseen_ai_agent/src/tools/tool.dart';
import 'package:yaseen_ai_agent/src/tools/tool_response.dart';

import '../helpers/fake_dio.dart';

class _EchoTool extends Tool {
  _EchoTool()
    : super(
        name: 'echo_tool',
        description: 'Echoes text back.',
        parameters: [
          ParameterSpecification(
            name: 'text',
            type: 'string',
            description: 'Text to echo.',
            required: true,
          ),
          ParameterSpecification(
            name: 'mode',
            type: 'string',
            description: 'Echo mode.',
            enumValues: ['upper', 'lower'],
          ),
        ],
      );

  @override
  Future<ToolResponse> run(Map<String, dynamic> params) async => ToolResponse(
    toolName: name,
    isRequestSuccessful: true,
    message: '${params['text']}',
  );
}

Response<dynamic> _ok(RequestOptions options, Map<String, dynamic> json) =>
    Response(requestOptions: options, statusCode: 200, data: json);

void main() {
  group('OpenAI provider', () {
    test('returns text content', () async {
      final dio = fakeDio(
        (options) async => _ok(options, {
          'choices': [
            {
              'message': {'content': '{"response": "hello"}'},
            },
          ],
        }),
      );
      final llm = LLM.openAiLLM(
        apiKey: 'k',
        modelName: 'gpt-4o-mini',
        client: dio,
      );
      expect(llm.supportsNativeTools, isTrue);
      expect(await llm.generate(prompt: 'hi'), '{"response": "hello"}');
    });

    test('bridges native tool_calls to canonical JSON', () async {
      Map<String, dynamic>? seenBody;
      final dio = fakeDio((options) async {
        seenBody = Map<String, dynamic>.from(options.data as Map);
        return _ok(options, {
          'choices': [
            {
              'message': {
                'tool_calls': [
                  {
                    'function': {
                      'name': 'echo_tool',
                      'arguments': '{"text": "hi"}',
                    },
                  },
                ],
              },
            },
          ],
        });
      });
      final llm = LLM.openAiLLM(
        apiKey: 'k',
        modelName: 'gpt-4o-mini',
        client: dio,
      );
      final raw = await llm.generate(prompt: 'echo', tools: [_EchoTool()]);
      final decoded = json.decode(raw) as Map<String, dynamic>;
      expect(decoded['tools'], ['echo_tool']);
      expect((decoded['parameters'] as Map)['echo_tool'], {'text': 'hi'});
      // Native payload carries schemas; json_object mode is off.
      final sentTools = seenBody!['tools'] as List;
      expect(sentTools, hasLength(1));
      expect(seenBody, isNot(contains('response_format')));
      final fn = (sentTools.first as Map)['function'] as Map;
      expect(fn['name'], 'echo_tool');
      expect(((fn['parameters'] as Map)['required'] as List), contains('text'));
    });

    test('maps 429 to LlmRateLimitException with retryAfter', () async {
      final dio = failingDio(
        (options) => DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: 429,
            headers: Headers.fromMap({
              'retry-after': ['7'],
            }),
          ),
        ),
      );
      final llm = LLM.openAiLLM(
        apiKey: 'k',
        modelName: 'gpt-4o-mini',
        client: dio,
      );
      try {
        await llm.generate(prompt: 'hi');
        fail('expected LlmRateLimitException');
      } on LlmRateLimitException catch (e) {
        expect(e.retryAfter, const Duration(seconds: 7));
      }
    });

    test('empty choices throw LlmException', () async {
      final dio = fakeDio(
        (options) async => _ok(options, {'choices': <dynamic>[]}),
      );
      final llm = LLM.openAiLLM(
        apiKey: 'k',
        modelName: 'gpt-4o-mini',
        client: dio,
      );
      expect(() => llm.generate(prompt: 'hi'), throwsA(isA<LlmException>()));
    });

    test('stream chunks join to generate() text', () async {
      const sse =
          'data: {"choices": [{"delta": {"content": "Hel"}}]}\n\n'
          'data: {"choices": [{"delta": {"content": "lo"}}]}\n\n'
          'data: [DONE]\n\n';
      final dio = fakeDio((options) async {
        final isStream = (options.data as Map)['stream'] == true;
        if (isStream) {
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
          'choices': [
            {
              'message': {'content': 'Hello'},
            },
          ],
        });
      });
      final llm = LLM.openAiLLM(
        apiKey: 'k',
        modelName: 'gpt-4o-mini',
        client: dio,
      );
      final chunks = await llm.generateStream(prompt: 'hi').toList();
      expect(chunks.length, greaterThanOrEqualTo(2));
      expect(chunks.join(), await llm.generate(prompt: 'hi'));
    });
  });
}
