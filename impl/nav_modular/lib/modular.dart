// import 'package:core/core.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_modular/flutter_modular.dart';

// class ModularNav implements DefaultNav {
//   @override
//   Map<String, String> queryParams(BuildContext context) => Modular.args.queryParams;

//   @override
//   Map<String, String> pathParams(BuildContext context) => Modular.args.params.map((key, value) => MapEntry(key, "$value"));

//   @override
//   String get path => Modular.to.path;
//   @override
//   void navigate(String path, {dynamic arguments}) => Modular.to.navigate(path, arguments: arguments); // This action replaces all past routes

//   @override
//   void popUntil(bool Function(Route<dynamic>) predicate) => Modular.to.popUntil(predicate);

//   @override
//   void pop<T extends Object?>([T? result]) => Modular.to.pop<T?>(result);

//   @override
//   Future<T?>? pushRoute<T extends Object?>(Route<T> route) => Modular.to.push<T>(route);

//   @override
//   Future<T?>? push<T extends Object?>(String location, {Object? extra}) => Modular.to.pushNamed<T>(location, arguments: extra);

//   @override
//   Future<T?> pushNamed<T extends Object?>(
//     String name, {
//     Map<String, String> pathParams = const <String, String>{},
//     Map<String, dynamic> queryParams = const <String, dynamic>{},
//     Object? extra,
//   }) => throw UnimplementedError();

//   @override
//   Future<T?>? popAndPushNamed<T extends Object?, TO extends Object?>(String routeName, {TO? result, Object? arguments, bool forRoot = false}) =>
//       Modular.to.popAndPushNamed<T, TO>(routeName, result: result, arguments: arguments, forRoot: forRoot);

//   @override
//   Future<T?>? pushReplacement<T>(String location, {Object? extra}) {
//     Modular.to.pushReplacementNamed<T, Object?>(location, arguments: extra);
//   }
// }
