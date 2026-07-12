/// Used as a base class for the final app routes class.
///
/// Defines all common, globally accessible URL paths for navigation.
abstract class R {
  const R();

  // --- Core Application Routes ---
  /// The root path of the main application content.
  final String contentRootRoute = '/';
  final String homeRoute = '/home';
  final String onboardingRoute = '/onboarding';

  // ##########################################################################
  // ############################# SETTINGS ROUTES ##############################
  // ##########################################################################

  /// Base path for all settings pages.
  final String settingsRootRoute = '/settings';

  final String themesRoute = '/themes';
  String settingsThemes() => settingsRootRoute + themesRoute;

  final String settingsNotificationsRoute = '/notifications';
  String settingsNotifications() =>
      settingsRootRoute + settingsNotificationsRoute;

  final String settingsLanguagesRoute = '/languages';
  String settingsLanguages() => settingsRootRoute + settingsLanguagesRoute;

  final String settingsServerConfigRoute = '/server';
  String settingsServerConfig() =>
      settingsRootRoute + settingsServerConfigRoute;

  // ##########################################################################
  // ############################# AUTHENTICATION ROUTES ########################
  // ##########################################################################

  /// Base path for all authentication flows.
  final String authRootRoute = '/auth';

  final String loginRoute = '/login';
  String login() => authRootRoute + loginRoute;
  final String registerRoute = '/register';
  String register() => authRootRoute + registerRoute;
  final String passwordRoute = '/password';
  String password() => authRootRoute + passwordRoute;
  final String passwordForgetRoute = '/password/forget';
  String passwordForget() => authRootRoute + passwordForgetRoute;
  final String passwordResetRoute = '/password/reset';
  String passwordReset() => authRootRoute + passwordResetRoute;

  final String otpRoute = '/otp';
  String otp() => authRootRoute + otpRoute;

  final String socialAuthRoute = '/social';
  String socialAuth() => authRootRoute + socialAuthRoute;

  final String accountsRoute = '/accounts';
  String accounts() => authRootRoute + accountsRoute;

  // --- Redirection and Guards ---

  /// The default path to navigate to after a successful login.
  String get redirectAfterLogin =>
      '$homeRoute?r=${DateTime.now().millisecondsSinceEpoch}';

  /// The default path to redirect to after a soft logout.
  String get redirectAfterLogout => login();

  /// The default path to redirect to after a hard/forced logout.
  String get redirectAfterHardLogout => login();

  /// List of routes accessible to unauthenticated (guest) users.
  List<String> get guest => [
    login(),
    register(),
    otp(),
    socialAuth(),
    passwordForget(),
    passwordReset(),
    //password(),
  ];

  /// Checks if a [path] is an exact match for a guest route.
  bool isGuestPath(String path) =>
      guest.where((element) => path == element).isNotEmpty;

  /// Checks if a [path] starts with the prefix of any guest route.
  bool guestContains(String path) =>
      guest.where((element) => path.startsWith(element)).isNotEmpty;
}
