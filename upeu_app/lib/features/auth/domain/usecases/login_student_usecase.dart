import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class LoginStudentUseCase {
  final AuthRepository repository;

  LoginStudentUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String dni,
    required String studentCode,
  }) async {
    if (dni.isEmpty || studentCode.isEmpty) {
      return const Left(
        ValidationFailure('DNI y código de estudiante son requeridos'),
      );
    }

    if (dni.length != 8) {
      return const Left(
        ValidationFailure('El DNI debe tener 8 dígitos'),
      );
    }

    return await repository.loginStudent(
      dni: dni,
      studentCode: studentCode,
    );
  }
}