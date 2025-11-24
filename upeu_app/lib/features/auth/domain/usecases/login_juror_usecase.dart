import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class LoginJurorUseCase {
  final AuthRepository repository;

  LoginJurorUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String username,
    required String dni,
  }) async {
    if (username.isEmpty || dni.isEmpty) {
      return const Left(
        ValidationFailure('Usuario y DNI son requeridos'),
      );
    }

    if (dni.length != 8) {
      return const Left(
        ValidationFailure('El DNI debe tener 8 dígitos'),
      );
    }

    return await repository.loginJuror(
      username: username,
      dni: dni,
    );
  }
}