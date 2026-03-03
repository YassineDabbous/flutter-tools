import 'package:core/core.dart'; // Assumes AuthResponse is defined here

/// An abstract contract for services that require initialization and
/// management based on the application's authentication status.
///
/// Services implementing [I] should be managed by the application's service locator.
abstract class I {
  const I();

  /// Initializes the service, preparing it for operation (e.g., loading configurations).
  Future init();

  /// Forces the service to re-read its current state or settings and update accordingly.
  void refresh();

  /// Activates the service for a successfully logged-in user, often involving
  /// token setup or personalized listener subscriptions.
  ///
  /// @param user The [AuthResponse] of the currently logged-in user.
  void activate({required AuthResponse user});

  /// Deactivates the service upon user logout (soft or hard), typically by
  /// clearing tokens or unsubscribing from personalized topics.
  ///
  /// @param user Optional [AuthResponse] of the user who logged out.
  void deactivate({AuthResponse? user});
}
