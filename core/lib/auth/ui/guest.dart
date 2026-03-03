import 'package:core/core.dart';
import 'package:flutter/material.dart';

/// A widget that displays a 'Login' button and navigates to the login screen.
class Guest extends StatelessWidget {
  final String? message;
  const Guest({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          // Uses the centralized Core navigator to push the login route.
          Core.nav.push(Core.get<R>().login());
        },
        child: Text(message ?? 'login'.i18n()),
      ),
    );
  }
}
