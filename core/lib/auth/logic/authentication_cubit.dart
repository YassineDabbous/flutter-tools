import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';

/// Manages the in-app authentication state and handles user actions
/// like login, logout, and account switching.
///
/// It relies on [AuthLocalManager] for persisting and retrieving user tokens.
class AuthenticationCubit extends Cubit<AuthenticationState> {
  final AuthLocalManager repository;

  /// Initializes the BLoC and sets the initial state to [AuthenticationInitial].
  AuthenticationCubit({required this.repository}) : super(AuthenticationInitial());

  // --- State Modification Methods ---

  /// Handles a successful login event.
  ///
  /// 1. Saves the full authentication response, including the token, to local storage
  ///    (and sets it as the root token).
  /// 2. Emits [AuthenticationAuthenticated].
  void login(AuthResponse auth) async {
    await repository.setAuth(auth);
    emit(AuthenticationAuthenticated(auth: auth));
  }

  /// Handles switching to a different profile/account within the same root session.
  ///
  /// 1. Saves the new profile's authentication response to local storage (keeping
  ///    the root token).
  /// 2. Emits [AuthenticationAuthenticated] with the new profile data.
  void switchTo(AuthResponse auth) async {
    await repository.setSwitchAccount(auth);
    emit(AuthenticationAuthenticated(auth: auth));
  }

  /// Performs a soft logout.
  ///
  /// 1. Removes the active profile data from local storage (keeps the root token).
  /// 2. Emits [AuthenticationLogout].
  void logout() async {
    await repository.logout();
    emit(AuthenticationLogout());
  }

  /// Performs a hard logout (complete session termination).
  ///
  /// 1. Removes all authentication data (active profile and root token) from
  ///    local storage.
  /// 2. Emits [AuthenticationLogoutHard].
  void logoutHard() async {
    await repository.hardLogout();
    emit(AuthenticationLogoutHard());
  }

  // --- State Emission Methods (Used by External Listeners) ---

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
  /// This is useful if the logout needs to be backgrounded or doesn't
  /// immediately require a UI change.
  Future localLogout() async {
    await repository.hardLogout();
  }
}

// --- Authentication States ---

/// Base class for all authentication states.
abstract class AuthenticationState extends Equatable {
  const AuthenticationState();

  @override
  List<Object> get props => [];
}

/// Initial state when the BLoC is first created.
class AuthenticationInitial extends AuthenticationState {}

/// State representing a soft logout (profile token cleared, root token remains).
class AuthenticationLogout extends AuthenticationState {}

/// State representing a hard logout (all tokens cleared).
class AuthenticationLogoutHard extends AuthenticationState {}

/// State representing a successfully authenticated user.
class AuthenticationAuthenticated extends AuthenticationState {
  final AuthResponse auth;
  const AuthenticationAuthenticated({required this.auth});

  @override
  List<Object> get props => [auth];
}
