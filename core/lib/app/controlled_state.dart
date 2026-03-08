import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';

/// ControlledState is widget state with a State manager `store` (usualy a Bloc instance)
abstract class ControlledState<
  TWidget extends StatefulWidget,
  TStore extends Object
>
    extends State<TWidget> {
  /// Get the state manager instance from dependencies injection map
  final TStore store = Core.get<TStore>();

  /// Whether this widget owns the store and should close it on dispose.
  /// Defaults to false since most stores are shared singletons.
  bool get ownsStore => false;

  @override
  void dispose() {
    if (ownsStore && store is Bloc) {
      (store as Bloc).close();
    }
    super.dispose();
  }
}
