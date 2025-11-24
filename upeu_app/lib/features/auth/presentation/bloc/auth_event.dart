import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginAdminRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginAdminRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class LoginStudentRequested extends AuthEvent {
  final String dni;
  final String studentCode;

  const LoginStudentRequested({
    required this.dni,
    required this.studentCode,
  });

  @override
  List<Object?> get props => [dni, studentCode];
}

class LoginJurorRequested extends AuthEvent {
  final String username;
  final String dni;

  const LoginJurorRequested({
    required this.username,
    required this.dni,
  });

  @override
  List<Object?> get props => [username, dni];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}