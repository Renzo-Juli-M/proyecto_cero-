import 'user_model.dart';
import 'student_model.dart';
import 'juror_model.dart';

class LoginResponseModel {
  final bool success;
  final String message;
  final String token;
  final UserModel user;
  final StudentModel? student;
  final JurorModel? juror;

  const LoginResponseModel({
    required this.success,
    required this.message,
    required this.token,
    required this.user,
    this.student,
    this.juror,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      success: json['success'] as bool,
      message: json['message'] as String,
      token: json['token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      student: json['student'] != null
          ? StudentModel.fromJson(json['student'] as Map<String, dynamic>)
          : null,
      juror: json['juror'] != null
          ? JurorModel.fromJson(json['juror'] as Map<String, dynamic>)
          : null,
    );
  }
}