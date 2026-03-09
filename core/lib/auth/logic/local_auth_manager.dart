import 'dart:convert';
import 'package:meta/meta.dart';

import 'package:core/core.dart';

/// Access singleton [AuthLocalManager].
AuthLocalManager auth() => Core.get<AuthLocalManager>();

/// Asynchronously retrieve current user.
Future<AuthResponse?> user() => auth().getCurrentUser();

/// Manages local persistence for authentication data and defines backend auth actions.
///
/// It handles two main tokens:
/// 1. The token of the currently active profile ([currentUser.token]).
/// 2. The root token used to manage and switch between multiple profiles ([realToken]).
abstract class AuthLocalManager {
  static const String _kKeyCurrentUser = 'current_user';
  static const String _kKeyRealToken = 'real_token';

  AuthResponse<dynamic>? currentUser;
  final SharedPrefHelper _prefs;

  /// Root token for managing associated profiles.
  String? realToken;

  AuthLocalManager({SharedPrefHelper? prefs})
    : _prefs = prefs ?? Core.get<SharedPrefHelper>();

  /// Load user data. Call at app startup.
  Future<void> init() async {
    await getCurrentUser();
  }

  // --- Backend Action Methods (To be implemented by Providers) ---

  /// Performs backend login and updates local state on success.
  Future<AuthResponse> login({required String email, required String password});

  /// Performs backend registration.
  Future<AuthResponse> register({required Map<String, dynamic> data});

  /// Performs backend password recovery.
  Future<void> forgotPassword(String email);

  /// General purpose sign-in with a specific scheme (OAuth, OTP, etc.)
  Future<void> signInWithScheme(String scheme, {Map<String, dynamic>? params}) {
    throw UnimplementedError(
      'signInWithScheme not implemented for this provider',
    );
  }

  // --- Local Persistence Logic ---

  /// Sets primary user (initial login). Saves both active profile and root token.
  @mustCallSuper
  Future setAuth(AuthResponse<dynamic> auth) async {
    currentUser = auth;
    await setRealAuthToken(auth.token);
    await setCurrentUser(auth);

    Core.get<I>().refresh();
    logAuth.debug('DONE --------------------- USER SAVED LOCALLY');
  }

  /// Sets user when switching profiles. Updates active profile only; root token remains.
  @mustCallSuper
  Future setSwitchAccount(AuthResponse<dynamic> auth) async {
    currentUser = auth;
    await setCurrentUser(auth);
    logAuth.debug('DONE --------------------- USER SAVED LOCALLY');
  }

  /// Clears active profile but keeps root token (allows re-listing profiles).
  @mustCallSuper
  Future<void> logout() async {
    currentUser = null;
    await _prefs.remove(_kKeyCurrentUser);
  }

  /// Clears active profile and root token.
  @mustCallSuper
  Future<void> hardLogout() async {
    await logout();
    await _prefs.remove(_kKeyRealToken);
  }

  bool check() => currentUser != null;

  bool guest() => !check();

  /// Returns in-memory user or loads from SharedPreferences.
  Future<AuthResponse?> getCurrentUser() async {
    logAuth.debug(
      "-------------- Fetching CURRENT_USER from SharedPreferences ... ---------------",
    );

    if (currentUser != null) {
      logAuth.debug("-------------- USER ALREADY LOGGED ---------------");
      return currentUser;
    }

    logAuth.debug(
      "-------------- checking if prefs containsKey current_user ---------------",
    );
    if (_prefs.containsKey(_kKeyCurrentUser)) {
      String s = _prefs.get<String>(_kKeyCurrentUser)!;
      currentUser = AuthResponse.fromJson(json.decode(s));
      logAuth.debug(
        "---------------------------------------------------------",
      );
      logAuth.info("-------------- found user in SharedPrefs! ---------------");
      logAuth.debug(
        "---------------------------------------------------------",
      );
    } else {
      logAuth.warning("-------------- NO USER LOGGED ---------------");
    }
    return currentUser;
  }

  Future setCurrentUser(AuthResponse user) async {
    try {
      await _prefs.set<String>(_kKeyCurrentUser, json.encode(user.toJson()));
    } catch (e) {
      throw Exception(e);
    }
  }

  /// Updates local user name/photo and persists.
  Future<bool> updateCurrentUser({String? name, String? photo}) async {
    final current = await getCurrentUser();
    if (current != null) {
      if (name != null) current.user.name = name;
      if (photo != null) current.user.photo = photo;

      setCurrentUser(current);
      return true;
    }
    return false;
  }

  // --- Real Token Management ---

  Future<String?> getRealAuthToken() async {
    realToken = _prefs.get<String>(_kKeyRealToken);
    return realToken;
  }

  Future setRealAuthToken(String token) async {
    realToken = token;
    await _prefs.set<String>(_kKeyRealToken, token);
  }

  /// Updates the token for the current user and persists it.
  Future<void> updateToken(String newToken) async {
    if (currentUser != null) {
      currentUser!.token = newToken;
      await setCurrentUser(currentUser!);
    }
  }
}
