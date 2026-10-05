import 'dart:async';
import 'dart:typed_data';

import 'package:yaseen_ai_agent/src/llm/_anthropic.dart';
import 'package:yaseen_ai_agent/src/llm/_cohere.dart';
import 'package:yaseen_ai_agent/src/llm/_gemini.dart';
import 'package:yaseen_ai_agent/src/llm/_ollama.dart';
import 'package:yaseen_ai_agent/src/llm/_openai.dart';
import 'package:yaseen_ai_agent/src/llm/llm_config.dart';
import 'package:yaseen_ai_agent/src/tools/tool.dart';
import 'package:dio/dio.dart';

/// The LLM interface defines the contract for all large language models used in the agent.
abstract class LLM {
  /// Generates a response based on the provided prompt and optional raw data.
  ///
  /// When [tools] is non-empty and [supportsNativeTools] is true, the
  /// provider sends them as native function declarations and serializes any
  /// native tool call back into the canonical JSON-text contract
  /// (`{"tools": ..., "parameters": ...}`) so the agent parser stays uniform.
  /// Providers without native support ignore [tools] (the prompt already
  /// carries the specs in fallback mode).
  Future<String> generate({
    required String prompt,
    String? systemInstruction,
    Uint8List? rawData,
    String mimeType = 'image/jpeg',
    List<Tool>? tools,
  });

  /// Streams partial text deltas. Default implementation yields a single chunk
  /// from [generate]; providers with SSE/NDJSON override for true streaming.
  /// When native [tools] resolve to a tool call, implementations yield the
  /// canonical JSON once (still a valid stream).
  Stream<String> generateStream({
    required String prompt,
    String? systemInstruction,
    Uint8List? rawData,
    String mimeType = 'image/jpeg',
    List<Tool>? tools,
  }) async* {
    yield await generate(
      prompt: prompt,
      systemInstruction: systemInstruction,
      rawData: rawData,
      mimeType: mimeType,
      tools: tools,
    );
  }

  /// Whether this provider sends [tools] natively instead of via prompt JSON.
  bool get supportsNativeTools;

  /// Returns the unique identifier for the model.
  String get modelId;

  /// Provider-neutral generation config.
  LlmConfig get config;

  /// Creates a Gemini-backed [LLM] instance.
  ///
  /// [client] is test-only: inject a fake [Dio] to answer without network.
  static LLM geminiLLM({
    required String apiKey,
    required String modelName,
    LlmConfig config = const LlmConfig(),
    Object? safetySettings,
    Dio? client,
  }) => Gemini(
    apiKey: apiKey,
    modelName: modelName,
    config: config,
    safetySettings: safetySettings,
    client: client,
  );

  /// Creates an Anthropic (Claude) backed [LLM] instance.
  ///
  /// [modelName] is the Claude model id, e.g. `claude-sonnet-4-5`.
  static LLM anthropicLLM({
    required String apiKey,
    required String modelName,
    LlmConfig config = const LlmConfig(),
  }) => Anthropic(apiKey: apiKey, modelName: modelName, config: config);

  /// Creates an OpenAI Chat-Completions backed [LLM] instance.
  ///
  /// [modelName] is e.g. `gpt-4o`. Pass [baseUrl] to use an OpenAI-compatible
  /// endpoint such as DeepSeek, Grok, Groq, or OpenRouter.
  /// [client] is test-only: inject a fake [Dio] to answer without network.
  static LLM openAiLLM({
    required String apiKey,
    required String modelName,
    LlmConfig config = const LlmConfig(),
    String baseUrl = 'https://api.openai.com/v1',
    Map<String, String> extraHeaders = const {},
    Dio? client,
  }) => OpenAI(
    apiKey: apiKey,
    modelName: modelName,
    config: config,
    baseUrl: baseUrl,
    extraHeaders: extraHeaders,
    client: client,
  );

  /// Creates an Ollama-backed [LLM] instance for local development.
  ///
  /// [modelName] is e.g. `llama3.1:8b`. [baseUrl] defaults to the standard
  /// local daemon (`http://localhost:11434/v1`, OpenAI-compatible). Weak local
  /// models use the JSON-text fallback path with repair retries.
  static LLM ollamaLLM({
    required String modelName,
    LlmConfig config = const LlmConfig(timeout: Duration(seconds: 120)),
    String baseUrl = 'http://localhost:11434/v1',
    Dio? client,
  }) => Ollama(
    modelName: modelName,
    config: config,
    baseUrl: baseUrl,
    client: client,
  );

  /// Creates a DeepSeek-backed [LLM] instance.
  ///
  /// [modelName] is e.g. `deepseek-chat` or `deepseek-reasoner`.
  /// Backed by the OpenAI-compatible Chat Completions API.
  static LLM deepseekLLM({
    required String apiKey,
    required String modelName,
    LlmConfig config = const LlmConfig(),
  }) => OpenAI(
    apiKey: apiKey,
    modelName: modelName,
    config: config,
    baseUrl: 'https://api.deepseek.com/v1',
  );

  /// Creates an xAI Grok-backed [LLM] instance.
  ///
  /// [modelName] is e.g. `grok-4`, `grok-4-mini`, or `grok-vision-beta`.
  /// Backed by the OpenAI-compatible Chat Completions API.
  static LLM grokLLM({
    required String apiKey,
    required String modelName,
    LlmConfig config = const LlmConfig(),
  }) => OpenAI(
    apiKey: apiKey,
    modelName: modelName,
    config: config,
    baseUrl: 'https://api.x.ai/v1',
  );

  /// Creates a Groq-backed [LLM] instance.
  ///
  /// [modelName] is e.g. `llama-3.3-70b-versatile`, `mixtral-8x7b-32768`,
  /// or `llama-3.2-90b-vision-preview`.
  /// Backed by the OpenAI-compatible Chat Completions API.
  static LLM groqLLM({
    required String apiKey,
    required String modelName,
    LlmConfig config = const LlmConfig(),
  }) => OpenAI(
    apiKey: apiKey,
    modelName: modelName,
    config: config,
    baseUrl: 'https://api.groq.com/openai/v1',
  );

  /// Creates a Mistral-backed [LLM] instance.
  ///
  /// [modelName] is e.g. `mistral-large-latest`, `open-mistral-nemo`,
  /// or `pixtral-large-latest` (vision).
  /// Backed by the OpenAI-compatible Chat Completions API.
  static LLM mistralLLM({
    required String apiKey,
    required String modelName,
    LlmConfig config = const LlmConfig(),
  }) => OpenAI(
    apiKey: apiKey,
    modelName: modelName,
    config: config,
    baseUrl: 'https://api.mistral.ai/v1',
  );

  /// Creates a Cohere-backed [LLM] instance.
  ///
  /// [modelName] is e.g. `command-r-plus-08-2024`, `command-r-08-2024`,
  /// or `command-light`.
  /// Multimodal input is not supported.
  static LLM cohereLLM({
    required String apiKey,
    required String modelName,
    LlmConfig config = const LlmConfig(),
  }) => Cohere(apiKey: apiKey, modelName: modelName, config: config);
}
