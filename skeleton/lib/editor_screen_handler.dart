import 'package:core/core.dart';
import 'package:skeleton/skeleton.dart';
import 'package:flutter/material.dart';

mixin EditorHandler<
  TModel extends Jsonable,
  TRequest extends SuperModel<TRequest>,
  TMaker extends BaseMaker<TModel, TRequest, ID>,
  TWidget extends StatefulWidget,
  TBind extends Object,
  ID
>
    on ControlledState<TWidget, TBind> {
  late TMaker maker;

  @override
  void initState() {
    // Check if id is effectively "empty" for creation
    final id = maker.id;
    final isEmpty =
        id == null || (id is String && id.isEmpty) || (id is int && id == 0);

    if (isEmpty) {
      // creation screen can use query parameters as default values
      maker.fillFromQuery(Core.nav.queryParams());
    }
    super.initState();
  }

  void send() {
    if (maker.validate != null && maker.validate!()) {
      maker.fill!();
      save();
      // dialogConfirmation(context: context, title: 'are you sure to save'.i18n(), onConfirm: save);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('unvalid form'),
          action: SnackBarAction(label: 'Ok'.i18n(), onPressed: () {}),
        ),
      );
    }
  }

  // implemented in the widget state class or any other child mixin
  void save();
}
