import 'dart:convert';
import 'package:yaseen_ai_agent/yaseen_ai_agent.dart';
import 'package:yaseen_ai_agent/src/static/_pkg_constants.dart';
import 'package:yaseen_ai_agent/src/tools/_param_validator.dart';
import 'package:yaseen_ai_agent/src/tools/_parser.dart';
import 'package:yaseen_ai_agent/src/tools/_tool_runner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

part '_memory_manager.dart';
part '_prompt_builder.dart';
part '_agent_registry.dart';

/// Agent is the main class that represents the AI agent.
/// Define the agent with all background knowledge and tools.
class Agent {
  final _MemoryManager _memoryManager;
  final _PromptBuilder _promptBuilder;
  final PromptParser _promptParser = PromptParser();

  /// This is where you define the tools that the agent can use, registry allows you to register and unregister tools.
  final ToolRegistry toolRegistry;
  final ToolRunner _toolRunner = ToolRunner();

  /// The LLM that powers the agent, you can use a pre-built model like Gemini or if you have a custom implementation running on the server, you can use that.
  final LLM llm;

  /// This is the name of your agent, it is used to identify the agent in the conversation.
  final String name;

  /// This is the role of your agent, make it very descriptive because based on the description provided in role agents will be able to communicate with each other.
  final String role;

  /// Controls whether the agent throws typed exceptions or returns a graceful error message.
  final FailureMode failureMode;

  /// Optional callback invoked when an error occurs, regardless of failure mode.
  final void Function(YaseenAiAgentException error, StackTrace stack)? onError;

  /// Debug turn logging (prompts, tool calls, observations, outcomes).
  /// Always additionally gated by `kDebugMode`: release builds stay silent.
  final bool debugLog;

  final AgentScope _scope;

  Agent._internal({
    required this.llm,
    required _MemoryManager memoryManager,
    required _PromptBuilder promptBuilder,
    required this.toolRegistry,
    required this.name,
    required this.role,
    required this.failureMode,
    required AgentScope scope,
    this.onError,
    this.debugLog = false,
  }) : _memoryManager = memoryManager,
       _promptBuilder = promptBuilder,
       _scope = scope;

  /// Debug line, emitted only when [debugLog] is on AND in debug builds.
  /// Prompts may carry user data — never enable outside development.
  void _debug(Object? message) {
    if (debugLog && kDebugMode) {
      debugPrint('[yaseen_ai_agent:$name] $message');
    }
  }

  /// Truncates long text for debug lines.
  static String _truncate(String text, int max) =>
      text.length <= max ? text : '${text.substring(0, max)}…[truncated]';

  /// Async factory constructor to create an instance with loaded system data.
  ///
  /// [scope] controls which group of agents this agent can discover and chain
  /// to. Defaults to [AgentScope.global].
  ///
  /// [registrationPolicy] controls what happens when an agent with the same
  /// [name] already exists in the scope. Defaults to
  /// [RegistrationPolicy.throwIfExists].
  static Future<Agent> create({
    required DataStore dataStore,
    required LLM llm,
    required String name,
    required String role,

    /// Inline system prompt. When provided, [pathToSystemData] is ignored and
    /// no asset bundle is touched (pure-Dart friendly).
    Map<String, dynamic>? systemData,

    /// Debug turn logging (see [Agent.debugLog]). Development only.
    bool debugLog = false,

    /// BCP-47 conversation locale (e.g. `ar-TN`) rendered into prompts and
    /// merged into the system instruction.
    String? locale,

    /// Tool registry version advertised to the model.
    String? toolsVersion,
    String pathToSystemData = 'assets/system_data.json',
    FailureMode failureMode = FailureMode.gracefulMessage,
    void Function(YaseenAiAgentException error, StackTrace stack)? onError,
    AgentScope? scope,
    RegistrationPolicy registrationPolicy = RegistrationPolicy.throwIfExists,

    /// How many evicted messages to accumulate before the LLM summarizes them
    /// into a rolling context that is prepended to every future prompt.
    ///
    /// Set to 0 (the default) to disable summarization — evicted messages are
    /// simply dropped when they fall outside [memoryLimit].
    int summarizationBatchSize = 0,
  }) async {
    final resolvedScope = scope ?? AgentScope.global;
    final resolvedSystemData =
        systemData ?? await _loadSystemData(pathToSystemData);
    final registry = ToolRegistry();
    final agent = Agent._internal(
      llm: llm,
      memoryManager: _MemoryManager(
        dataStore: dataStore,
        llm: llm,
        summarizationBatchSize: summarizationBatchSize,
      ),
      promptBuilder: _PromptBuilder(
        systemPrompt: resolvedSystemData,
        registry: registry,
        scope: resolvedScope,
        locale: locale,
        toolsVersion: toolsVersion,
      ),
      toolRegistry: registry,
      name: name,
      role: role,
      failureMode: failureMode,
      onError: onError,
      debugLog: debugLog,
      scope: resolvedScope,
    );

    _AgentRegistry.instance.registerAgent(agent, policy: registrationPolicy);
    return agent;
  }

