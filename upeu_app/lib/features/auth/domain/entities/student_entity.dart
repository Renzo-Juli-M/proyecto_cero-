import 'package:equatable/equatable.dart';

class StudentEntity extends Equatable {
  final int id;
  final int userId;
  final String dni;
  final String studentCode;
  final String firstName;
  final String lastName;
  final String type;

  const StudentEntity({
    required this.id,
    required this.userId,
    required this.dni,
    required this.studentCode,
    required this.firstName,
    required this.lastName,
    required this.type,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    dni,
    studentCode,
    firstName,
    lastName,
    type,
  ];

  String get fullName => '$firstName $lastName';
  bool get isPonente => type == 'ponente';
  bool get isOyente => type == 'oyente';
}