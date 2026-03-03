import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';

/// Handles the initial check of the user's authentication status upon application startup.
///
/// It determines if a valid session exists based on the presence of the
/// root token and the current user profile.
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
        // No root token means no user has ever logged in since the last hard logout.
        emit(const AuthNotIdentified());
      } else if (currentUser != null) {
        // Root token exists, AND current profile data exists. User is ready.
        emit(AuthIdentified(auth: currentUser));
      } else {
        // Root token exists, but the current profile token/data is missing
        // (likely due to a soft logout). The app needs to navigate to a state
        // where the user can pick a profile or re-login (not a hard logout).
        emit(const AuthNotIdentified(hard: false));
      }
    } catch (e) {
      // Handles errors during SharedPreferences access or JSON parsing.
      emit(AuthCheckingFailure(message: e.toString()));
    }
  }
}

// --- Auth Checker States ---

/// Base class for all states related to the initial authentication check.
abstract class AuthCheckerState extends Equatable {
  const AuthCheckerState();

  @override
  List<Object> get props => [];
}

/// Initial state when the Cubit is first created.
class AuthCheckInitial extends AuthCheckerState {}

/// State emitted while actively checking local storage for credentials.
class AuthChecking extends AuthCheckerState {}

/// State indicating a user is successfully identified.
class AuthIdentified extends AuthCheckerState {
  final AuthResponse auth;
  const AuthIdentified({required this.auth});

  @override
  List<Object> get props => [auth];
}

/// State indicating no user is identified.
class AuthNotIdentified extends AuthCheckerState {
  /// If `true` (default), all tokens are missing (hard logout state).
  /// If `false`, the root token exists but the current profile is missing (soft logout state).
  final bool hard;
  const AuthNotIdentified({this.hard = true});

  @override
  List<Object> get props => [hard];
}

/// State indicating an error occurred during the local check process.
class AuthCheckingFailure extends AuthCheckerState {
  final String message;
  const AuthCheckingFailure({required this.message});

  @override
  List<Object> get props => [message];
}
