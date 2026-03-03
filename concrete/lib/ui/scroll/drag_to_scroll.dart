import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class DraggableScroll extends StatelessWidget {
  final Widget child;
  const DraggableScroll({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch, PointerDeviceKind.trackpad}),
      child: child,
    );
  }
}
