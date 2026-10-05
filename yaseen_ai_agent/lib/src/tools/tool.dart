// This is the blueprint for the Tool class.
// It defines the structure and behavior that all tools should implement.
// It includes the name, description, and parameters of the tool.
// The run method is an abstract method that must be implemented by all tools.

import 'package:yaseen_ai_agent/src/tools/param_spec.dart';
import 'package:yaseen_ai_agent/src/tools/tool_context.dart';
import 'package:yaseen_ai_agent/src/tools/tool_response.dart';

/// Approval policy for a tool call requested by the LLM.
enum ToolApproval {
  /// Execute immediately when requested.
  auto,

  /// Pause the turn with a [PendingApproval]; executes only after
  /// [Agent.resumeWithApproval] approves. All money-moving tools use this.
  requireApproval,
}

/// The Tool class is an abstract class that defines the structure and behavior of a tool.
/// It includes the name, description, and parameters of the tool.
abstract class Tool {
  /// The name of the tool.
  final String name;

  /// A short description of what the tool does.
  final String description;

  /// The parameters that the tool accepts.
  final List<ParameterSpecification> parameters;

  /// Whether the LLM may invoke this tool freely ([ToolApproval.auto]) or
  /// must pause for human approval first (`requireApproval`, resumed via
  /// `Agent.resumeWithApproval`).
  final ToolApproval approval;

  /// Constructs a Tool with the required fields.
  Tool({
    required this.name,
    required this.description,
    this.parameters = const [],
    this.approval = ToolApproval.auto,
  });

  /// Executes the tool with the given validated parameters.
  ///
  /// **Idempotency contract:** if this tool has observable side effects
  /// (writes to a database, sends a message, charges a card), implementations
  /// SHOULD be idempotent — use upsert semantics, a natural key, or an
  /// explicit idempotency token in the parameters. The framework guards
  /// against duplicate `(name, params)` invocations within a single turn,
  /// but it cannot detect semantically-equivalent calls with different
  /// parameter shapes, so this contract is the final line of defence.
  Future<ToolResponse> run(Map<String, dynamic> params);

  /// Context-aware entry point used by the framework. Defaults to [run] so
  /// existing tools compile untouched; override when the tool needs the
  /// [ToolContext] (cancellation, tracing).
  Future<ToolResponse> runWithContext(
    Map<String, dynamic> params,
    ToolContext context,
  ) => run(params);
}
