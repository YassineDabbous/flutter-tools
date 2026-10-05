// INTERNAL: Changes here affect prompt structure and downstream LLM behaviors.

part of 'agent.dart';

class _PromptBuilder {
  final Map<String, dynamic> systemPrompt;
  final ToolRegistry registry;
  final AgentScope scope;

  _PromptBuilder({
    required this.systemPrompt,
    required this.registry,
    required this.scope,
  });

  /// The system instruction block, passed separately via LLM's systemInstruction param.
  String get systemInstruction => json.encode(systemPrompt);

  String buildTextPrompt({
    List<AgentMessage>? memoryMessages,
    String? contextSummary,
    required AgentMessage userMessage,
    bool isPartOfChain = false,
    String? input,

    /// False in native function-calling mode: full specs travel in the API
    /// payload, so the prompt stays lean. True keeps the JSON-text contract.
    bool includeTools = true,
  }) {
    final buffer = StringBuffer();

    // --- Agents in scope ---
    if (!isPartOfChain) {
      final agents = _AgentRegistry.instance.getAllAgents(scope: scope);
      if (agents.isNotEmpty) {
        buffer.writeln(
          'Agents in the System: ${agents.map((e) => e.toString()).join(", ")}',
        );
      }
    }

    // --- Rolling summary of evicted history (rendered before recent messages) ---
    if (contextSummary != null && contextSummary.isNotEmpty) {
      buffer.writeln('Summary of earlier conversation:\n$contextSummary\n');
    }

    // --- Chat history (excludes error messages) ---
    if (memoryMessages != null && memoryMessages.isNotEmpty) {
      buffer.writeln('Chat History:');
      for (final msg in memoryMessages) {
        if (msg.isError) continue;
        buffer.writeln(
          "${msg.isFromAgent ? 'Chatbot' : 'User'}: ${msg.content}",
        );
      }
    }
    // --- Available tools (as a JSON array, or native in lean mode) ---
    final tools = registry.getAllTools();
    if (tools.isEmpty) {
      buffer.writeln('Available Tools: none\n');
    } else if (!includeTools) {
      buffer.writeln(
        'Available Tools: ${tools.map((t) => t.name).join(", ")} '
        '(provided natively — invoke them via function calling with exact '
        'parameter names; never invent tool names)\n',
      );
    } else {
      final toolSpecs = tools
          .map(
            (tool) => {
              'name': tool.name,
              'description': tool.description,
              'parameters': tool.parameters.map((e) => e.toJson()).toList(),
            },
          )
          .toList();
      buffer.writeln('Available Tools: ${json.encode(toolSpecs)}\n');
    }

    // --- Output format specification ---
    if (!includeTools) {
      buffer.writeln('''
Output format — EITHER invoke the provided functions (preferred when a tool
matches), OR reply with ONLY a single JSON object, no prose, no markdown
fences:

{"response": "<your answer>"}''');
    } else {
      buffer.writeln(
        '''
Output format — reply with ONLY a single JSON object, no prose, no markdown fences.

If you can answer directly:
{"response": "<your answer>"}

If tools should be used:
{"tools": "<tool_name1>, <tool_name2>", "parameters": {"<tool_name1>": {"<param>": "<value>"}}}''',
      );
    }

    if (!isPartOfChain) {
      buffer.writeln('''
If the task requires multiple agents:
{"agents_chain": ["<agent_name1>", "<agent_name2>"]}''');
    }

    // --- Rules ---
    buffer.writeln(
      '''

RULES:
1. Check all available tools first. If a tool matches the prompt, output it in the JSON format above.
2. For required tool parameters, deduce them from the prompt and any provided data. Only ask the user for a required parameter if it cannot be deduced at all — explain why you need it in the "response" field.
3. Do NOT ask for optional parameters. Do NOT mention tool names to the user.''',
    );

    if (!isPartOfChain) {
      buffer.writeln(
        '4. If the task needs multiple agents, output them as an agents_chain in logical order.\n'
        '5. If no tools or agents apply, generate the response yourself.',
      );
    } else {
      buffer.writeln('4. If no tools apply, generate the response yourself.');
    }

    // --- Chain input from previous agent ---
    if (input != null && input.isNotEmpty && isPartOfChain) {
      buffer.writeln(
        '\nProvided Data from previous agent (use this to extract parameters '
        'and fulfill the task — do NOT ask the user for additional information):\n$input',
      );
    }

    // --- User prompt (rendered exactly once) ---
    buffer.writeln('\nUser prompt: ${userMessage.content}');

    return buffer.toString().trim();
  }
}
