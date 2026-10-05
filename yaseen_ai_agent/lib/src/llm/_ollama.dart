// Internal File, not part of the Public API

import 'dart:typed_data';

import 'package:yaseen_ai_agent/src/llm/_openai.dart';
import 'package:yaseen_ai_agent/src/llm/llm.dart';
import 'package:yaseen_ai_agent/src/llm/llm_config.dart';
import 'package:yaseen_ai_agent/src/tools/tool.dart';
import 'package:dio/dio.dart';

/// Ollama provider for local development, transported over its
/// OpenAI-compatible endpoint (`/v1/chat/completions`).
///
/// Local models use the JSON-text fallback path ([supportsNativeTools] is
/// false): tool specs travel in the prompt and repair retries cover weak
/// instruction-following.
class Ollama extends LLM {
  final OpenAI _inner;

  /// Creates an Ollama instance.
  Ollama({
    required String modelName,
    LlmConfig config = const LlmConfig(timeout: Duration(seconds: 120)),
    String baseUrl = 'http://localhost:11434/v1',
    Dio? client,
  }) : _inner = OpenAI(
         apiKey: 'ollama',
         modelName: modelName,
         config: config.copyWith(jsonMode: false),
         baseUrl: baseUrl,
         client: client,
       );

  @override
  String get modelId => _inner.modelId;

  @override
  LlmConfig get config => _inner.config;

  @override
  bool get supportsNativeTools => false;

  @override
  Future<String> generate({
    required String prompt,
    String? systemInstruction,
    Uint8List? rawData,
    String mimeType = 'image/jpeg',
    List<Tool>? tools,
  }) => _inner.generate(
    prompt: prompt,
    systemInstruction: systemInstruction,
    rawData: rawData,
    mimeType: mimeType,
    // Ignored: local models use the JSON-text fallback path.
  );

  @override
  Stream<String> generateStream({
    required String prompt,
    String? systemInstruction,
    Uint8List? rawData,
    String mimeType = 'image/jpeg',
    List<Tool>? tools,
  }) => _inner.generateStream(
    prompt: prompt,
    systemInstruction: systemInstruction,
    rawData: rawData,
    mimeType: mimeType,
  );
}
