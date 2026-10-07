// Sealed turn results for approval-gated agent execution.

import 'package:yaseen_ai_agent/src/memory/data/agent_message.dart';

/// Terminal result of one agent turn.
///
/// Either a final [message] or a [pendingApproval] pause awaiting
/// [Agent.resumeWithApproval]. Pauses are normal control flow, never errors —
/// [FailureMode.gracefulMessage] never swallows them.
sealed class AgentResult {
  const AgentResult();

  /// Final answer (or graceful failure) of the turn.
  const factory AgentResult.message(AgentMessage message) = AgentMessageResult;

  /// Execution paused before a `requireApproval` tool. Nothing was executed.
  const factory AgentResult.pendingApproval(PendingApproval pending) =
      AgentPendingResult;
}

/// Final answer of a turn. See [AgentResult.message].
class AgentMessageResult extends AgentResult {
  /// The terminal agent message (saved to memory by the agent).
  final AgentMessage message;

  /// Creates an [AgentMessageResult].
  const AgentMessageResult(this.message);
}

/// Paused turn awaiting human approval. See [AgentResult.pendingApproval].
class AgentPendingResult extends AgentResult {
  /// The pending approval to resume (or deny) via [Agent.resumeWithApproval].
  final PendingApproval pending;

  /// Creates an [AgentPendingResult].
  const AgentPendingResult(this.pending);
}

/// One piece of a streaming turn. See `Agent.generateStream`.
///
/// Text deltas arrive as [AgentTextChunk] (in LLM order); the turn always
/// terminates with exactly one [AgentDoneChunk] unless `FailureMode.throwError`
/// rethrows.
sealed class AgentStreamChunk {
  const AgentStreamChunk();

  /// One LLM text delta.
  const factory AgentStreamChunk.text(String delta) = AgentTextChunk;

  /// Terminal chunk carrying the turn's [AgentResult].
  const factory AgentStreamChunk.done(AgentResult result) = AgentDoneChunk;
}

/// One LLM text delta. See [AgentStreamChunk.text].
class AgentTextChunk extends AgentStreamChunk {
  /// The streamed text fragment.
  final String delta;

  /// Creates an [AgentTextChunk].
  const AgentTextChunk(this.delta);
}

/// Terminal chunk of a streaming turn. See [AgentStreamChunk.done].
class AgentDoneChunk extends AgentStreamChunk {
  /// The turn's terminal result.
  final AgentResult result;

  /// Creates an [AgentDoneChunk].
  const AgentDoneChunk(this.result);
}

/// A `requireApproval` tool call awaiting a human decision.
///
/// Created by the agent when the LLM requests a gated tool; resumed exactly
/// once via [Agent.resumeWithApproval]. IDs are per-agent-instance UUIDs.
class PendingApproval {
  /// Opaque id consumed by [Agent.resumeWithApproval].
  final String id;

  /// Name of the gated tool (registered in the agent's [ToolRegistry]).
  final String toolName;

  /// Validated parameters the tool would run with (editable on resume).
  final Map<String, dynamic> params;

  /// Conversation this turn belongs to.
  final String convoId;

  /// Creates a [PendingApproval].
  const PendingApproval({
    required this.id,
    required this.toolName,
    required this.params,
    required this.convoId,
  });
}

/// One recorded LLM round trip: exactly what went over the wire and what
/// came back. Powers session audits — see `Agent.exchanges`.
class LlmExchange {
  /// When the call was issued.
  final DateTime at;

  /// Structured `role`/`content` payload (structured providers), if any.
  final List<Map<String, dynamic>>? messages;

  /// Flattened prompt (text providers), if any.
  final String? prompt;

  /// System instruction sent alongside a text prompt, if any. Structured
  /// providers carry it inside [messages] instead.
  final String? systemInstruction;

  /// Full buffered response text (deltas concatenated).
  final String response;

  /// Creates an [LlmExchange].
  const LlmExchange({
    required this.at,
    this.messages,
    this.prompt,
    this.systemInstruction,
    required this.response,
  });

  /// Audit-shaped map.
  Map<String, dynamic> toJson() => {
    'at': at.toIso8601String(),
    if (messages != null) 'messages': messages,
    if (prompt != null) 'prompt': prompt,
    if (systemInstruction != null) 'system_instruction': systemInstruction,
    'response': response,
  };
}
