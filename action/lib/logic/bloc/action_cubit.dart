import 'package:skeleton/skeleton.dart';

part 'action_state.dart';

class ActionCubit
    extends
        MyBaseCubit<
          BaseApiService<dynamic, dynamic, dynamic, dynamic>,
          ActionState
        > {
  ApiResponse? action;

  ActionCubit() : super(bs: ActionState());

  void runAction(ActionRequest request) async {
    try {
      emit(ActionHandlingState());
      // Unified call using callFunction instead of deprecated handleAction
      final data = (await handle(
        http().callFunction(
          request.action,
          params: {
            ...request.payload ?? {},
            '_type_': request.type,
            '_keys_': request.keys,
            if (request.filter != null) ...request.filter!,
          },
        ),
      ));
      emit(ActionHandledState(data));
    } catch (e) {
      emit(mapErrorToState(e));
    }
  }
}
