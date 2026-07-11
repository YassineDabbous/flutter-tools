import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GoRouterNav implements AppNavigator {
  GoRouter get router => GoRouter.of(Core.navigatorKey.currentContext!);
  // RouteMatch get state => router.routerDelegate.currentConfiguration.last;

  static GoRoute navtoGoRoute(NavRoute route) {
    return GoRoute(
      path: route.path,
      name: route.name,
      // Convert GoRouterState to your custom NavState
      builder: (context, state) {
        final navState = NavState(
          pathParams: state.pathParameters,
          queryParams: state.uri.queryParameters,
        );
        return route.builder(context, navState);
      },
      // Recursively build sub-routes
      routes: route.routes.map((e) => navtoGoRoute(e)).toList(),
    );
    // return GoRoute(
    //   path: route.path,
    //   name: route.name,
    //   builder: (context, state) => route.builder(context, NavState(pathParams: state.pathParameters, queryParams: state.uri.queryParameters)),
    // );
  }

  @override
  String get path => router.state.uri.toString();

  @override
  Map<String, String> queryParams() => router.state.uri.queryParameters;

  @override
  Map<String, String> pathParams() => router.state.pathParameters;

  //
  //
  // === CLEAR & REPLACE
  //
  //

  @override
  void navigate(String path, {dynamic arguments}) {
    Core.ctx?.go(path);
  }

  //
  //
  // === PUSH
  //
  //

  @override
  Future<T?>? push<T extends Object?>(String location, {Object? extra}) =>
      Core.ctx?.push<T>(location, extra: extra);

  @override
  Future<T?>? pushRoute<T extends Object?>(Route<T> route) {
    return Core.navigatorKey.currentState?.push<T>(route);
  }

  @override
  Future<T?>? pushNamed<T extends Object?>(
    String name, {
    Map<String, String> pathParams = const <String, String>{},
    Map<String, dynamic> queryParams = const <String, dynamic>{},
    Object? extra,
  }) {
    return Core.ctx?.pushNamed<T>(
      name,
      pathParameters: pathParams,
      queryParameters: queryParams,
      extra: extra,
    );
  }

  //
  //
  // === POP
  //
  //

  @override
  bool canPop() => Core.ctx?.canPop() ?? false;

  @override
  void pop<T extends Object?>([T? result]) => Core.ctx?.pop<T?>(result);

  @override
  void popUntil(bool Function(Route<dynamic>) predicate) =>
      Core.navigatorKey.currentState?.popUntil(predicate);

  @override
  Future<T?>? popAndPushNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    TO? result,
    Object? arguments,
    bool forRoot = false,
  }) {
    Core.ctx?.pop<TO?>(result);
    return Core.ctx?.pushNamed<T>(
      routeName,
      pathParameters: arguments as Map<String, String>,
    );
  }

  //
  //
  // === PUSH REPLACEMENT
  //
  //

  @override
  void pushReplacement(String location, {Object? extra}) =>
      Core.ctx?.pushReplacement(location, extra: extra);

  @override
  Future<T?>? pushReplacementRoute<T extends Object?>(Route<T> route) =>
      Core.navigatorKey.currentState?.pushReplacement<T, Object?>(route);

  @override
  Future<T?>? pushReplacementNamed<T>(
    String name, {
    Map<String, String> pathParams = const <String, String>{},
    Map<String, dynamic> queryParams = const <String, dynamic>{},
    Object? extra,
  }) {
    Core.ctx?.pushReplacementNamed(
      name,
      pathParameters: pathParams,
      queryParameters: queryParams,
      extra: extra,
    );
    return null;
  }
}
