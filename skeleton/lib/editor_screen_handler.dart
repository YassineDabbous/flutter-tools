import 'package:core/core.dart';
import 'package:skeleton/skeleton.dart';
import 'package:flutter/material.dart';

mixin EditorHandler<
  TModel extends Jsonable,
  TRequest extends SuperModel<TRequest>,
  TMaker extends BaseMaker<TModel, TRequest>,
  TWidget extends StatefulWidget,
  TBind extends Object
>
    on ControlledState<TWidget, TBind> {
  late TMaker maker;

  @override
  void initState() {
    // maker.id == null || maker.id == 0 || maker.id == ''
    if (maker.id.isEmpty) {
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