  /// Unregisters this agent from its scope, releasing it for re-creation.
  void dispose() {
    _AgentRegistry.instance.unregisterAgent(this);
  }

  static Future<Map<String, dynamic>> _loadSystemData(String path) async {
    try {
      final raw = await rootBundle.loadString(path);
      final decoded = json.decode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw ConfigException(
          'System data at $path must be a JSON object, got ${decoded.runtimeType}',
        );
      }
      return decoded;
    } on YaseenAiAgentException {
      rethrow;
    } catch (e, st) {
      throw ConfigException(
        'Failed to load system data from $path',
        cause: e,
        causeStack: st,
      );
    }
  }

  /// Paused approval states owned by this agent, keyed by approval id.
  ///
  /// Chained sub-turns store theirs on the owning agent; [resumeWithApproval]
  /// routes across the scope, so callers only ever talk to the root agent.
  final Map<String, _PendingState> _pendings = {};

  /// Generate a response to the user message. This is the public facing method.
  ///
  /// Returns [AgentResult.message] on completion or [AgentResult.pendingApproval]
  /// when the LLM requests a `requireApproval` tool (nothing executed yet).
  /// When the LLM supports native function calling, tool specs travel in the
  /// API payload and the prompt stays lean; otherwise the JSON-text fallback
  /// contract is used.
  Future<AgentResult> generate({
    required String convoId,
    required AgentMessage userMessage,
    int memoryLimit = 10,
    Object? metaData,
    CancellationToken? cancelToken,
  }) async {
    AgentResult? terminal;
    await for (final chunk in _turnStream(
      convoId: convoId,
      userMessage: userMessage,
      memoryLimit: memoryLimit,
      metaData: metaData,
      saveUser: true,
      persistTerminal: true,
      cancelToken: cancelToken,
    )) {
      if (chunk is AgentDoneChunk) terminal = chunk.result;
    }
    if (terminal == null) {
      throw StateError('Agent turn produced no result');
    }
    return terminal;
  }

  /// Streaming variant of [generate].
  ///
  /// Yields [AgentTextChunk] deltas in LLM order, then exactly one
  /// [AgentDoneChunk] with the terminal [AgentResult]. Cancellation and
  /// approval pauses surface as chunks, never as stream errors (unless
  /// [failureMode] is [FailureMode.throwError]).
  Stream<AgentStreamChunk> generateStream({
    required String convoId,
    required AgentMessage userMessage,
    int memoryLimit = 10,
    Object? metaData,
    CancellationToken? cancelToken,
  }) {
    return _turnStream(
      convoId: convoId,
      userMessage: userMessage,
      memoryLimit: memoryLimit,
      metaData: metaData,
      saveUser: true,
      persistTerminal: true,
      cancelToken: cancelToken,
    );
  }

  /// Resumes a turn paused with [AgentResult.pendingApproval].
  ///
  /// [approved] executes the gated tool (with [editedParams] when provided)
  /// and continues the turn; denied turns end with a graceful skip message
  /// and no side effects. Each approval resumes exactly once — unknown or
  /// already-consumed ids throw [UnknownApprovalException].
  Future<AgentResult> resumeWithApproval({
    required String pendingId,
    required bool approved,
    Map<String, dynamic>? editedParams,
    CancellationToken? cancelToken,
  }) async {
    final owner = _ownerOf(pendingId);
    if (owner == null) throw UnknownApprovalException(pendingId);
    if (!identical(owner, this)) {
      return owner.resumeWithApproval(
        pendingId: pendingId,
        approved: approved,
        editedParams: editedParams,
        cancelToken: cancelToken,
      );
    }
    final state = _pendings.remove(pendingId)!;
    try {
      if (cancelToken?.isCancelled ?? false) {
        throw const CancelledException();
      }
      final tool = toolRegistry.getTool(state.toolName);
      if (tool == null) throw ToolNotFoundException(state.toolName);
      if (!approved) {
        final skipped = AgentMessage(
          content: 'OK — I skipped ${state.toolName}.',
          isFromAgent: true,
          generatedAt: DateTime.now(),
        );
        await _memoryManager.saveMessage(
          state.convoId,
          skipped,
          metaData: state.metaData,
        );
        return AgentResult.message(skipped);
      }
      var params = state.params;
      if (editedParams != null) {
        final validation = validateParams(tool.parameters, editedParams);
        if (!validation.isValid) {
          throw ToolExecutionException(
            state.toolName,
            'Edited parameters invalid for tool ${state.toolName}: '
            '${validation.errors.join("; ")}',
          );
        }
        params = validation.values;
      }
      final callKey = _callKey(state.toolName, params);
      final context = ToolContext(
        metaData: state.metaData,
        cancelToken: cancelToken,
      );
      late final ToolResponse toolResponse;
      try {
        toolResponse = await tool.runWithContext(params, context);
      } on YaseenAiAgentException {
        rethrow;
      } catch (e, st) {
        throw ToolExecutionException(
          state.toolName,
          'Tool ${state.toolName} threw during execution: $e',
          cause: e,
          causeStack: st,
        );
      }
      final observation = {
        'tool': toolResponse.toolName,
        'success': toolResponse.isRequestSuccessful,
        'message': toolResponse.message,
        if (toolResponse.data != null) 'data': toolResponse.data,
      };
      if (toolResponse.needsFurtherReasoning) {
        final reasoned = await _reasonUsingData(state.userMessage.content, [
          toolResponse,
        ]);
        await _memoryManager.saveMessage(
          state.convoId,
          reasoned,
          metaData: state.metaData,
        );
        return AgentResult.message(reasoned);
      }
      AgentResult? terminal;
      await for (final chunk in _turnStream(
        convoId: state.convoId,
        userMessage: state.userMessage,
        memoryLimit: state.memoryLimit,
        metaData: state.metaData,
        saveUser: false,
        persistTerminal: true,
        cancelToken: cancelToken,
        initialObservations: [observation],
        initialAttempted: {...state.attemptedKeys, callKey},
        initialStep: state.stepsUsed,
      )) {
        if (chunk is AgentDoneChunk) terminal = chunk.result;
      }
      if (terminal == null) {
        throw StateError('Agent turn produced no result');
      }
      return terminal;
    } on CancelledException {
      final msg = _cancelledMessage();
      await _memoryManager.saveMessage(
        state.convoId,
        msg,
        metaData: state.metaData,
      );
      return AgentResult.message(msg);
    } on YaseenAiAgentException catch (e, st) {
      onError?.call(e, st);
      if (failureMode == FailureMode.throwError) rethrow;
      final msg = _gracefulMessage();
      await _memoryManager.saveMessage(
        state.convoId,
        msg,
        metaData: state.metaData,
      );
      return AgentResult.message(msg);
    } catch (e, st) {
      final wrapped = LlmException(
        'Unexpected error: $e',
        cause: e,
        causeStack: st,
      );
      onError?.call(wrapped, st);
      if (failureMode == FailureMode.throwError) throw wrapped;
      final msg = _gracefulMessage();
      await _memoryManager.saveMessage(
        state.convoId,
        msg,
        metaData: state.metaData,
      );
      return AgentResult.message(msg);
    }
  }

  /// Finds the agent in this scope owning [pendingId], if any.
  Agent? _ownerOf(String pendingId) {
    if (_pendings.containsKey(pendingId)) return this;
    for (final agent in _AgentRegistry.instance.getAllAgents(scope: _scope)) {
      if (agent._pendings.containsKey(pendingId)) return agent;
    }
    return null;
  }

  /// Encodes one attempted `(tool, params)` call for duplicate suppression.
  static String _callKey(String toolName, Map<String, dynamic> params) =>
      json.encode({'tool': toolName, 'params': params});

  static AgentMessage _cancelledMessage() => AgentMessage(
    content: 'Request cancelled.',
    isFromAgent: true,
    generatedAt: DateTime.now(),
    isError: true,
  );

  static AgentMessage _gracefulMessage() => AgentMessage(
    content: kLLMResponseOnFailure,
    isFromAgent: true,
    generatedAt: DateTime.now(),
    isError: true,
  );

  /// Persists a terminal message per the turn's save flags, logs the outcome,
  /// and yields the closing chunk. Single funnel for all success terminals so
  /// debug output and persistence cannot drift apart.
  Stream<AgentStreamChunk> _finish({
    required AgentMessage message,
    required String convoId,
    required AgentMessage userMessage,
    Object? metaData,
    required bool saveUser,
    required bool persistTerminal,
    required Stopwatch turnClock,
  }) async* {
    _debug(
      'terminal message after ${turnClock.elapsedMilliseconds}ms: '
      '${_truncate(message.content, 500)}',
    );
    if (saveUser) {
      await _memoryManager.saveMessage(
        convoId,
        userMessage,
        metaData: metaData,
      );
    }
    if (persistTerminal) {
      await _memoryManager.saveMessage(convoId, message, metaData: metaData);
    }
    yield AgentStreamChunk.done(AgentResult.message(message));
  }

  /// Single turn implementation backing [generate], [generateStream] and
  /// [resumeWithApproval]. Streams [AgentTextChunk] deltas in LLM order and
  /// always terminates with exactly one [AgentDoneChunk] unless [failureMode]
  /// rethrows.
  Stream<AgentStreamChunk> _turnStream({
    required String convoId,
    required AgentMessage userMessage,
    required int memoryLimit,
    Object? metaData,
    required bool saveUser,
    required bool persistTerminal,
    bool isPartOfChain = false,
    String? input,
    Set<String>? chainVisited,
    int chainDepth = 0,
    CancellationToken? cancelToken,
    bool propagateCancel = false,
    List<Map<String, dynamic>>? initialObservations,
    Set<String>? initialAttempted,
    int initialStep = 0,
  }) async* {
    Future<void> saveUserMessage() =>
        _memoryManager.saveMessage(convoId, userMessage, metaData: metaData);
    Future<void> saveAgentMessage(AgentMessage message) =>
        _memoryManager.saveMessage(convoId, message, metaData: metaData);
    // Declared outside `try` so the catch blocks can report turn latency.
    final turnClock = Stopwatch()..start();

    try {
      if (cancelToken?.isCancelled ?? false) {
        throw const CancelledException();
      }
      final (:messages, :summary) = await _memoryManager.getContext(
        convoId,
        limit: memoryLimit,
        metaData: metaData,
      );

      // Hybrid tool protocol: native-capable LLMs receive specs out-of-band and
      // get a lean prompt; everyone else gets the full JSON-text contract.
      final nativeTools =
          llm.supportsNativeTools && toolRegistry.getAllTools().isNotEmpty
          ? toolRegistry.getAllTools()
          : null;

      // Structured wire providers (e.g. the Rebelo AI proxy) receive
      // role/content messages instead of one flattened text prompt.
      final structured = llm.prefersStructuredHistory;

      final prompt = structured
          ? ''
          : _promptBuilder.buildTextPrompt(
              memoryMessages: messages,
              contextSummary: summary,
              userMessage: userMessage,
              isPartOfChain: isPartOfChain,
              input: input,
              includeTools: nativeTools == null,
            );

      // Structured providers skip the flattened prompt: history travels as
      // wire messages and only the tail evolves across tool rounds.
      final baseTail = structured
          ? _promptBuilder.buildStructuredTail(
              input: input,
              isPartOfChain: isPartOfChain,
              userContent: userMessage.content,
            )
          : '';

      // Accumulated tool observations for multi-step tool use.
      final observations = <Map<String, dynamic>>[...?initialObservations];
      // Per-tool (name + params) keys that have already been attempted this turn.
      // Used to hard-block re-execution — the model cannot repeat a call even if
      // it ignores the observation prompt.
      final attemptedCalls = <String>{...?initialAttempted};
      var currentPrompt = observations.isEmpty
          ? prompt
          : _buildObservationPrompt(
              originalPrompt: prompt,
              observations: observations,
            );
      var currentTail = observations.isEmpty
          ? baseTail
          : '$baseTail${_observationBlock(observations)}'.trim();
      var isFirstCall = initialObservations == null;
      final toolContext = ToolContext(
        metaData: metaData,
        cancelToken: cancelToken,
      );
      _debug('turn start convo=$convoId prompt=${_truncate(prompt, 2000)}');

      for (var step = initialStep; step < kMaxToolIterations; step++) {
        if (cancelToken?.isCancelled ?? false) {
          throw const CancelledException();
        }
        // Streaming parse-retry: deltas yield as they arrive; the full text
        // is parsed once the provider stream closes.
        var parsed = PromptParserResult(
          outcome: ParseOutcome.unparseable,
          agentNames: const <String>[],
          toolNames: const <String>[],
          params: const <String, Map<String, dynamic>>{},
          rawOutput: structured ? currentTail : currentPrompt,
        );
        var attemptPrompt = currentPrompt;
        var attemptTail = currentTail;
        for (var attempt = 0; attempt <= kMaxParseRetries; attempt++) {
          if (cancelToken?.isCancelled ?? false) {
            throw const CancelledException();
          }
          final buffer = StringBuffer();
          await for (final delta
              in structured
                  ? llm.generateStreamWithMessages(
                      messages: _promptBuilder.buildWireMessages(
                        memoryMessages: messages,
                        contextSummary: summary,
                        systemInstruction: _promptBuilder.systemInstruction,
                        tail: attemptTail,
                        isPartOfChain: isPartOfChain,
                        includeTools: nativeTools == null,
                      ),
                      rawData: (attempt == 0 && isFirstCall)
                          ? userMessage.imageData
                          : null,
                      tools: nativeTools,
                    )
                  : llm.generateStream(
                      prompt: attemptPrompt,
                      systemInstruction: _promptBuilder.systemInstruction,
                      rawData: (attempt == 0 && isFirstCall)
                          ? userMessage.imageData
                          : null,
                      tools: nativeTools,
                    )) {
            buffer.write(delta);
            yield AgentStreamChunk.text(delta);
          }
          parsed = _promptParser.parse(buffer.toString());
          if (parsed.outcome != ParseOutcome.unparseable) break;
          attemptPrompt = '$currentPrompt\n\n$kParseRetryInstruction';
          attemptTail = '$currentTail\n\n$kParseRetryInstruction';
        }
        isFirstCall = false;

        switch (parsed.outcome) {
          case ParseOutcome.response:
            final response = parsed.fallbackResponse ?? kLLMResponseOnFailure;
            final message = AgentMessage(
              content: response,
              isFromAgent: true,
              generatedAt: DateTime.now(),
              data: observations.isNotEmpty
                  ? {'observations': observations}
                  : null,
            );
            yield* _finish(
              message: message,
              convoId: convoId,
              userMessage: userMessage,
              metaData: metaData,
              saveUser: saveUser,
              persistTerminal: persistTerminal,
              turnClock: turnClock,
            );
            return;

          case ParseOutcome.agentsChain:
            AgentResult? chainTerminal;
            await for (final chunk in _handleAgentChainStream(
              parsed: parsed,
              convoId: convoId,
              userMessage: userMessage,
              memoryLimit: memoryLimit,
              metaData: metaData,
              cancelToken: cancelToken,
              visited: chainVisited,
              depth: chainDepth,
            )) {
              if (chunk is AgentTextChunk) {
                yield chunk;
              } else if (chunk is AgentDoneChunk) {
                chainTerminal = chunk.result;
              }
            }
            if (saveUser) await saveUserMessage();
            if (chainTerminal is AgentPendingResult) {
              _debug('terminal pending ${chainTerminal.pending.toolName}');
              yield AgentStreamChunk.done(chainTerminal);
              return;
            }
            final chained = (chainTerminal as AgentMessageResult).message;
            yield* _finish(
              message: chained,
              convoId: convoId,
              userMessage: userMessage,
              metaData: metaData,
              saveUser: false,
              persistTerminal: persistTerminal,
              turnClock: turnClock,
            );
            return;

          case ParseOutcome.tools:
            final gated = _firstGatedTool(parsed.toolNames);
            if (gated != null) {
              final gatedTool = toolRegistry.getTool(gated)!;
              final gatedValidation = validateParams(
                gatedTool.parameters,
                parsed.params[gated] ?? const <String, dynamic>{},
              );
              if (!gatedValidation.isValid) {
                // Correctable: steer a retry instead of pausing on garbage.
                observations.add({
                  'tool': gated,
                  'success': false,
                  'message':
                      'Parameter error: ${gatedValidation.errors.join("; ")}. '
                      'Expected: ${_requiredParamsHint(gatedTool)}. Correct '
                      'the parameters and retry, or ask the user.',
                });
                currentPrompt = _buildObservationPrompt(
                  originalPrompt: prompt,
                  observations: observations,
                );
                currentTail = '$baseTail${_observationBlock(observations)}'
                    .trim();
                continue;
              }
              yield* _pauseForApproval(
                toolName: gated,
                parsed: parsed,
                convoId: convoId,
                userMessage: userMessage,
                memoryLimit: memoryLimit,
                metaData: metaData,
                saveUser: saveUser,
                attemptedCalls: attemptedCalls,
                step: step,
              );
              return;
            }
            // Filter out any (tool, params) combo already attempted this turn.
            // Prevents duplicate side effects even if the model ignores the
            // observation prompt's "do not re-invoke" instruction.
            final remaining = <String>[];
            final remainingKeys = <String>[];
            for (final toolName in parsed.toolNames) {
              final key = json.encode({
                'tool': toolName,
                'params': parsed.params[toolName] ?? const <String, dynamic>{},
              });
              if (attemptedCalls.contains(key)) continue;
              remaining.add(toolName);
              remainingKeys.add(key);
            }

            if (remaining.isEmpty) {
              // Model re-requested only already-attempted tools. Return with
              // whatever we have so we don't burn more LLM calls.
              final successMessages = observations
                  .where((o) => o['success'] == true)
                  .map((o) => (o['message'] ?? '').toString())
                  .where((m) => m.isNotEmpty)
                  .toList();
              final content = successMessages.isNotEmpty
                  ? successMessages.join('\n')
                  : kLLMResponseOnFailure;
              final exhausted = AgentMessage(
                content: content,
                isFromAgent: true,
                generatedAt: DateTime.now(),
                data: observations.isNotEmpty
                    ? {'observations': observations}
                    : null,
              );
              yield* _finish(
                message: exhausted,
                convoId: convoId,
                userMessage: userMessage,
                metaData: metaData,
                saveUser: saveUser,
                persistTerminal: persistTerminal,
                turnClock: turnClock,
              );
              return;
            }

            // Validate BEFORE running: correctable parameter errors become
            // failed observations that steer a retry (next step) instead of
            // killing the turn. Unknown tools pass through for the runner
            // to reject loudly — a retry cannot invent a real tool.
            final validNames = <String>[];
            final validKeys = <String>[];
            for (var i = 0; i < remaining.length; i++) {
              final toolName = remaining[i];
              final tool = toolRegistry.getTool(toolName);
              if (tool == null) {
                validNames.add(toolName);
                validKeys.add(remainingKeys[i]);
                continue;
              }
              final validation = validateParams(
                tool.parameters,
                parsed.params[toolName] ?? const <String, dynamic>{},
              );
              if (validation.isValid) {
                validNames.add(toolName);
                validKeys.add(remainingKeys[i]);
              } else {
                observations.add({
                  'tool': toolName,
                  'success': false,
                  'message':
                      'Parameter error: ${validation.errors.join("; ")}. '
                      'Expected: ${_requiredParamsHint(tool)}. Correct the '
                      'parameters and retry, or ask the user.',
                });
              }
            }

            if (validNames.isEmpty) {
              // Nothing runnable this step — the errors above steer retry.
              // Bounded by the loop cap, so a stubborn model cannot spin.
              currentPrompt = _buildObservationPrompt(
                originalPrompt: prompt,
                observations: observations,
              );
              currentTail = '$baseTail${_observationBlock(observations)}'
                  .trim();
              continue;
            }

            // Mark as attempted BEFORE running so an exception mid-flight still
            // blocks a naive retry of the same call.
            attemptedCalls.addAll(validKeys);

            final filteredParsed = PromptParserResult(
              outcome: ParseOutcome.tools,
              toolNames: validNames,
              params: {
                for (final t in validNames)
                  t: parsed.params[t] ?? const <String, dynamic>{},
              },
              agentNames: parsed.agentNames,
              rawOutput: parsed.rawOutput,
            );
            _debug(
              'calling ${remaining.join(',')} '
              'params=${_truncate(json.encode(filteredParsed.params), 500)}',
            );

            final toolResponses = await _toolRunner.runTools(
              filteredParsed,
              toolRegistry,
              context: toolContext,
            );

            for (final r in toolResponses) {
              _debug(
                'observation ${r.toolName} success=${r.isRequestSuccessful} '
                'message=${_truncate(r.message, 300)}',
              );
              observations.add({
                'tool': r.toolName,
                'success': r.isRequestSuccessful,
                'message': r.message,
                if (r.data != null) 'data': r.data,
              });
            }

            final needsFurtherReasoning = toolResponses.any(
              (r) => r.needsFurtherReasoning,
            );

            if (needsFurtherReasoning) {
              final reasoned = await _reasonUsingData(
                userMessage.content,
                toolResponses,
              );
              yield* _finish(
                message: reasoned,
                convoId: convoId,
                userMessage: userMessage,
                metaData: metaData,
                saveUser: saveUser,
                persistTerminal: persistTerminal,
                turnClock: turnClock,
              );
              return;
            }

            // Build a follow-up prompt with an explicit succeeded/failed split
            // so the LLM knows exactly what remains and what NOT to repeat.
            currentPrompt = _buildObservationPrompt(
              originalPrompt: prompt,
              observations: observations,
            );
            currentTail = '$baseTail${_observationBlock(observations)}'.trim();

          case ParseOutcome.unparseable:
            // All parse retries exhausted in _llmGenerateWithParseRetry
            throw ResponseParseException(
              'LLM output remained unparseable after retries',
              rawOutput: parsed.rawOutput ?? '',
            );
        }
      }

      // Max iterations reached — synthesize from what we have
      final fallback = observations.isNotEmpty
          ? AgentMessage(
              content:
                  observations.map((o) => o['message'] ?? '').join('\n').isEmpty
                  ? kLLMResponseOnFailure
                  : observations.map((o) => o['message'] ?? '').join('\n'),
              isFromAgent: true,
              generatedAt: DateTime.now(),
              data: {'observations': observations},
            )
          : AgentMessage(
              content: kLLMResponseOnFailure,
              isFromAgent: true,
              generatedAt: DateTime.now(),
            );
      yield* _finish(
        message: fallback,
        convoId: convoId,
        userMessage: userMessage,
        metaData: metaData,
        saveUser: saveUser,
        persistTerminal: persistTerminal,
        turnClock: turnClock,
      );
      return;
    } on CancelledException {
      if (propagateCancel) rethrow;
      _debug('terminal cancelled after ${turnClock.elapsedMilliseconds}ms');
      final cancelled = _cancelledMessage();
      if (saveUser) await saveUserMessage();
      if (persistTerminal) await saveAgentMessage(cancelled);
      yield AgentStreamChunk.done(AgentResult.message(cancelled));
      return;
    } on YaseenAiAgentException catch (e, st) {
      onError?.call(e, st);
      if (failureMode == FailureMode.throwError) rethrow;
      _debug('terminal graceful ($e) after ${turnClock.elapsedMilliseconds}ms');
      final graceful = _gracefulMessage();
      if (saveUser) await saveUserMessage();
      if (persistTerminal) await saveAgentMessage(graceful);
      yield AgentStreamChunk.done(AgentResult.message(graceful));
      return;
    } catch (e, st) {
      final wrapped = LlmException(
        'Unexpected error: $e',
        cause: e,
        causeStack: st,
      );
      onError?.call(wrapped, st);
      if (failureMode == FailureMode.throwError) throw wrapped;
      _debug(
        'terminal graceful ($wrapped) after ${turnClock.elapsedMilliseconds}ms',
      );
      final graceful = _gracefulMessage();
      if (saveUser) await saveUserMessage();
      if (persistTerminal) await saveAgentMessage(graceful);
      yield AgentStreamChunk.done(AgentResult.message(graceful));
      return;
    }
  }

  /// One-line parameter contract for correction prompts:
  /// `routeKey (required, one of: a, b); arg (optional)`.
  static String _requiredParamsHint(Tool tool) {
    final parts = <String>[];
    for (final p in tool.parameters) {
      final req = p.required ? 'required' : 'optional';
      final enums = p.enumValues != null && p.enumValues!.isNotEmpty
          ? ', one of: ${p.enumValues!.join(', ')}'
          : '';
      parts.add('${p.name} ($req$enums)');
    }
    return parts.join('; ');
  }

  /// Returns the first requested tool gated by [ToolApproval.requireApproval],
  /// if any. Unknown tools are left for [ToolRunner] to reject.
  String? _firstGatedTool(List<String> toolNames) {
    for (final toolName in toolNames) {
      final tool = toolRegistry.getTool(toolName);
      if (tool != null && tool.approval == ToolApproval.requireApproval) {
        return toolName;
      }
    }
    return null;
  }

  /// Pauses the turn before a gated tool runs: validates parameters now,
  /// stores the resumable state, and yields the pending approval as a stream.
  Stream<AgentStreamChunk> _pauseForApproval({
    required String toolName,
    required PromptParserResult parsed,
    required String convoId,
    required AgentMessage userMessage,
    required int memoryLimit,
    Object? metaData,
    required bool saveUser,
    required Set<String> attemptedCalls,
    required int step,
  }) async* {
    final tool = toolRegistry.getTool(toolName)!;
    final rawParams = parsed.params[toolName] ?? const <String, dynamic>{};
    final validation = validateParams(tool.parameters, rawParams);
    if (!validation.isValid) {
      throw ToolExecutionException(
        toolName,
        'Parameter validation failed for tool $toolName: '
        '${validation.errors.join("; ")}',
      );
    }
    final approval = PendingApproval(
      id: const Uuid().v4(),
      toolName: toolName,
      params: validation.values,
      convoId: convoId,
    );
    _pendings[approval.id] = _PendingState(
      convoId: convoId,
      userMessage: userMessage,
      memoryLimit: memoryLimit,
      metaData: metaData,
      toolName: toolName,
      params: validation.values,
      attemptedKeys: Set<String>.from(attemptedCalls),
      stepsUsed: step + 1,
    );
    if (saveUser) {
      await _memoryManager.saveMessage(
        convoId,
        userMessage,
        metaData: metaData,
      );
    }
    _debug(
      'paused for approval ${approval.toolName} '
      'params=${_truncate(json.encode(approval.params), 500)}',
    );
    yield AgentStreamChunk.done(AgentResult.pendingApproval(approval));
  }

  /// Forwards one chained sub-turn: text deltas pass through, the sub-turn's
  /// terminal chunk is captured by the caller. A sub-turn approval pause
  /// propagates upward (resumable via scope routing in [resumeWithApproval]).
  Stream<AgentStreamChunk> _handleAgentChainStream({
    required PromptParserResult parsed,
    required String convoId,
    required AgentMessage userMessage,
    required int memoryLimit,
    Object? metaData,
    CancellationToken? cancelToken,
    Set<String>? visited,
    int depth = 0,
  }) async* {
    final agentsChain = List<String>.of(parsed.agentNames);
    String? inputForNextStep;
    AgentMessage? lastResponse;
    final visitedSet = visited ?? <String>{name};

    while (agentsChain.isNotEmpty) {
      final agentName = agentsChain.removeAt(0);

      if (visitedSet.contains(agentName)) {
        throw ConfigException(
          'Cycle detected in agent chain: $agentName has already been visited '
          '(path: ${visitedSet.join(" → ")} → $agentName)',
        );
      }

      if (depth >= kMaxChainDepth) {
        throw ConfigException(
          'Agent chain depth limit ($kMaxChainDepth) exceeded at agent $agentName',
        );
      }

      final agent = _AgentRegistry.instance.getAgent(agentName, scope: _scope);

      if (agent == null) {
        throw AgentNotFoundException(agentName);
      }

      visitedSet.add(agentName);

      AgentResult? subTerminal;
      await for (final chunk in agent._turnStream(
        convoId: convoId,
        userMessage: userMessage,
        memoryLimit: memoryLimit,
        metaData: metaData,
        saveUser: false,
        persistTerminal: false,
        isPartOfChain: true,
        input: inputForNextStep,
        chainVisited: visitedSet,
        chainDepth: depth + 1,
        cancelToken: cancelToken,
        propagateCancel: true,
      )) {
        if (chunk is AgentTextChunk) {
          yield chunk;
        } else if (chunk is AgentDoneChunk) {
          subTerminal = chunk.result;
        }
      }
      if (subTerminal is AgentPendingResult) {
        yield AgentStreamChunk.done(subTerminal);
        return;
      }
      final message = (subTerminal as AgentMessageResult).message;
      lastResponse = message;
      inputForNextStep = message.data != null
          ? json.encode(message.data)
          : message.content;
    }

    if (lastResponse == null) {
      yield AgentStreamChunk.done(AgentResult.message(_gracefulMessage()));
      return;
    }
    yield AgentStreamChunk.done(AgentResult.message(lastResponse));
  }

  String _buildObservationPrompt({
    required String originalPrompt,
    required List<Map<String, dynamic>> observations,
  }) => '$originalPrompt${_observationBlock(observations)}'.trim();

  /// The tool-results section appended to a turn prompt (text) or tail
  /// (structured) after each tool round. Extracted so both prompt paths
  /// share one implementation.
  static String _observationBlock(List<Map<String, dynamic>> observations) {
    final succeeded = observations.where((o) => o['success'] == true).toList();
    final failed = observations.where((o) => o['success'] != true).toList();

    final buffer = StringBuffer();
    buffer.writeln('\n\nTool execution results so far:');

    if (succeeded.isNotEmpty) {
      buffer.writeln(
        '\nAlready completed successfully — the framework will REJECT any '
        'attempt to invoke these again with the same parameters:',
      );
      for (final o in succeeded) {
        buffer.writeln('- ${o['tool']}: ${o['message']}');
      }
    }

    if (failed.isNotEmpty) {
      buffer.writeln(
        '\nFailed — you may retry ONLY with corrected parameters, or '
        'acknowledge the failure in your response:',
      );
      for (final o in failed) {
        buffer.writeln('- ${o['tool']}: ${o['message']}');
      }
    }

    if (failed.isEmpty) {
      buffer.writeln(
        '\nAll requested actions are complete. If the user\'s task is fully '
        'done, respond NOW with {"response": "<brief confirmation>"}. '
        'Only call another tool if a DIFFERENT next step is genuinely required.',
      );
    } else {
      buffer.writeln(
        '\nDecide: call the next required tool, retry a failed one with '
        'corrected params, or respond with {"response": "..."}. '
        'Never re-invoke a succeeded tool.',
      );
    }

    return buffer.toString();
  }

  /// Get messages for a specific conversation from the datastore.
  Future<List<AgentMessage>> getMessages({
    required String conversationId,
    Object? metaData,
  }) {
    return _memoryManager.dataStore.getMessages(
      conversationId,
      metaData: metaData,
    );
  }

  /// Get all conversations from the datastore.
  Future<List<Conversation>> getAllConversations({Object? metaData}) {
    return _memoryManager.dataStore.getConversations(metaData: metaData);
  }

  /// Delete a conversation from the datastore.
  Future<void> deleteConversation({
    required String conversationId,
    Object? metaData,
  }) {
    return _memoryManager.dataStore.deleteConversation(
      conversationId,
      metaData: metaData,
    );
  }

  Future<AgentMessage> _reasonUsingData(
    String originalPrompt,
    List<ToolResponse> toolResponses,
  ) async {
    final toolData = toolResponses
        .map(
          (r) => {
            'tool': r.toolName,
            'message': r.message,
            if (r.data != null) 'data': r.data,
          },
        )
        .toList();

    final raw = await llm.generate(
      prompt:
          'Keep the answer to the point but natural, only answer what is asked '
          'in the original prompt using this data.\n\n'
          'Tool results: ${json.encode(toolData)}\n\n'
          'Original prompt: $originalPrompt',
      systemInstruction: _promptBuilder.systemInstruction,
    );

    final content = _extractResponseText(raw);

    return AgentMessage(
      content: content,
      isFromAgent: true,
      generatedAt: DateTime.now(),
      data: {'tools': toolData},
    );
  }

  /// Extracts plain text from a raw LLM response that may be wrapped in
  /// `{"response": "..."}` JSON (common when jsonMode is enabled).
  String _extractResponseText(String raw) {
    try {
      final decoded = json.decode(raw.trim());
      if (decoded is Map<String, dynamic> && decoded.containsKey('response')) {
        return decoded['response']?.toString() ?? raw;
      }
    } catch (_) {}
    return raw;
  }

  @override
  String toString() => 'Agent(name: $name, role: $role)';
}

/// Resumable loop state stored when a turn pauses for approval.
///
/// The user message is persisted at pause time; the agent message is
/// persisted when the resumed turn terminates.
class _PendingState {
  final String convoId;
  final AgentMessage userMessage;
  final int memoryLimit;
  final Object? metaData;
  final String toolName;
  final Map<String, dynamic> params;
  final Set<String> attemptedKeys;
  final int stepsUsed;

  _PendingState({
    required this.convoId,
    required this.userMessage,
    required this.memoryLimit,
    this.metaData,
    required this.toolName,
    required this.params,
    required this.attemptedKeys,
    required this.stepsUsed,
  });
}
