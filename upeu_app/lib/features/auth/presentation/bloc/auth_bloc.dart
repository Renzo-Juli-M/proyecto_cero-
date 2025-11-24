import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/login_admin_usecase.dart';
import '../../domain/usecases/login_student_usecase.dart';
import '../../domain/usecases/login_juror_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginAdminUseCase loginAdminUseCase;
  final LoginStudentUseCase loginStudentUseCase;
  final LoginJurorUseCase loginJurorUseCase;
  final LogoutUseCase logoutUseCase;

  AuthBloc({
    required this.loginAdminUseCase,
    required this.loginStudentUseCase,
    required this.loginJurorUseCase,
    required this.logoutUseCase,
  }) : super(const AuthInitial()) {
    on<LoginAdminRequested>(_onLoginAdminRequested);
    on<LoginStudentRequested>(_onLoginStudentRequested);
    on<LoginJurorRequested>(_onLoginJurorRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

  Future<void> _onLoginAdminRequested(
      LoginAdminRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());

    final result = await loginAdminUseCase(
      email: event.email,
      password: event.password,
    );

    result.fold(
          (failure) => emit(AuthError(failure.message)),
          (data) => emit(
        AuthAuthenticated(
          user: data['user'],
          token: data['token'],
        ),
      ),
    );
  }

  Future<void> _onLoginStudentRequested(
      LoginStudentRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());

    final result = await loginStudentUseCase(
      dni: event.dni,
      studentCode: event.studentCode,
    );

    result.fold(
          (failure) => emit(AuthError(failure.message)),
          (data) => emit(
        AuthAuthenticated(
          user: data['user'],
          student: data['student'],
          token: data['token'],
        ),
      ),
    );
  }

  Future<void> _onLoginJurorRequested(
      LoginJurorRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());

    final result = await loginJurorUseCase(
      username: event.username,
      dni: event.dni,
    );

    result.fold(
          (failure) => emit(AuthError(failure.message)),
          (data) => emit(
        AuthAuthenticated(
          user: data['user'],
          juror: data['juror'],
          token: data['token'],
        ),
      ),
    );
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());

    final result = await logoutUseCase();

    result.fold(
          (failure) => emit(const AuthUnauthenticated()),
          (_) => emit(const AuthUnauthenticated()),
    );
  }

  Future<void> _onCheckAuthStatus(
      CheckAuthStatus event,
      Emitter<AuthState> emit,
      ) async {
    // Aquí verificarías si hay una sesión activa
    // Por ahora solo emitimos unauthenticated
    emit(const AuthUnauthenticated());
  }
}