// Internal File, not part of the Public API
//
// Translates the single [Tool]/[ParameterSpecification] source into native
// provider function-calling payloads. Unknown parameter types pass through
// verbatim so provider-side extensions never break the translation.

import 'package:yaseen_ai_agent/src/tools/param_spec.dart';
import 'package:yaseen_ai_agent/src/tools/tool.dart';

/// JSON Schema fragment for one tool parameter.
Map<String, dynamic> _paramSchema(ParameterSpecification p) {
  return {
    'type': p.type,
    'description': p.description,
    if (p.enumValues != null && p.enumValues!.isNotEmpty) 'enum': p.enumValues,
  };
}

/// OpenAI `tools` entry for [tool].
Map<String, dynamic> openAiToolSchema(Tool tool) {
  final properties = <String, dynamic>{
    for (final p in tool.parameters) p.name: _paramSchema(p),
  };
  return {
    'type': 'function',
    'function': {
      'name': tool.name,
      'description': tool.description,
      'parameters': {
        'type': 'object',
        'properties': properties,
        'required': [
          for (final p in tool.parameters)
            if (p.required) p.name,
        ],
      },
    },
  };
}

/// Gemini `functionDeclarations` entry for [tool].
Map<String, dynamic> geminiToolSchema(Tool tool) {
  final properties = <String, dynamic>{
    for (final p in tool.parameters) p.name: _paramSchema(p),
  };
  return {
    'name': tool.name,
    'description': tool.description,
    'parameters': {
      'type': 'object',
      'properties': properties,
      'required': [
        for (final p in tool.parameters)
          if (p.required) p.name,
      ],
    },
  };
}
