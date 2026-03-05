import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';

/// Handles the initial check of the user's authentication status upon application startup.
class AuthCheckerCubit extends Cubit<AuthCheckerState> {
  final AuthLocalManager repository;

  /// Initializes the Cubit and sets the initial state to [AuthCheckInitial].
  AuthCheckerCubit({required this.repository}) : super(AuthCheckInitial());

  /// Initiates the authentication check process.
  void check() async {
    emit(AuthChecking());
    try {
      final currentUser = await repository.getCurrentUser();
      final realToken = await repository.getRealAuthToken();

      if (realToken == null) {
        emit(AuthNotIdentified());
      } else if (currentUser != null) {
        emit(AuthIdentified(auth: currentUser));
      } else {
        emit(AuthNotIdentified(hard: false));
      }
    } catch (e) {
      emit(AuthCheckingFailure(message: e.toString()));
    }
  }
}

// --- Auth Checker States ---

abstract class AuthCheckerState extends Equatable {
  const AuthCheckerState();

  @override
  List<Object?> get props => [];
}

class AuthCheckInitial extends AuthCheckerState {}

class AuthChecking extends AuthCheckerState {}

class AuthIdentified extends AuthCheckerState {
  final AuthResponse auth;
  const AuthIdentified({required this.auth});

  @override
  List<Object?> get props => [auth];
}

class AuthNotIdentified extends AuthCheckerState {
  final bool hard;
  const AuthNotIdentified({this.hard = true});

  @override
  List<Object?> get props => [hard];
}

class AuthCheckingFailure extends AuthCheckerState {
  final String message;
  const AuthCheckingFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
