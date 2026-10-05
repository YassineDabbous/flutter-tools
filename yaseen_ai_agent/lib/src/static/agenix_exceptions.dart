/// Base class for all YaseenAiAgent exceptions. Sealed so consumers can exhaustively
/// switch on the exception type.
sealed class YaseenAiAgentException implements Exception {
  /// Human-readable description of what went wrong.
  final String message;

  /// The original error that caused this exception, if any.
  final Object? cause;

  /// The stack trace of the original error, if any.
  final StackTrace? causeStack;

  /// Creates an [YaseenAiAgentException] with a [message] and optional [cause]/[causeStack].
  const YaseenAiAgentException(this.message, {this.cause, this.causeStack});

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when the LLM call fails (network error, blocked response, empty output).
class LlmException extends YaseenAiAgentException {
  /// HTTP status code returned by the provider, if the failure was an HTTP error.
  final int? statusCode;

  /// How long to wait before retrying, parsed from the provider's `Retry-After`
  /// header. `null` when the header was absent or unparseable.
  final Duration? retryAfter;

  /// Creates an [LlmException].
  const LlmException(
    super.message, {
    super.cause,
    super.causeStack,
    this.statusCode,
    this.retryAfter,
  });
}

/// Thrown when a provider responds with HTTP 429 (Too Many Requests).
///
/// Check [retryAfter] for the provider-suggested wait duration before retrying.
/// When the provider omits the `Retry-After` header, [retryAfter] is `null` and
/// the caller should apply its own backoff strategy.
class LlmRateLimitException extends LlmException {
  /// Creates an [LlmRateLimitException].
  const LlmRateLimitException(
    super.message, {
    super.cause,
    super.causeStack,
    super.statusCode = 429,
    super.retryAfter,
  });
}

/// Thrown when an LLM request exceeds the configured timeout.
class LlmTimeoutException extends LlmException {
  /// Creates an [LlmTimeoutException].
  const LlmTimeoutException(super.message, {super.cause, super.causeStack});
}

/// Thrown when the LLM output cannot be parsed into the expected JSON contract.
class ResponseParseException extends YaseenAiAgentException {
  /// The raw string the LLM returned.
  final String rawOutput;

  /// Creates a [ResponseParseException].
  const ResponseParseException(
    super.message, {
    required this.rawOutput,
    super.cause,
    super.causeStack,
  });
}

/// Thrown when a tool referenced by the LLM is not registered.
class ToolNotFoundException extends YaseenAiAgentException {
  /// The name of the missing tool.
  final String toolName;

  /// Creates a [ToolNotFoundException] for [toolName].
  const ToolNotFoundException(this.toolName)
    : super('Tool $toolName not found in registry');
}

/// Thrown when a registered tool's [run] method throws during execution.
class ToolExecutionException extends YaseenAiAgentException {
  /// The name of the tool that failed.
  final String toolName;

  /// Creates a [ToolExecutionException] for [toolName].
  const ToolExecutionException(
    this.toolName,
    super.message, {
    super.cause,
    super.causeStack,
  });
}

/// Thrown when an agent referenced in a chain is not registered.
class AgentNotFoundException extends YaseenAiAgentException {
  /// The name of the missing agent.
  final String agentName;

  /// Creates an [AgentNotFoundException] for [agentName].
  const AgentNotFoundException(this.agentName)
    : super('Agent $agentName not found in registry');
}

/// Thrown when a [DataStore] operation fails.
class DataStoreException extends YaseenAiAgentException {
  /// Creates a [DataStoreException].
  const DataStoreException(super.message, {super.cause, super.causeStack});
}

/// Thrown when a [DataStore] operation requires an authenticated user but none is signed in.
class NotAuthenticatedException extends DataStoreException {
  /// Creates a [NotAuthenticatedException].
  const NotAuthenticatedException()
    : super(
        'No authenticated user found. Sign in before using the data store.',
      );
}

/// Thrown when agent configuration is invalid (e.g. malformed system_data.json).
class ConfigException extends YaseenAiAgentException {
  /// Creates a [ConfigException].
  const ConfigException(super.message, {super.cause, super.causeStack});
}

/// Controls how the agent surfaces errors from [Agent.generateResponse].
enum FailureMode {
  /// Rethrow the typed [YaseenAiAgentException] to the caller.
  throwError,

  /// Return a graceful error [AgentMessage] with [isError] set to true.
  gracefulMessage,
}
