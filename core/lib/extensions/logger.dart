import 'package:loggy/loggy.dart';

/// Defines loggy mixins for categorization.
mixin AuthLoggy implements LoggyType {
  @override
  Loggy<AuthLoggy> get loggy => Loggy<AuthLoggy>('Auth - ${runtimeType.toString()}');
}
mixin ControlLoggy implements LoggyType {
  @override
  Loggy<ControlLoggy> get loggy => Loggy<ControlLoggy>('CTRL - ${runtimeType.toString()}');
}
mixin UiLoggy implements LoggyType {
  @override
  Loggy<UiLoggy> get loggy => Loggy<UiLoggy>('UI - ${runtimeType.toString()}');
}
mixin NetworkLoggy implements LoggyType {
  @override
  Loggy<NetworkLoggy> get loggy => Loggy<NetworkLoggy>('Network - ${runtimeType.toString()}');
}

/// Extension on [Object] to provide quick access to categorized loggers.
extension Lg on Object {
  Loggy<ControlLoggy> get logCtrl => Loggy<ControlLoggy>('CTRL - ${runtimeType.toString()}');
  Loggy<AuthLoggy> get logAuth => Loggy<AuthLoggy>('AUTH - ${runtimeType.toString()}');
  Loggy<UiLoggy> get logUI => Loggy<UiLoggy>('UI - ${runtimeType.toString()}');
  Loggy<NetworkLoggy> get logNet => Loggy<NetworkLoggy>('Network - ${runtimeType.toString()}');
}
