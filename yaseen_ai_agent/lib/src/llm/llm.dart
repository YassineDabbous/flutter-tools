import 'dart:async';
import 'dart:typed_data';

import 'package:yaseen_ai_agent/src/llm/_anthropic.dart';
import 'package:yaseen_ai_agent/src/llm/_cohere.dart';
import 'package:yaseen_ai_agent/src/llm/_custom.dart';
import 'package:yaseen_ai_agent/src/llm/_gemini.dart';
import 'package:yaseen_ai_agent/src/llm/_ollama.dart';
import 'package:yaseen_ai_agent/src/llm/_openai.dart';
import 'package:yaseen_ai_agent/src/llm/_rebelo_proxy.dart';
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

  /// Whether this provider prefers structured `role`/`content` messages over
  /// the flattened text [prompt].
  ///
  /// When true, the agent calls [generateWithMessages] /
  /// [generateStreamWithMessages] instead of [generate] / [generateStream].
  /// Defaults to false: legacy single-prompt providers are unaffected.
  bool get prefersStructuredHistory => false;

  /// Structured-messages variant of [generate].
  ///
  /// The default implementation flattens `system` roles into
  /// [generate]'s `systemInstruction` and renders the rest as
  /// `role: content` lines, so providers that only implement the legacy path
  /// keep working unchanged.
  Future<String> generateWithMessages({
    required List<Map<String, String>> messages,
    Uint8List? rawData,
    String mimeType = 'image/jpeg',
    List<Tool>? tools,
  }) {
    final flat = flattenChatMessages(messages);
    return generate(
      prompt: flat.prompt,
      systemInstruction: flat.system.isEmpty ? null : flat.system,
      rawData: rawData,
      mimeType: mimeType,
      tools: tools,
    );
  }

  /// Structured-messages variant of [generateStream].
  ///
  /// Same flattening default as [generateWithMessages]; structured providers
  /// override for true message-based streaming.
  Stream<String> generateStreamWithMessages({
    required List<Map<String, String>> messages,
    Uint8List? rawData,
    String mimeType = 'image/jpeg',
    List<Tool>? tools,
  }) async* {
    final flat = flattenChatMessages(messages);
    yield* generateStream(
      prompt: flat.prompt,
      systemInstruction: flat.system.isEmpty ? null : flat.system,
      rawData: rawData,
      mimeType: mimeType,
      tools: tools,
    );
  }

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

  /// Creates a custom [LLM] from plain callbacks, without subclassing.
  ///
  /// Provide [generate] and/or [generateWithMessages]; the missing sides
  /// derive via the base-class flattening rules. Streaming callbacks are
  /// optional and fall back to single-chunk generation.
  static LLM custom({
    required String modelId,
    LlmConfig config = const LlmConfig(),
    bool supportsNativeTools = false,
    bool prefersStructuredHistory = false,
    LlmGenerateFn? generate,
    LlmStreamFn? generateStream,
    LlmMessagesGenerateFn? generateWithMessages,
    LlmMessagesStreamFn? generateStreamWithMessages,
  }) => DelegatingLLM(
    modelId: modelId,
    config: config,
    supportsNativeTools: supportsNativeTools,
    prefersStructuredHistory: prefersStructuredHistory,
    generate: generate,
    generateStream: generateStream,
    generateWithMessages: generateWithMessages,
    generateStreamWithMessages: generateStreamWithMessages,
  );

  /// Creates a Rebelo AI-proxy-backed [LLM] instance.
  ///
  /// Unlike the direct providers, authentication comes from the injected
  /// [client] (the app's authenticated Dio: `Auth`/`Refresh` interceptors
  /// attach the Sanctum token, `Tenant-Id`, and locale headers), so there is
  /// no API key parameter. Pass the app Dio — or a fake Dio in tests.
  /// [baseUrl] is only used when [client] is null, to build an owned client.
  static LLM rebeloProxy({
    Dio? client,
    String? baseUrl,
    LlmConfig config = const LlmConfig(timeout: Duration(seconds: 180)),
  }) => RebeloProxy(client: client, baseUrl: baseUrl, config: config);
}
