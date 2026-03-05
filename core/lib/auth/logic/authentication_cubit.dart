import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';

/// Manages the in-app authentication state and handles user actions
/// like login, logout, and account switching.
class AuthenticationCubit extends Cubit<AuthenticationState> {
  final AuthLocalManager repository;

  /// Initializes the BLoC and sets the initial state to [AuthenticationInitial].
  AuthenticationCubit({required this.repository}) : super(AuthenticationInitial());

  // --- State Modification Methods ---

  /// Handles a successful login event.
  void login(AuthResponse auth) async {
    await repository.setAuth(auth);
    emit(AuthenticationAuthenticated(auth: auth));
  }

  /// Handles switching to a different profile/account within the same root session.
  void switchTo(AuthResponse auth) async {
    await repository.setSwitchAccount(auth);
    emit(AuthenticationAuthenticated(auth: auth));
  }

  /// Performs a soft logout.
  void logout() async {
    await repository.logout();
    emit(AuthenticationLogout());
  }

  /// Performs a hard logout (complete session termination).
  void logoutHard() async {
    await repository.hardLogout();
    emit(AuthenticationLogoutHard());
  }

  /// Emits the [AuthenticationLogout] state without modifying local storage.
  void emitLogout() {
    logAuth.debug('○○○○○○○ emit Logout state ○○○○○○○');
    emit(AuthenticationLogout());
  }

  /// Emits the [AuthenticationLogoutHard] state without modifying local storage.
  void emitLogoutHard() {
    logAuth.debug('○○○○○○○ emit HardLogout state ○○○○○○○');
    emit(AuthenticationLogoutHard());
  }

  /// Performs a hard logout on the repository without emitting a new state.
  Future localLogout() async {
    await repository.hardLogout();
  }
}

// --- Authentication States ---

abstract class AuthenticationState extends Equatable {
  const AuthenticationState();

  @override
  List<Object?> get props => [];
}

class AuthenticationInitial extends AuthenticationState {}

class AuthenticationLogout extends AuthenticationState {}

class AuthenticationLogoutHard extends AuthenticationState {}

class AuthenticationAuthenticated extends AuthenticationState {
  final AuthResponse auth;
  const AuthenticationAuthenticated({required this.auth});

  @override
  List<Object?> get props => [auth];
}
