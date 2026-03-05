import 'package:skeleton/skeleton.dart';

part 'action_state.dart';

class ActionCubit extends MyBaseBloc<ActionApiService, ActionState> {
  ApiResponse? action;

  ActionCubit() : super(bs: ActionState());

  void runAction(ActionRequest request) async {
    try {
      emit(ActionHandlingState());
      final data = (await handle(http().handleAction(request)));
      emit(ActionHandledState(data));
    } catch (e) {
      emit(mapErrorToState(e));
    }
  }
}
