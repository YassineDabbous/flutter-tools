import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaseen_ai_agent/src/llm/llm.dart';

import '../helpers/fake_dio.dart';

void main() {
  group('Ollama provider', () {
    test('uses fallback path and delegates transport', () async {
      RequestOptions? seen;
      final dio = fakeDio((options) async {
        seen = options;
        return Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'choices': [
              {
                'message': {'content': '{"response": "local hi"}'},
              },
            ],
          },
        );
      });
      final llm = LLM.ollamaLLM(modelName: 'llama3.1:8b', client: dio);
      expect(llm.supportsNativeTools, isFalse);
      expect(llm.modelId, 'llama3.1:8b');
      expect(await llm.generate(prompt: 'hi'), '{"response": "local hi"}');
      expect(seen!.path, contains('/chat/completions'));
      // jsonMode is forced off for weak local models.
      expect(llm.config.jsonMode, isFalse);
    });

    test('local defaults: long timeout, jsonMode off', () {
      final llm = LLM.ollamaLLM(
        modelName: 'llama3.1:8b',
        client: fakeDio((options) async {
          return Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'choices': [
                {
                  'message': {'content': 'ok'},
                },
              ],
            },
          );
        }),
      );
      // Weak local models get repair retries, not strict json_object mode,
      // and twice the wall-clock budget of cloud providers.
      expect(llm.config.timeout, const Duration(seconds: 120));
      expect(llm.config.jsonMode, isFalse);
    });
  });
}
