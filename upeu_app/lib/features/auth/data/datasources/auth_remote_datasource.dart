import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/login_response_model.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponseModel> loginAdmin({
    required String email,
    required String password,
  });

  Future<LoginResponseModel> loginStudent({
    required String dni,
    required String studentCode,
  });

  Future<LoginResponseModel> loginJuror({
    required String username,
    required String dni,
  });

  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSourceImpl(this.dioClient);

  @override
  Future<LoginResponseModel> loginAdmin({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dioClient.post(
        ApiConstants.loginAdmin,
        data: {
          'email': email,
          'password': password,
        },
      );

      return LoginResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<LoginResponseModel> loginStudent({
    required String dni,
    required String studentCode,
  }) async {
    try {
      final response = await dioClient.post(
        ApiConstants.loginStudent,
        data: {
          'dni': dni,
          'student_code': studentCode,
        },
      );

      return LoginResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<LoginResponseModel> loginJuror({
    required String username,
    required String dni,
  }) async {
    try {
      final response = await dioClient.post(
        ApiConstants.loginJuror,
        data: {
          'username': username,
          'dni': dni,
        },
      );

      return LoginResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dioClient.post(ApiConstants.logout);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        // Extraer mensaje de error de Laravel
        if (data.containsKey('message')) {
          return data['message'] as String;
        }
        if (data.containsKey('errors')) {
          final errors = data['errors'] as Map<String, dynamic>;
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            return firstError.first as String;
          }
        }
      }
      return 'Error del servidor: ${error.response?.statusCode}';
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Tiempo de espera agotado. Verifica tu conexión.';
    } else if (error.type == DioExceptionType.connectionError) {
      return 'No se pudo conectar al servidor. Verifica tu conexión.';
    }
    return 'Error inesperado: ${error.message}';
  }
}