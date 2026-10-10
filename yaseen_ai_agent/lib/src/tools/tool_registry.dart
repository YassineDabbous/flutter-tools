import 'package:yaseen_ai_agent/src/static/yaseen_ai_agent_exceptions.dart';

import 'tool.dart';

/// Tool Registry for managing tools available to a single agent.
/// Each agent owns its own [ToolRegistry] instance.
/// It provides methods to register a tool, unregister a tool, get a tool by name, and check if a tool exists.
class ToolRegistry {
  final Map<String, Tool> _tools = {};

  /// Active domain groups advertised in the prompt for the current turn.
  /// Null (default) means every registered tool is advertised. Execution
  /// always resolves from the full set, so an unadvertised tool the model
  /// calls anyway still runs — narrowing the prompt never removes
  /// capability, it only focuses attention.
  Set<String>? _activeGroups;

  /// This method should be called whenever developers make a new tool.
  /// It registers the tool in the registry.
  /// If you miss this step, the tool won't be available for use.
  void registerTool(Tool tool) {
    if (hasTool(tool.name)) {
      throw ConfigException(
        'Tool with name ${tool.name} already exists. Do not register the same tool twice. Use a different name.',
      );
    }
    _tools[tool.name] = tool;
  }

  /// This method should be called whenever developers want to remove a tool.
  /// It unregisters the tool from the registry.
  void unregisterTool(String toolName) {
    _tools.remove(toolName);
  }

  /// This method gets a tool by its name.
  /// It is used by the agent to find the tool it needs.
  /// If the tool is not found, it returns null.
  Tool? getTool(String toolName) {
    return _tools[toolName];
  }

  /// This method gets all the tools in the registry.
  /// It is used by prompt builders to list all available tools.
  List<Tool> getAllTools() {
    return _tools.values.toList();
  }

  /// Narrows the prompt to [groups] for the next turn(s). Pass null to
  /// advertise everything again. Never affects execution: [getTool] always
  /// resolves from the full set.
  void setActiveGroups(Set<String>? groups) {
    _activeGroups = groups == null || groups.isEmpty ? null : {...groups};
  }

  /// Clears any narrowing set via [setActiveGroups]: everything advertised.
  void clearActiveGroups() => _activeGroups = null;

  /// Currently active groups, or null when the full set is advertised.
  Set<String>? get activeGroups =>
      _activeGroups == null ? null : Set.unmodifiable(_activeGroups!);

  /// Tools to render in the prompt: the active groups when narrowed,
  /// otherwise the full set. Falls back to the full set when narrowing
  /// would advertise nothing (unknown group key) — a turn must never show
  /// zero tools.
  List<Tool> getAdvertisedTools() {
    final groups = _activeGroups;
    if (groups == null) return getAllTools();
    final advertised = _tools.values.where((t) => groups.contains(t.group));
    return advertised.isEmpty ? getAllTools() : advertised.toList();
  }

  /// This method checks if a tool is registered in the registry.
  bool hasTool(String toolName) {
    return _tools.containsKey(toolName);
  }
}
