import 'package:core/core.dart';
import 'package:flutter/widgets.dart';

/// Data model for URL path and query parameters in navigation.
class NavState {
  final Map<String, String>? pathParams;
  final Map<String, String>? queryParams;
  final Object? extra;
  const NavState({this.pathParams, this.queryParams, this.extra});
}

/// Data model for defining an application route.
class NavRoute {
  final String name; // required for labels
  final String path;
  final Widget Function(BuildContext context, NavState state) builder;
  final List<NavRoute> routes;
  final bool isPrimary;
  bool isHidden;

  // New properties for the adaptive shell
  final IconData? icon;
  final IconData? selectedIcon;

  NavRoute({
    required this.path,
    required this.name,
    required this.builder,
    this.routes = const <NavRoute>[],
    this.icon, // If provided, this route is a top-level shell destination
    this.selectedIcon,
    this.isPrimary = false,
    this.isHidden = false,
  });
}

//
//
// Default Navigation Handler
//
//

class AppNavigator {
  static String? current = '/';

  String get path =>
      ModalRoute.of(Core.navigatorKey.currentState!.context)?.settings.name ??
      current ??
      '/';

  Map<String, String> queryParams() => throw UnimplementedError();
  Map<String, String> pathParams() => throw UnimplementedError();

  //
  //
  // === CLEAR & REPLACE
  //
  //

  void navigate(String path, {dynamic arguments}) {
    current = path;
    Core.navigatorKey.currentState?.pushReplacementNamed(
      path,
    ); // This action replaces all past routes
  }

  //
  //
  // === PUSH
  //
  //

  Future<T?>? push<T extends Object?>(String location, {Object? extra}) =>
      throw UnimplementedError();

  Future<T?>? pushRoute<T extends Object?>(Route<T> route) {
    current = null;
    return Core.navigatorKey.currentState?.push<T>(route);
  }

  Future<T?>? pushNamed<T extends Object?>(
    String name, {
    Map<String, String> pathParams = const <String, String>{},
    Map<String, dynamic> queryParams = const <String, dynamic>{},
    Object? extra,
  }) {
    current = name; // ?
    return Core.navigatorKey.currentState?.pushNamed<T>(name, arguments: extra);
  }

  //
  //
  // === POP
  //
  //

  bool canPop() => Core.navigatorKey.currentState?.canPop() ?? false;

  void pop<T extends Object?>([T? result]) {
    current = null;
    Core.navigatorKey.currentState?.pop<T?>(result);
  }

  Future<T?>? popAndPushNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    TO? result,
    Object? arguments,
    bool forRoot = false,
  }) {
    current = routeName;
    return Core.navigatorKey.currentState?.popAndPushNamed<T, TO>(
      routeName,
      result: result,
      arguments: arguments,
    );
  }

  void popUntil(bool Function(Route<dynamic>) predicate) {
    current = null;
    Core.navigatorKey.currentState?.popUntil(predicate);
  }

  //
  //
  // === PUSH REPLACEMENT
  //
  //

  void pushReplacement(String location, {Object? extra}) =>
      throw UnimplementedError();

  Future<T?>? pushReplacementRoute<T extends Object?>(Route<T> route) =>
      Core.navigatorKey.currentState?.pushReplacement<T, Object?>(route);

  Future<T?>? pushReplacementNamed<T>(
    String name, {
    Map<String, String> pathParams = const <String, String>{},
    Map<String, dynamic> queryParams = const <String, dynamic>{},
    Object? extra,
  }) {
    current = name;
    return Core.navigatorKey.currentState?.pushReplacementNamed<T, Object?>(
      name,
      result: extra,
      arguments: {...pathParams, ...queryParams},
    );
  }
}
