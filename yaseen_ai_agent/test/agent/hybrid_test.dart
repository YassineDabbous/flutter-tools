import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaseen_ai_agent/src/agent/agent.dart';
import 'package:yaseen_ai_agent/src/agent/agent_scope.dart';
import 'package:yaseen_ai_agent/src/llm/llm.dart';
import 'package:yaseen_ai_agent/src/llm/llm_config.dart';
import 'package:yaseen_ai_agent/src/memory/data/agent_message.dart';
import 'package:yaseen_ai_agent/src/memory/data/data_store.dart';
import 'package:yaseen_ai_agent/src/tools/tool.dart';

import '../helpers/fake_dio.dart';

class _FakeLLM extends LLM {
  final bool native;
  final List<String> script;
  int calls = 0;
  List<Tool>? seenTools;
  final List<String> seenPrompts = [];

  _FakeLLM({required this.native, required this.script});

  @override
  bool get supportsNativeTools => native;

  @override
  String get modelId => 'fake';

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
    seenTools = tools;
    seenPrompts.add(prompt);
    return script[calls++ % script.length];
  }
}

AgentMessage _user(String text) => AgentMessage(
  content: text,
  generatedAt: DateTime(2026, 1, 1),
  isFromAgent: false,
);

void main() {
  group('hybrid tool protocol', () {
    test('native LLM receives tools out-of-band', () async {
      final scope = AgentScope();
      final fake = _FakeLLM(
        native: true,
        script: [
          '{"tools": ["spy_tool"], "parameters": {"spy_tool": {"query": "tea"}}}',
          '{"response": "done"}',
        ],
      );
      final agent = await Agent.create(
        dataStore: DataStore.inMemory(),
        llm: fake,
        name: 'native-agent',
        role: 'test agent',
        systemData: const {},
        scope: scope,
      );
      agent.toolRegistry.registerTool(SpyTool());

      final response = await agent.generate(
        convoId: 'c-native',
        userMessage: _user('find tea'),
      );
      expect(response.content, 'done');
      expect(fake.seenTools, isNotNull);
      expect(fake.seenTools!.map((t) => t.name), contains('spy_tool'));
      agent.dispose();
    });

    test('fallback LLM receives full specs in-prompt', () async {
      final scope = AgentScope();
      final fake = _FakeLLM(
        native: false,
        script: [
          '{"tools": ["spy_tool"], "parameters": {"spy_tool": {"query": "tea"}}}',
          '{"response": "done"}',
        ],
      );
      final agent = await Agent.create(
        dataStore: DataStore.inMemory(),
        llm: fake,
        name: 'fallback-agent',
        role: 'test agent',
        systemData: const {},
        scope: scope,
      );
      agent.toolRegistry.registerTool(SpyTool());

      final response = await agent.generate(
        convoId: 'c-fallback',
        userMessage: _user('find tea'),
      );
      expect(response.content, 'done');
      expect(fake.seenTools, isNull);
      expect(fake.seenPrompts.first, contains('Available Tools:'));
      expect(fake.seenPrompts.first, contains('spy_tool'));
      agent.dispose();
    });

    test('deprecated generateResponse delegates to generate', () async {
      final scope = AgentScope();
      final fake = _FakeLLM(native: false, script: ['{"response": "shim ok"}']);
      final agent = await Agent.create(
        dataStore: DataStore.inMemory(),
        llm: fake,
        name: 'shim-agent',
        role: 'test agent',
        systemData: const {},
        scope: scope,
      );
      final response = await agent.generateResponse(
        convoId: 'c-shim',
        userMessage: _user('hi'),
      );
      expect(response.content, 'shim ok');
      agent.dispose();
    });
  });
}
