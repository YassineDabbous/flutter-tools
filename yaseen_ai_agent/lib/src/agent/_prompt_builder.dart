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

  /// JSON-text fallback contract (weak models, native-tools off).
  static const _kFormatFallback = '''
Output format — reply with ONLY a single JSON object, no prose, no markdown fences.

If you can answer directly:
{"response": "<your answer>"}

If tools should be used:
{"tools": "<tool_name1>, <tool_name2>", "parameters": {"<tool_name1>": {"<param>": "<value>"}}}

Worked example — user says "navigate to orders" and a tool named "navigate"
takes a required "routeKey":
{"tools": ["navigate"], "parameters": {"navigate": {"routeKey": "orders"}}}

Copy the shape exactly: "tools" is a list of names, "parameters" maps each
name to its own params object, every required parameter present.''';

  /// Lean contract for native function-calling providers.
  static const _kFormatNative = '''
Output format — EITHER invoke the provided functions (preferred when a tool
matches), OR reply with ONLY a single JSON object, no prose, no markdown
fences:

{"response": "<your answer>"}''';

  static const _kChainHint = '''
If the task requires multiple agents:
{"agents_chain": ["<agent_name1>", "<agent_name2>"]}''';

  static const _kRules = '''

RULES:
1. Check all available tools first. If a tool matches the prompt, output it in the JSON format above.
2. For required tool parameters, deduce them from the prompt and any provided data. Only ask the user for a required parameter if it cannot be deduced at all — explain why you need it in the "response" field.
3. Do NOT ask for optional parameters. Do NOT mention tool names to the user.''';

  /// Head section shared by the text and wire builders: locale, registry
  /// version, agents in scope, rolling summary, and — for the JSON-text
  /// contract — the output format block.
  String _headString({
    required String? contextSummary,
    required bool includeTools,
    required bool isPartOfChain,
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

    if (includeTools) {
      buffer.writeln(_kFormatFallback);
    }
    return buffer.toString();
  }

  /// Middle section shared by the text and wire builders: tool specs,
  /// native-contract format block, chain hint, and rules. Never truncated:
  /// cutting specs corrupts tool calls before anything else.
  String _middleString({
    required bool includeTools,
    required bool isPartOfChain,
  }) {
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

    // --- Output format specification (native-contract variant) ---
    if (!includeTools) {
      tail.writeln(_kFormatNative);
    }

    if (!isPartOfChain) {
      tail.writeln(_kChainHint);
    }

    // --- Rules ---
    tail.writeln(_kRules);

    if (!isPartOfChain) {
      tail.writeln(
        '4. If the task needs multiple agents, output them as an agents_chain in logical order.\n'
        '5. If no tools or agents apply, generate the response yourself.',
      );
    } else {
      tail.writeln('4. If no tools apply, generate the response yourself.');
    }
    return tail.toString();
  }

  /// Final user section: chained-agent input plus the user prompt itself,
  /// rendered exactly once and never truncated.
  String _userTailString({
    required String? input,
    required bool isPartOfChain,
    required String userContent,
  }) {
    final tail = StringBuffer();

    // --- Chain input from previous agent ---
    if (input != null && input.isNotEmpty && isPartOfChain) {
      tail.writeln(
        '\nProvided Data from previous agent (use this to extract parameters '
        'and fulfill the task — do NOT ask the user for additional information):\n$input',
      );
    }

    // --- User prompt (rendered exactly once, never truncated) ---
    tail.writeln('\nUser prompt: $userContent');
    return tail.toString();
  }

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
    final head = _headString(
      contextSummary: contextSummary,
      includeTools: includeTools,
      isPartOfChain: isPartOfChain,
    );

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
    final tailText =
        _middleString(
          includeTools: includeTools,
          isPartOfChain: isPartOfChain,
        ) +
        _userTailString(
          input: input,
          isPartOfChain: isPartOfChain,
          userContent: userMessage.content,
        );

    // --- Budget fit: drop oldest history lines first (header survives) ---
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

  /// Builds the structured tail (final user message content) for wire
  /// providers: chain input plus the user prompt. [extra] carries the
  /// per-step suffix — tool observations or the parse-retry instruction.
  String buildStructuredTail({
    String? input,
    bool isPartOfChain = false,
    required String userContent,
    String extra = '',
  }) =>
      (_userTailString(
                input: input,
                isPartOfChain: isPartOfChain,
                userContent: userContent,
              ) +
              extra)
          .trim();

  /// Assembles backend-ready `role`/`content` messages for structured
  /// providers (see the Rebelo AI proxy contract): system instruction plus
  /// head/middle blocks as `system` messages, recent history as
  /// `user`/`assistant` messages, [tail] as the final `user` message.
  ///
  /// Enforces the wire limits — at most [kWireMaxMessages] messages, at most
  /// [kWireMaxChars] characters per message:
  /// - system text is chunked at line boundaries (nothing is lost; models
  ///   concatenate consecutive system messages);
  /// - oldest history drops first to fit the count;
  /// - oversized `user`/`assistant` content (history or [tail]) throws
  ///   [ConfigException] before any HTTP call — loud in dev logs instead of
  ///   a server 422 or a silent cut.
  List<Map<String, String>> buildWireMessages({
    List<AgentMessage>? memoryMessages,
    String? contextSummary,
    required String systemInstruction,
    required String tail,
    bool isPartOfChain = false,
    bool includeTools = true,
  }) {
    final system =
        '$systemInstruction\n\n${_headString(contextSummary: contextSummary, includeTools: includeTools, isPartOfChain: isPartOfChain)}${_middleString(includeTools: includeTools, isPartOfChain: isPartOfChain)}';
    final systemChunks = _chunkText(system.trim());

    final history = <Map<String, String>>[];
    if (memoryMessages != null && memoryMessages.isNotEmpty) {
      for (final msg in memoryMessages) {
        if (msg.isError) continue;
        if (msg.content.length > kWireMaxChars) {
          throw ConfigException(
            'Wire history message exceeds $kWireMaxChars chars '
            '(${msg.content.length}); trim client-side before sending.',
          );
        }
        history.add({
          'role': msg.isFromAgent ? 'assistant' : 'user',
          'content': msg.content,
        });
      }
    }
    if (tail.length > kWireMaxChars) {
      throw ConfigException(
        'Wire tail message exceeds $kWireMaxChars chars (${tail.length}); '
        'trim client-side before sending.',
      );
    }

    // Oldest history drops first so system chunks + history + final user
    // always fit the count cap.
    final maxHistory = kWireMaxMessages - systemChunks.length - 1;
    final kept = maxHistory <= 0
        ? <Map<String, String>>[]
        : history.length <= maxHistory
        ? history
        : history.sublist(history.length - maxHistory);
    return [
      for (final chunk in systemChunks) {'role': 'system', 'content': chunk},
      ...kept,
      {'role': 'user', 'content': tail},
    ];
  }

  /// Splits [text] into chunks of at most [kWireMaxChars] characters,
  /// preferring newline boundaries; pathological single lines hard-split.
  List<String> _chunkText(String text) {
    if (text.length <= kWireMaxChars) return [text];
    final chunks = <String>[];
    var current = <String>[];
    var currentLen = 0;
    void flush() {
      if (current.isNotEmpty) {
        chunks.add(current.join('\n'));
        current = <String>[];
        currentLen = 0;
      }
    }

    for (final line in text.split('\n')) {
      if (line.length > kWireMaxChars) {
        flush();
        for (var i = 0; i < line.length; i += kWireMaxChars) {
          final end = i + kWireMaxChars > line.length
              ? line.length
              : i + kWireMaxChars;
          chunks.add(line.substring(i, end));
        }
        continue;
      }
      final added = (current.isEmpty ? 0 : 1) + line.length;
      if (currentLen + added > kWireMaxChars) flush();
      current.add(line);
      currentLen += added;
    }
    flush();
    return chunks;
  }
}
