import 'package:concrete/concrete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeleton/skeleton.dart';
import 'package:action/action.dart';

abstract class ActionForm<TAction extends BaseAction> extends StatefulWidget {
  final TAction action;
  // final Map<String, dynamic>? validation;
  const ActionForm({
    super.key,
    required this.action,
    // this.validation,
  });
}

mixin ActionHandler<TAction extends BaseAction> on ControlledState<ActionForm<TAction>, ActionCubit> {
  final GlobalKey<FormState> formkey = GlobalKey<FormState>();
  @override
  void initState() {
    // widget.action.validateAction = () => formkey.currentState!.validate();
    // widget.action.fillAction = fillAction;
    // widget.action.runAction = runAction;
    super.initState();
  }

  void fillAction();

  bool validateAction() => formkey.currentState?.validate() ?? true;

  void _runAction() {
    store.runAction(widget.action.request());
  }

  Future<void> runAction() async {
    if (widget.action.requireConfirmation) {
      // show confirmation alert
      await dialogConfirmation(context: context, onConfirm: () => _runAction());
    } else {
      _runAction();
    }
  }

  Future<void> listener(BuildContext context, ActionState state) async {
    logUI.debug('○○○ Listener: new state ${state.runtimeType}');
    if (state is ActionHandlingState) {
    } else if (state is ActionErrorState) {
      showSnackBar(context, state.message);
    } else if (state is ActionValidationErrorState) {
      showSnackBar(context, 'validation error');
    } else if (state is ActionHandledState) {
      // if (mounted) {
      //   Navigator.of(context).pop();
      // }
      // widget.action.onHandled?.call(state.data.data);
      // await dialogInfoSuccess(context: context);
    } else {
      showSnackBar(context, 'unhandled action in this screen');
    }
  }

  bool get showActionView;
  Widget? actionView(BuildContext context, ActionState state);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: BlocProvider(
        create: (context) => store,
        child: BlocListener<ActionCubit, ActionState>(
          listener: listener,
          // child: BlocBuilder<ActionCubit, ActionState>(builder: (context, state) => actionView(context, state)),
          child: BlocBuilder<ActionCubit, ActionState>(
            builder: (context, state) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: Edges.md,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(widget.action.title?.i18n() ?? widget.action.route.i18n(), textAlign: TextAlign.start, style: context.textTheme.titleLarge),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.action.description != null)
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Text(
                                      widget.action.description!.replaceAll(':count', '${widget.action.controller.selectedIds.length}').i18n(),
                                      textAlign: TextAlign.start,
                                      style: context.textTheme.bodyMedium,
                                    ),
                                  ),
                                const Divider(),
                                if (state is ActionValidationErrorState) ValidationMessage(bag: state.bag),
                                // if (widget.action.formBuilder != null) ...[
                                //   const SizedBox(height: Sz.md),
                                //   Expanded(
                                //     child: SingleChildScrollView(child: widget.action.formBuilder!.call(widget.action)),
                                //   ),
                                //   const Divider(),
                                //   const SizedBox(height: Sz.md),
                                // ],
                                if (showActionView) ...[
                                  const SizedBox(height: Sz.md),
                                  Expanded(child: SingleChildScrollView(child: actionView(context, state))),
                                  const Divider(),
                                  const SizedBox(height: Sz.md),
                                ],
                                if (state is ActionErrorState) Message.error(message: state.message),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              TextButton.icon(
                                label: Text('confirm'.i18n()),
                                icon: const Icon(Icons.done, color: Colors.green),
                                onPressed: () {
                                  // if (widget.action.validateAction?.call() ?? false) {
                                  //   widget.action.fillAction?.call();
                                  //   widget.action.runAction?.call();
                                  if (validateAction()) {
                                    fillAction();
                                    runAction();
                                  } else {
                                    showSnackBar(context, 'unvalid form');
                                  }
                                },
                              ),
                              TextButton.icon(
                                label: Text('cancel'.i18n()),
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (state is ActionHandlingState)
                    Positioned.fill(
                      child: Container(
                        color: Colors.grey[300],
                        child: Center(child: const CircularProgressIndicator()),
                      ),
                    ),
                  if (state is ActionHandledState)
                    Positioned.fill(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              const Icon(Icons.done_all, size: 80, color: Colors.green),
                              Text(state.data.message ?? '', textAlign: TextAlign.center),
                              if (widget.action.onHandled != null)
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    widget.action.onHandled?.call(state.data.data);
                                  },
                                  child: Text('ok'.i18n()),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
