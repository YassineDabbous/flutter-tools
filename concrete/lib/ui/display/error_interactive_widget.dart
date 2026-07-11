import 'package:flutter/material.dart';
import 'package:concrete/concrete.dart';

class InteractiveErrorWidget extends StatelessWidget {
  final Function()? onRefresh;
  final String? message;
  const InteractiveErrorWidget({super.key, this.onRefresh, this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (message != null) ...[Text(message!), const SizedBox(height: 32)],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: Text('back'.i18n()),
              onPressed: () => Core.nav.pop(context),
            ),
            const SizedBox(width: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text('refresh'.i18n()),
              onPressed: onRefresh,
            ),
          ],
        ),
      ],
    );
  }
}
