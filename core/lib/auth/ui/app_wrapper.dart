import 'package:core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A top-level wrapper widget designed to monitor global [AuthenticationCubit]
/// state changes and enforce application-wide navigation rules (e.g.,
/// immediate redirection upon login or logout).
class AppWrapper extends StatelessWidget {
  final Widget child;
  const AppWrapper({super.key, required this.child});

  /// Handles global authentication state changes and triggers mandatory navigation.
  void listener(BuildContext context, AuthenticationState state) {
    logAuth.info('APPWRAPPER state ${state.runtimeType}');
    final navPath = Core.nav.path;
    final R routes = Core.get<R>();

    if (state is AuthenticationAuthenticated) {
      // If authenticated and currently on a route meant for guests (login, register, etc.).
      if (routes.guest.contains(navPath) || navPath == routes.accounts()) {
        logAuth.info('Redirecting to: ${routes.redirectAfterLogin}');
        Core.get<I>().activate(
          user: state.auth,
        ); // Activate app services ('I' is the Initializer abstract class)
        Core.nav.popUntil(
          (r) => r.isFirst,
        ); // Clear the navigation history stack
        Core.nav.navigate(
          routes.redirectAfterLogin,
        ); // Redirect to the authenticated home path
      }
    } else if (state is AuthenticationLogout) {
      // Soft logout from current profile (profile token cleared, root account token remains).
      Core.get<I>()
          .deactivate(); // Deactivate app services ('I' is the Initializer abstract class)
      if (!routes.guest.contains(navPath)) {
        // Redirect to the soft logout page if the user was on a protected page.
        logAuth.info(
          'Redirecting to soft logout: ${routes.redirectAfterLogout}',
        );
        Core.nav.pushReplacement(routes.redirectAfterLogout);
      }
    } else if (state is AuthenticationLogoutHard) {
      // Hard logout from all saved profiles (all tokens cleared).
      Core.get<I>()
          .deactivate(); // Deactivate app services ('I' is the Initializer abstract class)
      if (!routes.guest.contains(navPath)) {
        // Redirect to the hard logout page if the user was on a protected page.
        logAuth.info(
          'Redirecting to hard logout: ${routes.redirectAfterHardLogout}',
        );
        Core.nav.pushReplacement(routes.redirectAfterHardLogout);
      }
    } else {
      throw UnimplementedError(
        'AuthenticationState type not detected in AppWrapper listener.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listens for authentication changes without rebuilding the widget tree below it.
    return BlocListener<AuthenticationCubit, AuthenticationState>(
      listener: listener,
      child: child,
    );
  }
}
