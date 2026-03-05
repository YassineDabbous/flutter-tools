import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core/core.dart';

/// Bridges Supabase GoTrue Auth with Core's AuthLocalManager.
class SupabaseAuthBridge extends AuthLocalManager {
  final SupabaseClient client;

  SupabaseAuthBridge(this.client) : super();

  @override
  bool check() => client.auth.currentSession != null;

  @override
  Future<void> logout() async {
    await client.auth.signOut();
    super.logout();
  }

  /// Listen to Supabase auth changes and update the local state.
  void listenToAuthChanges() {
    client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        // We can manually populate the local user if needed, 
        // but often we just rely on the Supabase session.
      } else {
        super.logout();
      }
    });
  }
}
