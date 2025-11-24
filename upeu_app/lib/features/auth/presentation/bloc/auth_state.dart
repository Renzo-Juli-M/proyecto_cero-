import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/student_entity.dart';
import '../../domain/entities/juror_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  final StudentEntity? student;
  final JurorEntity? juror;
  final String token;

  const AuthAuthenticated({
    required this.user,
    this.student,
    this.juror,
    required this.token,
  });

  @override
  List<Object?> get props => [user, student, juror, token];

  bool get isAdmin => user.isAdmin;
  bool get isStudent => user.isStudent;
  bool get isJuror => user.isJuror;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}