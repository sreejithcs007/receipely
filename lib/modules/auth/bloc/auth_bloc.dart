import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/data/repositories/user_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final UserRepository _userRepository;

  AuthBloc(this._userRepository) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignInWithEmailAndPasswordRequested>(_onSignInRequested);
    on<SignUpWithEmailAndPasswordRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
  }

  Future<void> _onAuthCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final user = _userRepository.getCurrentUser();
    if (user != null) {
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onSignInRequested(SignInWithEmailAndPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _userRepository.signIn(
        email: event.email,
        password: event.password,
      );
      if (response.user != null) {
        emit(Authenticated(response.user!));
      } else {
        emit(const AuthFailure('Log in failed. Invalid user session.'));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onSignUpRequested(SignUpWithEmailAndPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _userRepository.signUp(
        email: event.email,
        password: event.password,
        name: event.name,
      );
      if (response.user != null) {
        emit(Authenticated(response.user!));
      } else {
        emit(const AuthFailure('Registration failed. Invalid user session.'));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onSignOutRequested(SignOutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _userRepository.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }
}
