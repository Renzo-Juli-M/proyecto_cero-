import 'package:equatable/equatable.dart';

class JurorEntity extends Equatable {
  final int id;
  final int userId;
  final String dni;
  final String username;
  final String firstName;
  final String lastName;
  final String? specialty;

  const JurorEntity({
    required this.id,
    required this.userId,
    required this.dni,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.specialty,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    dni,
    username,
    firstName,
    lastName,
    specialty,
  ];

  String get fullName => '$firstName $lastName';
}