import 'package:flutter/widgets.dart';
import 'package:skeleton/skeleton.dart';

// Abstract Form widget
abstract class EditForm<TModel extends Jsonable, TRequest extends SuperModel<TRequest>, TMaker extends BaseMaker<TModel, TRequest>> extends StatefulWidget {
  /// extends [Maker]
  final TMaker maker;

  /// Validation messages map
  final Map<String, dynamic>? validation;

  /// Editable model fields
  final List<String>? fields;

  /// Constructor
  const EditForm({super.key, required this.maker, this.validation, this.fields});
}

// State helper for the Form widget
mixin FormHandler<TModel extends Jsonable, TRequest extends SuperModel<TRequest>, TMaker extends BaseMaker<TModel, TRequest>> on State<EditForm<TModel, TRequest, TMaker>> {
  final GlobalKey<FormState> formkey = GlobalKey<FormState>();
  Map<String, String>? validation;

  @override
  void initState() {
    fillForm();
    widget.maker.validate = validate;
    widget.maker.fill = fillMaker;
    _syncValidation();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant EditForm<TModel, TRequest, TMaker> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the validation map changed, re-sync the local map
    if (widget.validation != oldWidget.validation) {
      _syncValidation();
    }
  }

  void _syncValidation() {
    setState(() {
      validation = widget.validation?.map((k, v) {
        if (v is Iterable) return MapEntry(k, v.join(', '));
        return MapEntry(k, v.toString());
      });
    });
  }

  

  /// Specify whether a field should be visible in the creat/edit form.
  bool isVisibleField(String f) => (widget.fields == null) || (widget.fields!.contains(f)) || (widget.validation?.containsKey(f) ?? false);

  bool isHiddenField(String f) => !isVisibleField(f);

  /// Validate form
  bool validate() => formkey.currentState!.validate();

  /// Fill form inputs from `Maker` instance
  /// Triggered on init state.
  void fillForm();

  /// Fill `Maker` from form inputs.
  /// Triggered on form submit.
  void fillMaker();
}
