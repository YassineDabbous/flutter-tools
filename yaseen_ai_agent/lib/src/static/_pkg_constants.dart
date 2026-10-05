/// Default response when LLM fails
const String kLLMResponseOnFailure =
    "I am unable to process your request at the moment. Please try again later";

/// Maximum number of tool→observe→re-prompt iterations per turn.
const int kMaxToolIterations = 5;

/// Maximum number of corrective re-prompts when the LLM returns unparseable output.
const int kMaxParseRetries = 2;

/// Corrective instruction appended on parse-retry turns.
const String kParseRetryInstruction =
    "Your last reply was not valid JSON. Reply with ONLY the JSON object, no prose, no markdown fences.";

/// Maximum depth for agent chain delegation (prevents unbounded recursion).
const int kMaxChainDepth = 5;

/// Delay before the single retry on transient provider `503`s (observed live
/// on Gemini 2026-10-05). Exactly one replay per call; mid-stream replays are
/// skipped once any chunk was yielded.
const Duration kProviderServerRetryDelay = Duration(seconds: 2);

/// Soft budget for one rendered text prompt (characters).
///
/// When exceeded, the builder truncates the rolling summary first, then drops
/// the oldest history messages. Tool specs are never truncated.
const int kMaxPromptChars = 12000;

/// Soft budget for the rolling summary section (characters).
const int kMaxSummaryChars = 2000;

/// Hard cap on the number of `role`/`content` messages per request for
/// structured wire providers (matches the Rebelo AI proxy contract).
const int kWireMaxMessages = 20;

/// Hard cap on characters per `role`/`content` message for structured wire
/// providers (matches the Rebelo AI proxy contract).
const int kWireMaxChars = 4000;

/// Hard cap on total characters across all `role`/`content` messages per
/// request for structured wire providers (matches the Rebelo AI proxy
/// contract). When exceeded, oldest history drops first; system text is
/// never cut.
///
/// Single place for all backend wire numbers: when the backend raises its
/// caps, editing these three constants is the whole change.
const int kWireTotalChars = 32000;
