import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../entities/student_entity.dart';
import '../entities/juror_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, Map<String, dynamic>>> loginAdmin({
    required String email,
    required String password,
  });

  Future<Either<Failure, Map<String, dynamic>>> loginStudent({
    required String dni,
    required String studentCode,
  });

  Future<Either<Failure, Map<String, dynamic>>> loginJuror({
    required String username,
    required String dni,
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, UserEntity?>> getCurrentUser();

  Future<Either<Failure, StudentEntity?>> getCurrentStudent();

  Future<Either<Failure, JurorEntity?>> getCurrentJuror();
}