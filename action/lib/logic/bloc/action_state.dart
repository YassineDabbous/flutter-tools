part of 'action_bloc.dart';

class ActionState extends MyBaseState<dynamic> {
  @override
  List<Object> get props => [];

  @override
  error({required String error, int code = 0}) => ActionErrorState(message: error);

  @override
  get initial => ActionInitialState();

  @override
  validation(Map<String, dynamic> bag) => ActionValidationErrorState(bag: bag);
}

class ActionInitialState extends ActionState {}

//
//
//

class ActionHandlingState extends ActionState {}

class ActionHandledState extends ActionState {
  final BasicResponse data;
  ActionHandledState(this.data);
  @override
  List<Object> get props => [data];
}

//
//
//

class ActionValidationErrorState extends ActionState {
  final Map<String, dynamic> bag;

  ActionValidationErrorState({required this.bag});

  @override
  List<Object> get props => [bag];
}

class ActionErrorState extends ActionState {
  final String message;

  ActionErrorState({required this.message});

  @override
  List<Object> get props => [error];
}
