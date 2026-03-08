import 'package:flutter/material.dart';
import 'package:concrete/concrete.dart';
import 'package:action/action.dart';
import 'package:skeleton/skeleton.dart';

class ActionButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final GeneralAction action;
  final double? maxWidth;
  final double? maxHeight;

  const ActionButton({
    super.key,
    required this.action,
    required this.icon,
    required this.label,
    this.maxWidth,
    this.maxHeight,
  });
  factory ActionButton.delete({Key? key, required BaseController controller}) =>
      ActionButton(
        key: key,
        label: 'delete'.i18n(),
        icon: const Icon(Icons.delete),
        action: GeneralAction(
          controller: controller,
          route: 'delete'.i18n(),
          description: 'delete all selected items'.i18n(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: ElevatedButton.icon(
        icon: icon,
        label: Text(label),
        onPressed: () => dialogView(
          maxHeight: maxHeight ?? 200,
          maxWidth: maxWidth ?? 300,
          context: context,
          view: GeneralActionView(action: action),
        ),
      ),
    );
  }
}

class GeneralActionView extends ActionForm<GeneralAction> {
  const GeneralActionView({super.key, required super.action});

  @override
  State<ActionForm> createState() => _GeneralActionViewState();
}

class _GeneralActionViewState
    extends ControlledState<ActionForm<GeneralAction>, ActionCubit>
    with ActionHandler {
  @override
  fillAction() {}

  @override
  bool get showActionView => widget.action.formBuilder != null;

  @override
  Widget? actionView(BuildContext context, ActionState state) {
    return Form(
      key: formkey,
      child: widget.action.formBuilder!.call(widget.action),
    );
  }
}
