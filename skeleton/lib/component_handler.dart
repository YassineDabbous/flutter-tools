import 'package:core/core.dart';
import 'package:flutter/widgets.dart';

abstract class ComponentHandler<TModel, TState> {
  /// User action listener
  void onAction(TModel item, UserAction action, {int index = -1});

  void setController();

  /// Builds a ListView Or any scrollable data container
  Widget listBuilder(BuildContext context, TState state);

  // Widget itemBuilder(context, index);
}
