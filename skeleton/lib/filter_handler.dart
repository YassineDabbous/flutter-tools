import 'package:flutter/widgets.dart';
import 'package:skeleton/skeleton.dart';

abstract class FilterForm<TRequest extends SuperModel<TRequest>, TModel extends Jsonable, TController extends BaseController<TRequest, TModel>> extends StatefulWidget {
  final TController controller;
  final Map<String, dynamic>? validation;
  final List<String>? fields;
  const FilterForm({super.key, required this.controller, this.validation, this.fields});
}

mixin FilterHandler<TRequest extends SuperModel<TRequest>, TModel extends Jsonable, TController extends BaseController<TRequest, TModel>>
    on State<FilterForm<TRequest, TModel, TController>> {
  final GlobalKey<FormState> formkey = GlobalKey<FormState>();
  Map<String, String>? validation;


  @override
  void initState() {
    fillForm();

    widget.controller.validateFilter = () => formkey.currentState == null || formkey.currentState!.validate();

    widget.controller.fillFilter = fillFilter;

    widget.controller.clearForm = () => setState(() {
      formkey.currentState?.reset();
    });

    super.initState();
  }
  @override
  void didChangeDependencies() {
    validation = widget.validation?.map((k, v) {
      if (v is Iterable) {
        return MapEntry(k, v.join(', '));
      }
      return MapEntry(k, v.toString());
    });
    super.didChangeDependencies();
  }


  /// Specify whether a field should be visible in the search form.
  bool isVisibleField(String f) => (widget.fields == null) || (widget.fields!.contains(f)) || (widget.validation?.containsKey(f) ?? false);
  bool isHiddenField(String f) => !isVisibleField(f);

  /// Fill form inputs from `Controller.filter` instance
  /// Triggered on init state.
  void fillForm();

  /// Fill `Controller.filter` from form inputs.
  /// Triggered on form submit.
  void fillFilter();
}
