// Execution context passed to tools alongside their validated parameters.
//
// New cross-cutting concerns land here so [Tool.run] never breaks its
// signature again.

/// Cooperative cancellation token for one agent turn.
///
/// The module cancels on PTT-release, wake-word barge-in, sheet dispose, or
/// navigation away. The agent checks [isCancelled] at every loop step and
/// before every tool run; providers bridge it to Dio `CancelToken`s
/// internally. Single-shot: [cancel] is idempotent.
class CancellationToken {
  bool _cancelled = false;

  /// Whether [cancel] has been called.
  bool get isCancelled => _cancelled;

  /// Creates an uncancelled [CancellationToken].
  CancellationToken();

  /// A pre-cancelled token (tests, already-dead sessions).
  CancellationToken.cancelled() : _cancelled = true;

  /// Signals cancellation. Idempotent.
  void cancel() => _cancelled = true;
}

/// Execution context passed to tools alongside their validated parameters.
class ToolContext {
  /// Opaque per-call metadata forwarded from [Agent.generate].
  final Object? metaData;

  /// Cooperative cancellation for this turn, if any.
  final CancellationToken? cancelToken;

  /// Creates a [ToolContext].
  const ToolContext({this.metaData, this.cancelToken});
}
