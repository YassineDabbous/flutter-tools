import 'package:core/core.dart';
import 'package:skeleton/skeleton.dart';
import 'package:action/action.dart';

part 'action_state.dart';

class ActionCubit extends MyBaseBloc<ActionApiService, ActionState> {
  BasicResponse? action;

  ActionCubit() : super(bs: ActionState());

  void runAction(ActionRequest request) async {
    try {
      emit(ActionHandlingState());
      final data = (await handleRoot(http().handleAction(request)));
      emit(ActionHandledState(data));
    } catch (e) {
      emit(mapErrorToState(e));
    }
  }
}
