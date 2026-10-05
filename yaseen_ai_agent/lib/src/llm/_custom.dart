// Internal File, not part of the Public API
//
// Generic custom-provider hook: any HTTP backend can act as an [LLM] without
// forking this package by delegating to plain callbacks (see [LLM.custom]).

import 'dart:async';
import 'dart:typed_data';

import 'package:yaseen_ai_agent/src/llm/llm.dart';
import 'package:yaseen_ai_agent/src/llm/llm_config.dart';
import 'package:yaseen_ai_agent/src/tools/tool.dart';

/// Text-prompt callback backing [DelegatingLLM.generate].
typedef LlmGenerateFn =
    Future<String> Function({
      required String prompt,
      String? systemInstruction,
      Uint8List? rawData,
      String mimeType,
      List<Tool>? tools,
    });

/// Text-prompt streaming callback backing [DelegatingLLM.generateStream].
typedef LlmStreamFn =
    Stream<String> Function({
      required String prompt,
      String? systemInstruction,
      Uint8List? rawData,
      String mimeType,
      List<Tool>? tools,
    });

/// Structured-messages callback backing [DelegatingLLM.generateWithMessages].
typedef LlmMessagesGenerateFn =
    Future<String> Function({
      required List<Map<String, String>> messages,
      Uint8List? rawData,
      String mimeType,
      List<Tool>? tools,
    });

/// Structured-messages streaming callback backing
/// [DelegatingLLM.generateStreamWithMessages].
typedef LlmMessagesStreamFn =
    Stream<String> Function({
      required List<Map<String, String>> messages,
      Uint8List? rawData,
      String mimeType,
      List<Tool>? tools,
    });

/// Flattens structured `role`/`content` messages into the legacy
/// `(systemInstruction, prompt)` pair. `system` roles merge into the
/// instruction; everything else renders as `role: content` lines.
({String system, String prompt}) flattenChatMessages(
  List<Map<String, String>> messages,
) {
  final system = [
    for (final m in messages)
      if (m['role'] == 'system') (m['content'] ?? ''),
  ].where((s) => s.isNotEmpty).join('\n\n');
  final prompt = [
    for (final m in messages)
      if (m['role'] != 'system')
        '${m['role'] ?? 'user'}: ${m['content'] ?? ''}',
  ].join('\n');
  return (system: system, prompt: prompt);
}

/// An [LLM] implemented by caller-provided callbacks.
///
/// At least one generate callback is required; streaming falls back to a
/// single chunk from the generate path (same rule as [LLM.generateStream]),
/// and the structured path falls back to flattening (same rule as
/// [LLM.generateWithMessages]).
class DelegatingLLM extends LLM {
  final String _modelId;
  final LlmConfig _config;
  final bool _supportsNativeTools;
  final bool _prefersStructuredHistory;
  final LlmGenerateFn? _generate;
  final LlmStreamFn? _stream;
  final LlmMessagesGenerateFn? _generateMessages;
  final LlmMessagesStreamFn? _streamMessages;

  /// Creates a delegating LLM. Provide [generate] and/or
  /// [generateWithMessages]; the missing sides derive from the other via the
  /// base-class flattening rules.
  DelegatingLLM({
    required String modelId,
    LlmConfig config = const LlmConfig(),
    bool supportsNativeTools = false,
    bool prefersStructuredHistory = false,
    LlmGenerateFn? generate,
    LlmStreamFn? generateStream,
    LlmMessagesGenerateFn? generateWithMessages,
    LlmMessagesStreamFn? generateStreamWithMessages,
  }) : assert(
         generate != null || generateWithMessages != null,
         'DelegatingLLM needs at least one generate callback.',
       ),
       _modelId = modelId,
       _config = config,
       _supportsNativeTools = supportsNativeTools,
       _prefersStructuredHistory = prefersStructuredHistory,
       _generate = generate,
       _stream = generateStream,
       _generateMessages = generateWithMessages,
       _streamMessages = generateStreamWithMessages;

  @override
  String get modelId => _modelId;

  @override
  LlmConfig get config => _config;

  @override
  bool get supportsNativeTools => _supportsNativeTools;

  @override
  bool get prefersStructuredHistory => _prefersStructuredHistory;

  @override
  Future<String> generate({
    required String prompt,
    String? systemInstruction,
    Uint8List? rawData,
    String mimeType = 'image/jpeg',
    List<Tool>? tools,
  }) {
    final fn = _generate;
    if (fn == null) {
      throw StateError(
        'DelegatingLLM($modelId) has no generate callback; '
        'provide generate or generateWithMessages.',
      );
    }
    return fn(
      prompt: prompt,
      systemInstruction: systemInstruction,
      rawData: rawData,
      mimeType: mimeType,
      tools: tools,
    );
  }

  @override
  Stream<String> generateStream({
    required String prompt,
    String? systemInstruction,
    Uint8List? rawData,
    String mimeType = 'image/jpeg',
    List<Tool>? tools,
  }) async* {
    final fn = _stream;
    if (fn == null) {
      yield await generate(
        prompt: prompt,
        systemInstruction: systemInstruction,
        rawData: rawData,
        mimeType: mimeType,
        tools: tools,
      );
      return;
    }
    yield* fn(
      prompt: prompt,
      systemInstruction: systemInstruction,
      rawData: rawData,
      mimeType: mimeType,
      tools: tools,
    );
  }

  @override
  Future<String> generateWithMessages({
    required List<Map<String, String>> messages,
    Uint8List? rawData,
    String mimeType = 'image/jpeg',
    List<Tool>? tools,
  }) {
    final fn = _generateMessages;
    if (fn != null) {
      return fn(
        messages: messages,
        rawData: rawData,
        mimeType: mimeType,
        tools: tools,
      );
    }
    final flat = flattenChatMessages(messages);
    return generate(
      prompt: flat.prompt,
      systemInstruction: flat.system.isEmpty ? null : flat.system,
      rawData: rawData,
      mimeType: mimeType,
      tools: tools,
    );
  }

  @override
  Stream<String> generateStreamWithMessages({
    required List<Map<String, String>> messages,
    Uint8List? rawData,
    String mimeType = 'image/jpeg',
    List<Tool>? tools,
  }) async* {
    final fn = _streamMessages;
    if (fn != null) {
      yield* fn(
        messages: messages,
        rawData: rawData,
        mimeType: mimeType,
        tools: tools,
      );
      return;
    }
    final flat = flattenChatMessages(messages);
    yield* generateStream(
      prompt: flat.prompt,
      systemInstruction: flat.system.isEmpty ? null : flat.system,
      rawData: rawData,
      mimeType: mimeType,
      tools: tools,
    );
  }
}
