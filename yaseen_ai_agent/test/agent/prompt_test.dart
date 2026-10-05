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

class _CapturingLLM extends LLM {
  final bool native;
  final String reply;
  String? seenPrompt;
  String? seenSystem;

  _CapturingLLM({required this.native, required this.reply});

  @override
  bool get supportsNativeTools => native;

  @override
  String get modelId => 'capturing';

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
    seenPrompt = prompt;
    seenSystem = systemInstruction;
    return reply;
  }
}

AgentMessage _msg(String text, {bool agent = false}) => AgentMessage(
  content: text,
  generatedAt: DateTime(2026, 1, 1),
  isFromAgent: agent,
);

void main() {
  group('prompt builder', () {
    test('locale and toolsVersion render in prompt and instruction', () async {
      final llm = _CapturingLLM(native: false, reply: '{"response": "ok"}');
      final agent = await Agent.create(
        dataStore: DataStore.inMemory(),
        llm: llm,
        name: 'locale-agent',
        role: 'test agent',
        systemData: const {'tone': 'brief'},
        locale: 'ar-TN',
        toolsVersion: 'v3',
        scope: AgentScope(),
      );
      await agent.generate(convoId: 'c-locale', userMessage: _msg('hi'));
      expect(llm.seenPrompt, contains('Conversation locale: ar-TN'));
      expect(llm.seenPrompt, contains('Tool registry version: v3'));
      expect(llm.seenSystem, contains('"tone":"brief"'));
      expect(llm.seenSystem, contains('"locale":"ar-TN"'));
      expect(llm.seenSystem, contains('"toolsVersion":"v3"'));
      agent.dispose();
    });

    test('inline systemData never touches the asset bundle', () async {
      // Under plain test() there is no asset bundle: any rootBundle access
      // would throw. Passing here proves the pure-Dart path.
      final llm = _CapturingLLM(native: false, reply: '{"response": "pure"}');
      final agent = await Agent.create(
        dataStore: DataStore.inMemory(),
        llm: llm,
        name: 'pure-agent',
        role: 'test agent',
        systemData: const {'app': 'rebelo'},
        scope: AgentScope(),
      );
      final result = await agent.generate(
        convoId: 'c-pure',
        userMessage: _msg('hi'),
      );
      expect(((result as AgentMessageResult).message).content, 'pure');
      agent.dispose();
    });

    test('native prompt stays lean, fallback carries full specs', () async {
      final nativeLLM = _CapturingLLM(native: true, reply: '{"response": "n"}');
      final fallbackLLM = _CapturingLLM(
        native: false,
        reply: '{"response": "f"}',
      );
      Future<Agent> agentFor(_CapturingLLM llm, String name) => Agent.create(
        dataStore: DataStore.inMemory(),
        llm: llm,
        name: name,
        role: 'test agent',
        systemData: const {},
        scope: AgentScope(),
      );
      final nativeAgent = await agentFor(nativeLLM, 'snap-native');
      nativeAgent.toolRegistry.registerTool(SpyTool());
      await nativeAgent.generate(convoId: 'c1', userMessage: _msg('hi'));
      final fallbackAgent = await agentFor(fallbackLLM, 'snap-fallback');
      fallbackAgent.toolRegistry.registerTool(SpyTool());
      await fallbackAgent.generate(convoId: 'c2', userMessage: _msg('hi'));

      expect(nativeLLM.seenPrompt, contains('provided natively'));
      expect(nativeLLM.seenPrompt, isNot(contains('"parameters"')));
      expect(fallbackLLM.seenPrompt, contains('"parameters"'));
      expect(fallbackLLM.seenPrompt, contains('spy_tool'));
      nativeAgent.dispose();
      fallbackAgent.dispose();
    });

    test('long history is trimmed oldest-first under budget', () async {
      final store = DataStore.inMemory();
      for (var i = 0; i < 40; i++) {
        await store.saveMessage('c-trim', _msg('MSG-$i-${'x' * 500}'));
      }
      final llm = _CapturingLLM(
        native: false,
        reply: '{"response": "trimmed"}',
      );
      final agent = await Agent.create(
        dataStore: store,
        llm: llm,
        name: 'trim-agent',
        role: 'test agent',
        systemData: const {},
        scope: AgentScope(),
      );
      await agent.generate(
        convoId: 'c-trim',
        userMessage: _msg('latest question'),
        memoryLimit: 50,
      );
      final prompt = llm.seenPrompt!;
      expect(prompt.length, lessThanOrEqualTo(12000));
      expect(prompt, contains('MSG-39'));
      expect(prompt, isNot(contains('MSG-0-')));
      expect(prompt, contains('latest question'));
      agent.dispose();
    });
  });
}
