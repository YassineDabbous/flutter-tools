import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaseen_ai_agent/src/agent/agent.dart';
import 'package:yaseen_ai_agent/src/agent/agent_result.dart';
import 'package:yaseen_ai_agent/src/agent/agent_scope.dart';
import 'package:yaseen_ai_agent/src/llm/llm.dart';
import 'package:yaseen_ai_agent/src/llm/llm_config.dart';
import 'package:yaseen_ai_agent/src/memory/data/agent_message.dart';
import 'package:yaseen_ai_agent/src/memory/data/data_store.dart';
import 'package:yaseen_ai_agent/src/tools/tool.dart';

import '../helpers/fake_dio.dart';

class _ScriptLLM extends LLM {
  final List<String> script;
  int calls = 0;

  _ScriptLLM(this.script);

  @override
  bool get supportsNativeTools => false;

  @override
  String get modelId => 'script';

  @override
  LlmConfig get config => const LlmConfig();

  @override
  Future<String> generate({
    required String prompt,
    String? systemInstruction,
    Uint8List? rawData,
    String mimeType = 'image/jpeg',
    List<Tool>? tools,
  }) async => script[calls++ % script.length];
}

AgentMessage _user(String text) => AgentMessage(
  content: text,
  generatedAt: DateTime(2026, 1, 1),
  isFromAgent: false,
);

Future<Agent> _agent(_ScriptLLM llm, String name) async {
  final agent = await Agent.create(
    dataStore: DataStore.inMemory(),
    llm: llm,
    name: name,
    role: 'test agent',
    systemData: const {},
    scope: AgentScope(),
  );
  agent.toolRegistry.registerTool(SpyTool());
  return agent;
}

void main() {
  group('validation retry', () {
    test('empty params retry with correction, then execute', () async {
      final llm = _ScriptLLM([
        '{"tools": ["spy_tool"], "parameters": {"spy_tool": {}}}',
        '{"tools": ["spy_tool"], "parameters": {"spy_tool": {"query": "tea"}}}',
        '{"response": "found it"}',
      ]);
      final agent = await _agent(llm, 'retry-agent');
      final result = await agent.generate(
        convoId: 'c-retry',
        userMessage: _user('find tea'),
      );
      final message = (result as AgentMessageResult).message;
      expect(message.content, 'found it');
      // Initial bad call + corrected call + final answer.
      expect(llm.calls, 3);
      agent.dispose();
    });

    test('stubborn model is bounded, never throws', () async {
      final llm = _ScriptLLM([
        '{"tools": ["spy_tool"], "parameters": {"spy_tool": {}}}',
      ]);
      final agent = await _agent(llm, 'stubborn-agent');
      final result = await agent.generate(
        convoId: 'c-stubborn',
        userMessage: _user('find tea'),
      );
      final message = (result as AgentMessageResult).message;
      // No observation ever succeeded: the joined framework correction
      // messages surface (user-safe, no raw backend text), not an exception.
      expect(message.content, contains('Parameter error'));
      expect(message.content, isNot(contains('unable to process')));
      // One LLM call per loop iteration, then the loop cap stops it.
      expect(llm.calls, 5);
      agent.dispose();
    });
  });
}
