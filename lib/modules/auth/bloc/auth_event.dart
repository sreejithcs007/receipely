import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class SignInWithEmailAndPasswordRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInWithEmailAndPasswordRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class SignUpWithEmailAndPasswordRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;

  const SignUpWithEmailAndPasswordRequested({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  List<Object?> get props => [email, password, name];
}

class SignOutRequested extends AuthEvent {}
