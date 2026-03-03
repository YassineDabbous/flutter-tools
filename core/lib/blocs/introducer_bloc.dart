import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

/// Represents the persistence model for tracking user introduction/onboarding status.
class IntroducerModel {
  /// True if the user has completed or skipped the initial onboarding flow.
  bool onboarding;

  IntroducerModel({this.onboarding = false});

  Map<String, dynamic> toJson() => {'onboarding': onboarding};

  factory IntroducerModel.fromJson(Map<String, dynamic> json) => IntroducerModel(onboarding: json['onboarding'] as bool? ?? false);
}

/// Manages the state of the app's onboarding and feature introduction status.
class IntroducerBloc extends Cubit<IntroducerState> {
  final SharedPrefHelper prefHelper;

  /// Initializes the Cubit with [IntroducerInitialState].
  IntroducerBloc({required this.prefHelper}) : super(const IntroducerInitialState());

  /// Loads the persisted [IntroducerModel] from storage and emits [IntroducerLoadedState].
  /// Defaults to a new [IntroducerModel] if none is found.
  Future getIntroducer() async {
    final introducer = prefHelper.getIntroducer();
    emit(IntroducerLoadedState(introducer: introducer ?? IntroducerModel()));
  }

  /// Persists the new [IntroducerModel] to storage and emits [IntroducerLoadedState].
  Future setIntroducer(IntroducerModel introducer) async {
    await prefHelper.saveIntroducer(introducer);
    emit(IntroducerLoadedState(introducer: introducer));
  }

  /// Sets the `onboarding` flag to true and saves the updated model.
  Future skipOnboarding() async {
    final introducer = (prefHelper.getIntroducer()) ?? IntroducerModel();
    introducer.onboarding = true;
    await prefHelper.saveIntroducer(introducer);
  }
}

//
// --- States ---
//

/// Base class for all states emitted by [IntroducerBloc].
class IntroducerState extends Equatable {
  const IntroducerState();
  @override
  List<Object> get props => [];
}

/// Initial state when the Cubit is first created.
class IntroducerInitialState extends IntroducerState {
  const IntroducerInitialState();
}

/// State emitted when the [IntroducerModel] has been loaded or updated.
class IntroducerLoadedState extends IntroducerState {
  final IntroducerModel introducer;
  const IntroducerLoadedState({required this.introducer});
  @override
  List<Object> get props => [introducer];
}
