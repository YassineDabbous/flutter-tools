import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A widget that acts as an authentication guard for the [child] widget,
/// using Bloc/Cubit state to determine visibility and enforce redirection.
class Authenticity extends StatefulWidget {
  final Widget child;
  final Widget? guest;
  final bool strict;
  final Function(AuthResponse?)? onChecked;
  final bool Function(AuthResponse)? condition;

  /// **Soft Mode:** Shows [guest] if not authenticated, executes [onChecked], but avoids forced redirection.
  const Authenticity.soft({
    super.key,
    this.onChecked,
    this.condition,
    this.guest = const Guest(),
    required this.child,
  }) : strict = false,
       assert(guest != null);

  /// **Hard Mode:** Performs mandatory redirection if the auth state conflicts with the current route.
  const Authenticity.hard({super.key, required this.child})
    : strict = true,
      guest = null,
      onChecked = null,
      condition = null;

  @override
  State<Authenticity> createState() => _AuthenticityState();
}

class _AuthenticityState
    extends ControlledState<Authenticity, AuthCheckerCubit> {
  bool isGuestPath = false;

  /// Listener for the 'hard' enforcement mode. This mode forces navigation
  /// away from protected or guest-only routes based on the current auth state.
  void listenerHard(BuildContext context, AuthCheckerState state) {
    isGuestPath = Core.get<R>().isGuestPath(Core.nav.path);

    if (state is AuthIdentified) {
      // If user is logged in and on a guest-only route (e.g., /login), redirect to home.
      if (isGuestPath) {
        Core.nav.pushReplacement(Core.get<R>().redirectAfterLogin);
      }
    } else if (state is AuthNotIdentified) {
      // If user is logged out and on a protected route, redirect to the appropriate logout page.
      if (!isGuestPath) {
        final redirectRoute = state.hard
            ? Core.get<R>().redirectAfterHardLogout
            : Core.get<R>().redirectAfterLogout;
        Core.nav.pushReplacement(redirectRoute);
      }
    } else if (state is AuthCheckingFailure) {
      logAuth.debug('AuthCheckingFailure: ${state.message}');
    } else if (state is AuthChecking) {
      logAuth.debug('HARD: AuthCheckerState: AuthChecking ...');
    } else {
      throw UnimplementedError('HARD: AuthCheckerState type not detected');
    }
  }

  /// Listener for the 'soft' enforcement mode. This mode executes a callback
  /// ([onChecked]) upon auth state change but does not force navigation.
  void listenerSoft(BuildContext context, AuthCheckerState state) {
    if (state is AuthIdentified) {
      // Executes callback with the authenticated user data.
      widget.onChecked?.call(state.auth);
    } else if (state is AuthNotIdentified) {
      // Executes callback with null if not identified.
      widget.onChecked?.call(null);
    } else if (state is AuthCheckingFailure) {
      logAuth.debug('AuthCheckingFailure: ${state.message}');
    } else {
      logAuth.debug(
        'Authenticity.listenerSoft (unhandled state) • ==> ${state.runtimeType}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Initializes the AuthCheckerCubit and immediately triggers the check operation.
      create: (context) => store..check(),
      child: BlocListener<AuthCheckerCubit, AuthCheckerState>(
        // Selects the appropriate listener based on the widget's strictness setting.
        listener: widget.strict ? listenerHard : listenerSoft,
        child: BlocBuilder<AuthCheckerCubit, AuthCheckerState>(
          builder: (BuildContext context, AuthCheckerState state) {
            if (state is AuthChecking) {
              // Show a loading indicator while the authentication check is in progress.
              return const CircularProgressIndicator();
            } else if (state is AuthNotIdentified) {
              // If not identified, show guest UI if the path is protected, otherwise show the child (e.g., login screen).
              return !isGuestPath
                  ? (widget.guest ?? const Guest())
                  : widget.child;
            } else if (state is AuthIdentified || widget.strict) {
              // If authenticated, or if in hard mode (where non-auth users are already redirected).
              if (widget.condition != null) {
                // Apply an optional permission/role check on the authenticated user.
                if (!widget.condition!.call((state as AuthIdentified).auth)) {
                  // If condition fails, display the guest fallback.
                  return widget.guest!;
                }
              }
              // If all checks pass, display the protected content.
              return widget.child;
            }
            // Fallback for unexpected states during the authentication process.
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('|> Unhandled AuthCheckerState: ${state.runtimeType} <|'),
                widget.guest ?? const Guest(),
              ],
            );
          },
        ),
      ),
    );
  }
}
