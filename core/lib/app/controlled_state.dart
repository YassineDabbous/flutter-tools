import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';

/// ControlledState is widget state with a State manager `store` (usualy a Bloc instance)
abstract class ControlledState<TWidget extends StatefulWidget, TStore extends Object> extends State<TWidget> {
  /// Get the state manager instance from dependencies injection map
  final TStore store = Core.get<TStore>();

  @override
  void dispose() {
    if (store is Bloc) {
      (store as Bloc).close();
    }
    super.dispose();
  }
}
