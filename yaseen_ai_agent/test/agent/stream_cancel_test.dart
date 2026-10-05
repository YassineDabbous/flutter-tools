import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaseen_ai_agent/src/agent/agent.dart';
import 'package:yaseen_ai_agent/src/agent/agent_result.dart';
import 'package:yaseen_ai_agent/src/agent/agent_scope.dart';
import 'package:yaseen_ai_agent/src/llm/llm.dart';
import 'package:yaseen_ai_agent/src/llm/llm_config.dart';
import 'package:yaseen_ai_agent/src/memory/data/agent_message.dart';
import 'package:yaseen_ai_agent/src/memory/data/data_store.dart';
import 'package:yaseen_ai_agent/src/static/yaseen_ai_agent_exceptions.dart';
import 'package:yaseen_ai_agent/src/tools/_parser.dart';
import 'package:yaseen_ai_agent/src/tools/_tool_runner.dart';
import 'package:yaseen_ai_agent/src/tools/tool.dart';
import 'package:yaseen_ai_agent/src/tools/tool_context.dart';
import 'package:yaseen_ai_agent/src/tools/tool_registry.dart';

import '../helpers/fake_dio.dart';

class _ChunkedLLM extends LLM {
  final List<String> chunks;
  final String full;
  int generateCalls = 0;

  _ChunkedLLM({required this.chunks, required this.full});

  @override
  bool get supportsNativeTools => false;

  @override
  String get modelId => 'chunked';

  @override
  LlmConfig get config => const LlmConfig();

  @override
  Future<String> generate({
    required String prompt,
    String? systemInstruction,
    Uint8List? rawData,
    String mimeType = 'image/jpeg',
    List<Tool>? tools,
  }) async {
    generateCalls++;
    return full;
  }

  @override
  Stream<String> generateStream({
    required String prompt,
    String? systemInstruction,
    Uint8List? rawData,
    String mimeType = 'image/jpeg',
    List<Tool>? tools,
  }) async* {
    for (final chunk in chunks) {
      yield chunk;
    }
  }
}

AgentMessage _user(String text) => AgentMessage(
  content: text,
  generatedAt: DateTime(2026, 1, 1),
  isFromAgent: false,
);

void main() {
  group('streaming + cancellation', () {
    test('deltas precede the terminal chunk', () async {
      final scope = AgentScope();
      final agent = await Agent.create(
        dataStore: DataStore.inMemory(),
        llm: _ChunkedLLM(
          chunks: ['{"respon', 'se": "Hello"}'],
          full: '{"response": "Hello"}',
        ),
        name: 'stream-agent',
        role: 'test agent',
        systemData: const {},
        scope: scope,
      );
      final chunks = await agent
          .generateStream(convoId: 'c-stream', userMessage: _user('hi'))
          .toList();
      expect(chunks, hasLength(3));
      expect((chunks[0] as AgentTextChunk).delta, '{"respon');
      expect((chunks[1] as AgentTextChunk).delta, 'se": "Hello"}');
      final terminal = (chunks[2] as AgentDoneChunk).result;
      expect(((terminal as AgentMessageResult).message).content, 'Hello');
      agent.dispose();
    });

    test('pre-cancelled token stops before the first LLM call', () async {
      final scope = AgentScope();
      final llm = _ChunkedLLM(chunks: ['x'], full: '{"response": "x"}');
      final agent = await Agent.create(
        dataStore: DataStore.inMemory(),
        llm: llm,
        name: 'cancel-agent',
        role: 'test agent',
        systemData: const {},
        scope: scope,
      );
      final token = CancellationToken.cancelled();
      final result = await agent.generate(
        convoId: 'c-cancel',
        userMessage: _user('hi'),
        cancelToken: token,
      );
      final message = (result as AgentMessageResult).message;
      expect(message.isError, isTrue);
      expect(message.content, contains('cancelled'));
      expect(llm.generateCalls, 0);
      agent.dispose();
    });

    test('ToolRunner throws CancelledException when cancelled', () async {
      final registry = ToolRegistry()..registerTool(SpyTool());
      final runner = ToolRunner();
      expect(
        () => runner.runTools(
          PromptParserResult(
            outcome: ParseOutcome.tools,
            agentNames: const [],
            toolNames: const ['spy_tool'],
            params: const {
              'spy_tool': {'query': 'q'},
            },
          ),
          registry,
          context: ToolContext(cancelToken: CancellationToken.cancelled()),
        ),
        throwsA(isA<CancelledException>()),
      );
    });
  });
}
