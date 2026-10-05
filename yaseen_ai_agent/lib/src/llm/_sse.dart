// Internal File, not part of the Public API
//
// Shared SSE frame parser for streaming providers (OpenAI, Gemini).

import 'dart:convert';
import 'dart:typed_data';

/// Parses an SSE byte stream into decoded JSON objects (`data: {...}` lines).
///
/// Malformed frames are skipped; `[DONE]` terminators are ignored. Callers
/// must fail themselves when zero objects arrive.
Stream<Map<String, dynamic>> sseJsonObjects(Stream<Uint8List> bytes) async* {
  var buffer = '';
  await for (final chunk in bytes) {
    buffer += String.fromCharCodes(chunk);
    final lines = buffer.split('\n');
    buffer = lines.removeLast();
    for (final line in lines) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('data:')) continue;
      final payload = trimmed.substring(5).trim();
      if (payload.isEmpty || payload == '[DONE]') continue;
      try {
        final decoded = json.decode(payload);
        if (decoded is Map<String, dynamic>) yield decoded;
      } catch (_) {
        // Skip malformed SSE frames; the caller detects empty streams.
      }
    }
  }
}
