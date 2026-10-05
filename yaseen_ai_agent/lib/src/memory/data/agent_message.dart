// This file defines the AgentMessage class used to represent messages exchanged
// between an agent (e.g., AI chatbot) and a user.
// It supports text content, timestamps, agent identification, and optional image data or URL.

import 'dart:convert';
import 'dart:typed_data';

/// Represents a message in a conversation, either from the agent or the user.
/// It can optionally contain an image (as binary data or a URL).
class AgentMessage {
  /// The main text content of the message
  final String content;

  /// Timestamp when the message was generated
  final DateTime generatedAt;

  /// Indicates whether the message is from the agent (true) or user (false)
  final bool isFromAgent;

  /// Optional binary image data (e.g., for displaying inline)
  final Uint8List? imageData;

  /// MIME type of [imageData] (e.g. 'image/png', 'image/jpeg').
  final String mimeType;

  /// Optional URL to an image
  final String? imageUrl;

  /// Optional data associated with the message, this data is for internal use of the application and not for any extrnal use.
  final Map<String, dynamic>? data;

  /// When true, this message represents an error and should be excluded from
  /// conversation history sent to the LLM.
  final bool isError;

  /// When set, this message is a tool outcome: builders map it to the
  /// `tool_result` role (with `tool_name`, and `tool_call_id` when present)
  /// instead of `user`/`assistant`. Null for regular chat messages.
  final String? toolName;

  /// Provider call id linking this result to a parallel tool call, if any.
  /// Capped by backends (100 chars) — producers should keep it short.
  final String? toolCallId;

  /// Constructs an AgentMessage with required content and generatedAt,
  AgentMessage({
    required this.content,
    required this.generatedAt,
    required this.isFromAgent,
    this.imageData,
    this.mimeType = 'image/jpeg',
    this.imageUrl,
    this.data,
    this.isError = false,
    this.toolName,
    this.toolCallId,
  });

  /// Creates a tool-outcome message for history replay.
  factory AgentMessage.toolResult({
    required String toolName,
    required String content,
    String? toolCallId,
    DateTime? generatedAt,
  }) => AgentMessage(
    content: content,
    generatedAt: generatedAt ?? DateTime.now(),
    isFromAgent: true,
    toolName: toolName,
    toolCallId: toolCallId,
  );

  /// Builds one tool-outcome message per observation map
  /// (`{tool, success, message, data?}`, as produced by the agent loop).
  /// Content is JSON `{'success','message','data'?}` so replays are
  /// self-describing; falls back to the raw message when encoding fails.
  static List<AgentMessage> fromObservations(
    List<Map<String, dynamic>> observations,
  ) {
    final messages = <AgentMessage>[];
    for (final o in observations) {
      final tool = (o['tool'] ?? '').toString();
      if (tool.isEmpty) continue;
      final success = o['success'] == true;
      final message = (o['message'] ?? '').toString();
      String content;
      try {
        content = json.encode({
          'success': success,
          'message': message,
          if (o['data'] != null) 'data': o['data'],
        });
      } catch (_) {
        content = message;
      }
      messages.add(AgentMessage.toolResult(toolName: tool, content: content));
    }
    return messages;
  }

  /// Creates a copy of the current message with optional new values for each field
  AgentMessage copyWith({
    String? content,
    DateTime? generatedAt,
    bool? isFromAgent,
    Uint8List? imageData,
    String? mimeType,
    String? imageUrl,
    Map<String, dynamic>? data,
    bool? isError,
    String? toolName,
    String? toolCallId,
  }) {
    return AgentMessage(
      content: content ?? this.content,
      generatedAt: generatedAt ?? this.generatedAt,
      isFromAgent: isFromAgent ?? this.isFromAgent,
      imageData: imageData ?? this.imageData,
      mimeType: mimeType ?? this.mimeType,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      isError: isError ?? this.isError,
      toolName: toolName ?? this.toolName,
      toolCallId: toolCallId ?? this.toolCallId,
    );
  }

  /// Converts the message to a map (excluding `imageData`, which is not serializable)
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'content': content,
      'generatedAt': generatedAt.millisecondsSinceEpoch,
      'isFromAgent': isFromAgent,
      'mimeType': mimeType,
      'imageUrl': imageUrl,
      'data': data,
      'isError': isError,
      if (toolName != null) 'toolName': toolName,
      if (toolCallId != null) 'toolCallId': toolCallId,
    };
  }

  /// Constructs a message from a map (used for decoding from storage or network)
  factory AgentMessage.fromMap(Map<String, dynamic> map) {
    return AgentMessage(
      content: map['content'] as String,
      generatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['generatedAt'] as int,
      ),
      isFromAgent: map['isFromAgent'] as bool,
      mimeType: map['mimeType'] as String? ?? 'image/jpeg',
      imageUrl: map['imageUrl'] != null ? map['imageUrl'] as String : null,
      data: map['data'] as Map<String, dynamic>?,
      isError: map['isError'] as bool? ?? false,
      toolName: map['toolName'] as String?,
      toolCallId: map['toolCallId'] as String?,
    );
  }

  /// Converts the message to a JSON string
  String toJson() => json.encode(toMap());

  /// Parses a message from a JSON string
  factory AgentMessage.fromJson(String source) =>
      AgentMessage.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'AgentMessage(content: $content, generatedAt: $generatedAt, isFromAgent: $isFromAgent, imageData: $imageData, mimeType: $mimeType, imageUrl: $imageUrl, data: $data, isError: $isError, toolName: $toolName, toolCallId: $toolCallId)';
  }

  /// Equality check based on all fields
  @override
  bool operator ==(covariant AgentMessage other) {
    if (identical(this, other)) return true;

    return other.content == content &&
        other.generatedAt == generatedAt &&
        other.isFromAgent == isFromAgent &&
        _bytesEqual(other.imageData, imageData) &&
        other.mimeType == mimeType &&
        other.imageUrl == imageUrl &&
        _mapsEqual(other.data, data) &&
        other.isError == isError &&
        other.toolName == toolName &&
        other.toolCallId == toolCallId;
  }

  /// Pure-Dart equality helpers (no flutter dependency).
  static bool _bytesEqual(Uint8List? a, Uint8List? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _mapsEqual(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || b[key] != a[key]) return false;
    }
    return true;
  }

  /// Hash code based on all fields
  @override
  int get hashCode => Object.hash(
    content,
    generatedAt,
    isFromAgent,
    imageData != null ? Object.hashAll(imageData!) : null,
    mimeType,
    imageUrl,
    data != null ? Object.hashAll(data!.entries) : null,
    isError,
    toolName,
    toolCallId,
  );
}
