/// An abstract base class defining the contract for a real-time notification
/// or messaging service adapter.
///
/// Implementations handle the specifics of initialization, subscription,
/// and unsubscription from topics, events, or users.
abstract class Notifier {
  /// Initializes the underlying notification mechanism (e.g., setting up FCM,
  /// connecting to a WebSocket).
  Future init();

  /// Unsubscribes the user from all global and personalized topics/events.
  /// Should be called during a full application logout.
  ///
  /// @returns true if the logout and unsubscription were successful.
  Future<bool> logout();

  /// Subscribes to a specific event stream or topic associated with a user or entity ID.
  ///
  /// @param id The ID of the user or entity to subscribe to (e.g., user ID, group ID).
  /// @returns true if the subscription was successful.
  Future<bool> subscribe(int id);

  /// Unsubscribes only the given ID from its associated topic/event stream.
  /// Useful for leaving a specific chat room or event listener without a full logout.
  ///
  /// @param id The ID of the topic, user, or entity to stop listening to.
  /// @returns true if the removal was successful.
  Future<bool> unsubscribe(int id);

  /// Subscribes to a specific, predefined topic or tag (e.g., 'news_updates', 'system_alerts').
  ///
  /// @param tag The string identifier for the topic or broadcast channel.
  /// @returns true if the subscription was successful.
  Future<bool> subscribeTo(String tag);

  /// Unsubscribes from a specific, predefined topic or tag.
  ///
  /// @param tag The string identifier for the topic or broadcast channel.
  /// @returns true if the unsubscription was successful.
  Future<bool> unSubscribeFrom(String tag);
}
