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
import 'package:yaseen_ai_agent/src/tools/param_spec.dart';
import 'package:yaseen_ai_agent/src/tools/tool.dart';
import 'package:yaseen_ai_agent/src/tools/tool_response.dart';

/// Gated tool: never runs without human approval.
class GatedTool extends Tool {
  bool ran = false;
  Map<String, dynamic>? seenParams;

  GatedTool()
    : super(
        name: 'pay_debt',
        description: 'Pays money. Requires approval.',
        approval: ToolApproval.requireApproval,
        parameters: [
          ParameterSpecification(
            name: 'amount',
            type: 'number',
            description: 'Amount to pay.',
            required: true,
          ),
        ],
      );

  @override
  Future<ToolResponse> run(Map<String, dynamic> params) async {
    ran = true;
    seenParams = params;
    return ToolResponse(
      toolName: name,
      isRequestSuccessful: true,
      message: 'paid ${params['amount']}',
    );
  }
}

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

Future<(Agent, GatedTool)> _agent(List<String> script) async {
  final scope = AgentScope();
  final agent = await Agent.create(
    dataStore: DataStore.inMemory(),
    llm: _ScriptLLM(script),
    name:
        'approval-agent-${script.length}-${DateTime.now().microsecondsSinceEpoch}',
    role: 'test agent',
    systemData: const {},
    scope: scope,
  );
  final tool = GatedTool();
  agent.toolRegistry.registerTool(tool);
  return (agent, tool);
}

void main() {
  group('approval gate', () {
    test('gated tool pauses the turn without executing', () async {
      final (agent, tool) = await _agent([
        '{"tools": ["pay_debt"], "parameters": {"pay_debt": {"amount": 12}}}',
      ]);
      final result = await agent.generate(
        convoId: 'c-pause',
        userMessage: _user('pay my debt'),
      );
      expect(result, isA<AgentPendingResult>());
      final pending = (result as AgentPendingResult).pending;
      expect(pending.toolName, 'pay_debt');
      expect(pending.params, {'amount': 12});
      expect(pending.convoId, 'c-pause');
      expect(tool.ran, isFalse);
      agent.dispose();
    });

    test('approve executes and continues the turn', () async {
      final (agent, tool) = await _agent([
        '{"tools": ["pay_debt"], "parameters": {"pay_debt": {"amount": 12}}}',
        '{"response": "all settled"}',
      ]);
      final paused = await agent.generate(
        convoId: 'c-approve',
        userMessage: _user('pay my debt'),
      );
      final pending = (paused as AgentPendingResult).pending;
      final resumed = await agent.resumeWithApproval(
        pendingId: pending.id,
        approved: true,
      );
      expect(tool.ran, isTrue);
      expect(tool.seenParams, {'amount': 12});
      final message = (resumed as AgentMessageResult).message;
      expect(message.content, 'all settled');
      agent.dispose();
    });

    test('deny skips without side effects', () async {
      final (agent, tool) = await _agent([
        '{"tools": ["pay_debt"], "parameters": {"pay_debt": {"amount": 12}}}',
      ]);
      final paused = await agent.generate(
        convoId: 'c-deny',
        userMessage: _user('pay my debt'),
      );
      final pending = (paused as AgentPendingResult).pending;
      final resumed = await agent.resumeWithApproval(
        pendingId: pending.id,
        approved: false,
      );
      expect(tool.ran, isFalse);
      final message = (resumed as AgentMessageResult).message;
      expect(message.content, contains('skipped'));
      agent.dispose();
    });

    test('edited params replace the proposed ones', () async {
      final (agent, tool) = await _agent([
        '{"tools": ["pay_debt"], "parameters": {"pay_debt": {"amount": 12}}}',
        '{"response": "paid edited"}',
      ]);
      final paused = await agent.generate(
        convoId: 'c-edit',
        userMessage: _user('pay my debt'),
      );
      final pending = (paused as AgentPendingResult).pending;
      await agent.resumeWithApproval(
        pendingId: pending.id,
        approved: true,
        editedParams: {'amount': 5},
      );
      expect(tool.seenParams, {'amount': 5});
      agent.dispose();
    });

    test('unknown approval id throws', () async {
      final (agent, _) = await _agent(['{"response": "hi"}']);
      expect(
        () => agent.resumeWithApproval(pendingId: 'nope', approved: true),
        throwsA(isA<UnknownApprovalException>()),
      );
      agent.dispose();
    });

    test('approval resumes exactly once', () async {
      final (agent, _) = await _agent([
        '{"tools": ["pay_debt"], "parameters": {"pay_debt": {"amount": 1}}}',
        '{"response": "done"}',
      ]);
      final paused = await agent.generate(
        convoId: 'c-once',
        userMessage: _user('pay'),
      );
      final pending = (paused as AgentPendingResult).pending;
      await agent.resumeWithApproval(pendingId: pending.id, approved: false);
      expect(
        () => agent.resumeWithApproval(pendingId: pending.id, approved: true),
        throwsA(isA<UnknownApprovalException>()),
      );
      agent.dispose();
    });
  });
}
