import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class LoginAdminUseCase {
  final AuthRepository repository;

  LoginAdminUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      return const Left(
        ValidationFailure('Email y contraseña son requeridos'),
      );
    }

    return await repository.loginAdmin(
      email: email,
      password: password,
    );
  }
}