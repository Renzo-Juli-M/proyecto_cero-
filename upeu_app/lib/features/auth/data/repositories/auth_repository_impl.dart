import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/local_storage.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/student_entity.dart';
import '../../domain/entities/juror_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final LocalStorage localStorage;
  final DioClient dioClient;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localStorage,
    required this.dioClient,
  });

  @override
  Future<Either<Failure, Map<String, dynamic>>> loginAdmin({
    required String email,
    required String password,
  }) async {
    try {
      final response = await remoteDataSource.loginAdmin(
        email: email,
        password: password,
      );

      // Guardar token y datos
      await localStorage.saveToken(response.token);
      await localStorage.saveUserRole(response.user.role);
      await localStorage.saveUserId(response.user.id);

      // Configurar token en Dio
      dioClient.setToken(response.token);

      return Right({
        'user': response.user.toEntity(),
        'token': response.token,
      });
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> loginStudent({
    required String dni,
    required String studentCode,
  }) async {
    try {
      final response = await remoteDataSource.loginStudent(
        dni: dni,
        studentCode: studentCode,
      );

      // Guardar token y datos
      await localStorage.saveToken(response.token);
      await localStorage.saveUserRole(response.user.role);
      await localStorage.saveUserId(response.user.id);

      // Configurar token en Dio
      dioClient.setToken(response.token);

      return Right({
        'user': response.user.toEntity(),
        'student': response.student?.toEntity(),
        'token': response.token,
      });
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> loginJuror({
    required String username,
    required String dni,
  }) async {
    try {
      final response = await remoteDataSource.loginJuror(
        username: username,
        dni: dni,
      );

      // Guardar token y datos
      await localStorage.saveToken(response.token);
      await localStorage.saveUserRole(response.user.role);
      await localStorage.saveUserId(response.user.id);

      // Configurar token en Dio
      dioClient.setToken(response.token);

      return Right({
        'user': response.user.toEntity(),
        'juror': response.juror?.toEntity(),
        'token': response.token,
      });
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();

      // Limpiar almacenamiento local
      await localStorage.clearAll();

      // Remover token de Dio
      dioClient.removeToken();

      return const Right(null);
    } catch (e) {
      // Aun si falla el logout en el servidor, limpiamos local
      await localStorage.clearAll();
      dioClient.removeToken();
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final token = localStorage.getToken();
      if (token == null) {
        return const Right(null);
      }

      // Aquí podrías hacer una llamada al endpoint /me
      // Por ahora retornamos null
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, StudentEntity?>> getCurrentStudent() async {
    try {
      final token = localStorage.getToken();
      if (token == null) {
        return const Right(null);
      }

      // Aquí podrías hacer una llamada al endpoint /me
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, JurorEntity?>> getCurrentJuror() async {
    try {
      final token = localStorage.getToken();
      if (token == null) {
        return const Right(null);
      }

      // Aquí podrías hacer una llamada al endpoint /me
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}