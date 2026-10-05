// INTERNAL: Changes here affect prompt structure and downstream LLM behaviors.

part of 'agent.dart';

class _PromptBuilder {
  final Map<String, dynamic> systemPrompt;
  final ToolRegistry registry;
  final AgentScope scope;

  /// BCP-47 locale of the conversation (e.g. `ar-TN`), rendered into the
  /// prompt and merged into [systemInstruction].
  final String? locale;

  /// Tool registry version advertised to the model (cache-busting across
  /// assistant releases).
  final String? toolsVersion;

  _PromptBuilder({
    required this.systemPrompt,
    required this.registry,
    required this.scope,
    this.locale,
    this.toolsVersion,
  });

  /// The system instruction block, passed separately via LLM's systemInstruction param.
  String get systemInstruction => json.encode({
    ...systemPrompt,
    if (locale != null && locale!.isNotEmpty) 'locale': locale,
    if (toolsVersion != null && toolsVersion!.isNotEmpty)
      'toolsVersion': toolsVersion,
  });

  String buildTextPrompt({
    List<AgentMessage>? memoryMessages,
    String? contextSummary,
    required AgentMessage userMessage,
    bool isPartOfChain = false,
    String? input,

    /// False in native function-calling mode: full specs travel in the API
    /// payload, so the prompt stays lean. True keeps the JSON-text contract.
    bool includeTools = true,

    /// Soft character budget. The rolling summary is truncated first, then
    /// the oldest history messages are dropped. Tool specs are never cut.
    int maxPromptChars = kMaxPromptChars,
  }) {
    final buffer = StringBuffer();

    // --- Locale (drives answer language + voice wiring upstream) ---
    if (locale != null && locale!.isNotEmpty) {
      buffer.writeln('Conversation locale: $locale\n');
    }
    if (toolsVersion != null && toolsVersion!.isNotEmpty) {
      buffer.writeln('Tool registry version: $toolsVersion\n');
    }

    // --- Agents in scope ---
    if (!isPartOfChain) {
      final agents = _AgentRegistry.instance.getAllAgents(scope: scope);
      if (agents.isNotEmpty) {
        buffer.writeln(
          'Agents in the System: ${agents.map((e) => e.toString()).join(", ")}',
        );
      }
    }

    // --- Rolling summary of evicted history (capped first under budget) ---
    var summary = contextSummary ?? '';
    if (summary.length > kMaxSummaryChars) {
      summary = '${summary.substring(0, kMaxSummaryChars)}…[truncated]';
    }
    if (summary.isNotEmpty) {
      buffer.writeln('Summary of earlier conversation:\n$summary\n');
    }

    // --- Chat history (excludes error messages; oldest dropped under budget) ---
    final historyLines = <String>[];
    if (memoryMessages != null && memoryMessages.isNotEmpty) {
      historyLines.add('Chat History:');
      for (final msg in memoryMessages) {
        if (msg.isError) continue;
        historyLines.add(
          "${msg.isFromAgent ? 'Chatbot' : 'User'}: ${msg.content}",
        );
      }
    }
    final head = buffer.toString();
    final tail = StringBuffer();

    // --- Available tools (as a JSON array, or native in lean mode) ---
    // Never truncated: cutting specs corrupts tool calls before anything else.
    final tools = registry.getAllTools();
    if (tools.isEmpty) {
      tail.writeln('Available Tools: none\n');
    } else if (!includeTools) {
      tail.writeln(
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
      tail.writeln('Available Tools: ${json.encode(toolSpecs)}\n');
    }

    // --- Output format specification ---
    if (!includeTools) {
      tail.writeln('''
Output format — EITHER invoke the provided functions (preferred when a tool
matches), OR reply with ONLY a single JSON object, no prose, no markdown
fences:

{"response": "<your answer>"}''');
    } else {
      tail.writeln(
        '''
Output format — reply with ONLY a single JSON object, no prose, no markdown fences.

If you can answer directly:
{"response": "<your answer>"}

If tools should be used:
{"tools": "<tool_name1>, <tool_name2>", "parameters": {"<tool_name1>": {"<param>": "<value>"}}}''',
      );
    }

    if (!isPartOfChain) {
      tail.writeln('''
If the task requires multiple agents:
{"agents_chain": ["<agent_name1>", "<agent_name2>"]}''');
    }

    // --- Rules ---
    tail.writeln(
      '''

RULES:
1. Check all available tools first. If a tool matches the prompt, output it in the JSON format above.
2. For required tool parameters, deduce them from the prompt and any provided data. Only ask the user for a required parameter if it cannot be deduced at all — explain why you need it in the "response" field.
3. Do NOT ask for optional parameters. Do NOT mention tool names to the user.''',
    );

    if (!isPartOfChain) {
      tail.writeln(
        '4. If the task needs multiple agents, output them as an agents_chain in logical order.\n'
        '5. If no tools or agents apply, generate the response yourself.',
      );
    } else {
      tail.writeln('4. If no tools apply, generate the response yourself.');
    }

    // --- Chain input from previous agent ---
    if (input != null && input.isNotEmpty && isPartOfChain) {
      tail.writeln(
        '\nProvided Data from previous agent (use this to extract parameters '
        'and fulfill the task — do NOT ask the user for additional information):\n$input',
      );
    }

    // --- User prompt (rendered exactly once, never truncated) ---
    tail.writeln('\nUser prompt: ${userMessage.content}');

    // --- Budget fit: drop oldest history lines first (header survives) ---
    final tailText = tail.toString();
    var history = historyLines;
    String render(List<String> lines) =>
        '$head${lines.isEmpty ? '' : '${lines.join("\n")}\n'}$tailText'.trim();
    var rendered = render(history);
    while (history.length > 1 && rendered.length > maxPromptChars) {
      history = [history.first, ...history.sublist(2)];
      rendered = render(history);
    }
    return rendered;
  }
}
