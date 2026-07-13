import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:core/core.dart';

/// Implementation of [AuthLocalManager] for Supabase GoTrue Auth.
class SupabaseAuthManager extends AuthLocalManager {
  final sb.SupabaseClient client;

  SupabaseAuthManager(this.client) : super();

  @override
  bool check() => client.auth.currentSession != null;

  Future<AuthResponse<dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final auth = _mapSupabaseAuth(response);
    await setAuth(auth);
    return auth;
  }

  Future<AuthResponse<dynamic>> register({
    required Map<String, dynamic> data,
  }) async {
    final response = await client.auth.signUp(
      email: data['email'],
      password: data['password'],
      data: data['data'],
    );
    final auth = _mapSupabaseAuth(response);
    await setAuth(auth);
    return auth;
  }

  Future<void> forgotPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  Future<void> logout() async {
    await client.auth.signOut();
    await clearAuth();
  }

  Future<void> hardLogout() async {
    await client.auth.signOut();
    await clearAuthHard();
  }

  AuthResponse<dynamic> _mapSupabaseAuth(sb.AuthResponse response) {
    final user = response.user!;
    return AuthResponse(
      user: AuthUser(
        id: user.id,
        type: 'user',
        name: user.userMetadata?['full_name'] ?? user.email ?? 'Unknown',
        photo:
            user.userMetadata?['avatar_url'] ??
            user.userMetadata?['profile_picture_url'],
      ),
      token: response.session?.accessToken ?? '',
      abilities: ['*'],
      permissions: [],
    );
  }

  Future<AuthResponse<dynamic>?> fetchRemoteUser() async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    return _mapSupabaseAuth(sb.AuthResponse(user: user, session: client.auth.currentSession));
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await client.auth.updateUser(sb.UserAttributes(
      email: data['email'] as String?,
      password: data['password'] as String?,
      data: data['data'] as Map<String, dynamic>?,
    ));
  }

  Future<void> changePassword(Map<String, dynamic> data) async {
    await client.auth.updateUser(sb.UserAttributes(
      password: data['new_password'] as String?,
    ));
  }

  /// Listen to Supabase auth changes and update the local state.
  void listenToAuthChanges() {
    client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        // Optionially sync local user if session is present but currentUser is null
      } else {
        clearAuth();
      }
    });
  }
}
