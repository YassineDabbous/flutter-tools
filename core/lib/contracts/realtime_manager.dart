/// Standard interface for realtime communication.
abstract class RealtimeManager {
  /// Sends a broadcast message to a specific channel.
  Future<void> broadcast(String channel, Map<String, dynamic> payload);

  /// Synchronizes presence data for a specific channel.
  Stream<PresenceState> trackPresence(String channel);
}

/// Represents the state of users currently "present" in a channel.
class PresenceState {
  final Map<String, List<PresenceInfo>> users;
  const PresenceState(this.users);
}

class PresenceInfo {
  final String presenceRef;
  final Map<String, dynamic> metadata;
  const PresenceInfo({required this.presenceRef, required this.metadata});
}
