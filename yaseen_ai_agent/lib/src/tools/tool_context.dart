// Execution context passed to tools alongside their validated parameters.
//
// New cross-cutting concerns (cancellation in Phase 2, tracing later) land
// here so [Tool.run] never breaks its signature again.
class ToolContext {
  /// Opaque per-call metadata forwarded from [Agent.generateResponse].
  final Object? metaData;

  /// Creates a [ToolContext].
  const ToolContext({this.metaData});
}
