import '../../domain/entities/student_entity.dart';

class StudentModel extends StudentEntity {
  const StudentModel({
    required super.id,
    required super.userId,
    required super.dni,
    required super.studentCode,
    required super.firstName,
    required super.lastName,
    required super.type,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      dni: json['dni'] as String,
      studentCode: json['student_code'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'dni': dni,
      'student_code': studentCode,
      'first_name': firstName,
      'last_name': lastName,
      'type': type,
    };
  }

  StudentEntity toEntity() {
    return StudentEntity(
      id: id,
      userId: userId,
      dni: dni,
      studentCode: studentCode,
      firstName: firstName,
      lastName: lastName,
      type: type,
    );
  }
}